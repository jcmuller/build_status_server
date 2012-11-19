require 'spec_helper'

describe BuildStatusServer::UDPServer do
  let(:config) {
    mock(
      udp_server: {
        "address" => "address",
        "port" => "port"
      },
      verbose: false
    )
  }
  let(:store) { mock }

  subject { described_class.new(config, store, false) }

  before do
    STDERR.stub(:puts)
  end

  describe "#setup" do
    it "should instantiate an UDP Socket" do
      config.should_receive(:udp_server).and_return({"address" => "address", "port" => "port"})
      socket = mock
      UDPSocket.should_receive(:new).and_return(socket)
      socket.stub(:bind)

      subject.setup
    end

    it "should bind the address and port to the socket" do
      config.stub(:udp_server).and_return({"address" => "address", "port" => "port"})
      socket = mock
      UDPSocket.stub(:new).and_return(socket)
      socket.should_receive(:bind).with("address", "port")

      subject.setup
    end

    it "should let me know that UDP is listening" do
      config.should_receive(:verbose).and_return(true)
      config.stub(:udp_server).and_return({"address" => "address", "port" => "port"})
      socket = mock
      UDPSocket.stub(:new).and_return(socket)
      socket.stub(:bind).with("address", "port")

      STDOUT.should_receive(:puts).with("Listening on UDP address:port")

      subject.setup
    end

    it "should call address_in_use_error on Errno::EADDRINUSE" do
      socket = mock
      socket.should_receive(:bind).and_raise(Errno::EADDRINUSE)
      UDPSocket.stub(:new).and_return(socket)
      subject.should_receive(:address_in_use_error)

      subject.setup
    end

    it "should call address_not_available_error on Errno::EADDRNOTAVAIL" do
      socket = mock
      socket.should_receive(:bind).and_raise(Errno::EADDRNOTAVAIL)
      UDPSocket.stub(:new).and_return(socket)
      subject.should_receive(:address_not_available_error)

      subject.setup
    end
  end

  describe "#process" do
    let(:server) { mock( recvfrom: ["a piece of", "data"]) }

    before do
      subject.stub(:server).and_return(server)
    end

    it "should get data from server" do
      subject.stub(:process_job).and_return(false)
      server.should_receive(:recvfrom)

      subject.process
    end

    context "should process_job with data" do
      it "when true" do
        subject.should_receive(:process_job).and_return(true)
        store.should_receive(:summary_statuses).and_return("summary_statuses")
        tcp_client = mock
        tcp_client.should_receive(:notify).with("summary_statuses")
        BuildStatusServer::TCPClient.should_receive(:new).and_return(tcp_client)

        subject.process
      end

      it "when false" do
        subject.should_receive(:process_job).and_return(false)
        store.should_not_receive(:summary_statuses)
        BuildStatusServer::TCPClient.should_not_receive(:new)

        subject.process
      end
    end
  end

  describe "#process_job", pending: true do
    it "returns false if should_process_build returns false" do
      server.should_receive(:should_process_build).and_return(false)
      server.send(:process_job).should be_false
    end

    it "doesn't die if invalid JSON is passed in" do
      STDERR.should_receive(:puts).with("Invalid JSON! (Or at least JSON wasn't able to parse it...)\nReceived: {b => \"123\"}")
      expect { server.send(:process_job, '{b => "123"}') }.to_not raise_error(JSON::ParserError)
    end

    it "returns false and says so on stderr if payload doesn't have a hash for build" do
      server.should_receive(:should_process_build).and_return(true)
      JSON.should_receive(:parse).and_return({"build" => "Not a hash!"})
      STDERR.should_receive(:puts).with("Pinged with an invalid payload")
      server.send(:process_job).should be_false
    end

    it "returns false and says that the we got the job started when phase is FINISHED but status isn't success nor failure" do
      server.config.should_receive(:verbose).and_return(true)
      server.should_receive(:should_process_build).and_return(true)
      JSON.should_receive(:parse).with("{}").and_return({
        "name" => "name",
        "build" => { "phase" => "FINISHED", "status" => "some status", "number" => "number" }
      })
      Time.should_receive(:now).and_return("this is the time")
      STDOUT.should_receive(:puts).with('Got some status for name on this is the time [build=>number, status=>some status]')
      server.send(:process_job).should be_false
    end

    it "returns false and says that the job started when the phase isn't finished" do
      server.config.should_receive(:verbose).and_return(true)
      server.should_receive(:should_process_build).and_return(true)
      JSON.should_receive(:parse).with("{}").and_return({
        "name" => "name",
        "build" => { "phase" => "STARTED", "status" => "some status", "number" => "number" }
      })
      Time.should_receive(:now).and_return("this is the time")
      STDOUT.should_receive(:puts).with("Started for name on this is the time [build=>number, status=>some status]")
      server.send(:process_job).should be_false
    end

    context "phase is FINISHED and status is either SUCCESS or FAILURE" do
      before do
        server.config.should_receive(:verbose).and_return(true)
        server.should_receive(:should_process_build).and_return(true)
        Time.should_receive(:now).and_return("this is the time")
        YAML.should_receive(:load_file).and_return({})
        File.should_receive(:open)
      end

      it "should return true and write yaml file when phase is FINISHED and status is SUCCESS" do
        JSON.should_receive(:parse).with("{}").and_return({
          "name" => "name",
          "build" => { "phase" => "FINISHED", "status" => "SUCCESS", "number" => "number" }
        })
        STDOUT.should_receive(:puts).with("Got SUCCESS for name on this is the time [build=>number, status=>SUCCESS]")

        server.send(:process_job).should be_true
      end

      it "should return true and write yaml file when phase is FINISHED and status is FAILURE" do
        JSON.should_receive(:parse).with("{}").and_return({
          "name" => "name",
          "build" => { "phase" => "FINISHED", "status" => "FAILURE", "number" => "number" }
        })
        STDOUT.should_receive(:puts).with("Got FAILURE for name on this is the time [build=>number, status=>FAILURE]")

        server.send(:process_job).should be_true
      end
    end
  end

  describe "#parse_data" do
    it "should call JSON.parse" do
      JSON.should_receive(:parse).with("{a: 'b'}").and_return({ 'a' => 'b' })
      response = subject.parse_data("{a: 'b'}")
      response.should be_true
      response.should == { 'a' => 'b' }
    end

    it "should print error on JSON::ParserError" do
      JSON.should_receive(:parse).with("{invalid}").and_raise(JSON::ParserError)
      STDERR.should_receive(:puts).with("Invalid JSON! (Or at least our JSON parser wasn't able to parse it...)\nReceived: {invalid}\n")
      subject.parse_data("{invalid}").should be_false
    end
  end

  describe "#should_process_build" do
    context "when mask exists" do

      context "when policy is include" do
        before do
          config.stub!(:mask).and_return({"policy" => "include", "regex" => %r{.*(?:master).*}})
        end

        it "ignores builds if mask doesn't match build name" do
          subject.send(:should_process_build, "blah-development").should be_false
        end

        it "processes builds if mask matches build name" do
          subject.send(:should_process_build, "blah-master").should be_true
        end
      end

      context "when policy is exclude" do
        before do
          config.stub!(:mask).and_return({"policy" => "exclude", "regex" => %r{.*(?:master).*}})
        end

        it "ignores builds if mask matches build name" do
          subject.send(:should_process_build, "blah-master").should be_false
        end

        it "processes builds if mask doesn't match build name" do
          subject.send(:should_process_build, "blah-development").should be_true
        end
      end

      context "when policy is undefined it defaults to ignore" do
        before do
          config.stub!(:mask).and_return({"policy" => nil, "regex" => /.*(?:master).*/})
        end

        it "ignores builds if mask matches build name" do
          subject.send(:should_process_build, "blah-master").should be_false
        end

        it "processes builds if mask doesn't match build name" do
          subject.send(:should_process_build, "blah-development").should be_true
        end
      end

      context "when policy is unexpected it defaults to ignore" do
        before do
          config.stub!(:mask).and_return({"policy" => "trash", "regex" => /.*(?:master).*/})
        end

        it "ignores builds if mask matches build name" do
          subject.send(:should_process_build, "blah-master").should be_false
        end

        it "processes builds if mask doesn't match build name" do
          subject.send(:should_process_build, "blah-development").should be_true
        end
      end
    end

    context "when mask regex doesn't" do
      before do
        config.stub!(:mask).and_return({"policy" => "include", "regex" => nil})
      end

      it "should process all jobs" do
        subject.send(:should_process_build, "blah-development").should be_true
      end
    end
  end

  describe "#job_internals" do
    it "should return build number and status" do
      params = {"build" => {"number" => "number", "status" => "status"}}
      subject.send(:job_internals, params).should == "build=>number, status=>status"
    end

    it "should return only build if no status" do
      params = {"build" => {"number" => "number"}}
      subject.send(:job_internals, params).should == "build=>number"
    end
  end

end

# vim:set foldmethod=syntax foldlevel=1:
