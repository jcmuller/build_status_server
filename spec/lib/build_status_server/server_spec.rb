require 'spec_helper'
require 'build_status_server'

describe BuildStatusServer::Server do
  let(:server) { BuildStatusServer::Server.new }

  before do
    STDERR.should_receive(:puts)
  end

  describe "#listen" do
    it "should setup the udp server" do
      server.should_receive(:setup_udp_server)
      server.listen(false)
    end

    it "should close socket if interrupted" do
      # inject interruption
      server.should_receive(:process_loop).and_raise(Interrupt)

      server.should_receive(:setup_udp_server)
      udp_server = mock(:udp_server, :close => true)
      server.should_receive(:udp_server).and_return(udp_server)

      STDOUT.should_receive(:puts).with("Good bye.")
      udp_server.should_receive(:close)
      server.should_receive(:exit)

      server.listen
    end
  end

  context "private methods" do

    describe "#setup_udp_server" do
      it "reads the udp_server options from configuration file" do
        server.config.stub!(:udp_server).and_return({"address" => "address", "port" => "port"})
        socket = mock(:udp_socket)
        socket.should_receive(:bind).with("address", "port")
        UDPSocket.should_receive(:new).and_return(socket)
        server.stub!(:udp_server).and_return(socket)

        server.send(:setup_udp_server)
      end

      it "instantiates a UDPSocket object and binds it to address and port" do
        server.config.stub!(:udp_server).and_return({"address" => "127.0.0.1", "port" => 9999})

        server.send(:setup_udp_server)

        client = UDPSocket.new
        client.connect("127.0.0.1", 9999)
        client.send "hello, world!", 0
        msg = server.udp_server.recvfrom(13)

        msg[0].should == "hello, world!"
        ["AF_INET", "127.0.0.1"].each do |e|
          msg[1].should include e
        end
      end

      it "should show message and exit when connecting to address not available" do
        server.config.stub!(:udp_server).and_return({"address" => "192.192.192.192", "port" => 9999})

        STDERR.should_receive(:puts).with("The address configured is not available (192.192.192.192)\n\n")
        server.should_receive(:exit)

        server.send(:setup_udp_server)
      end

      it "it recovers from an address in use exception" do
        server.config.stub!(:udp_server).and_return({"address" => "127.0.0.1", "port" => 9999})

        socket = mock(:udp_socket)
        socket.should_receive(:bind).and_raise(Errno::EADDRINUSE)
        UDPSocket.should_receive(:new).and_return(socket)

        STDERR.should_receive(:puts).with("There appears that another instance is running, or another process\nis listening on the same port (127.0.0.1:9999)\n\n")
        server.should_receive(:exit)

        server.send(:setup_udp_server)
      end

      it "if verbose is enabled, show message" do
        server.config.stub!(:udp_server).and_return({"address" => "address", "port" => "port"})
        socket = mock(:udp_socket)
        socket.should_receive(:bind).with("address", "port")
        UDPSocket.should_receive(:new).and_return(socket)

        server.config.stub!(:verbose).and_return(true)
        STDOUT.should_receive(:puts).with("Listening on UDP address:port")

        server.send(:setup_udp_server)
      end
    end

    describe "#process_loop" do
      it "should process all statuses and notify when process job returns true" do
        socket = mock(:udp_socket)
        socket.stub!(:recvfrom).and_return("data", "addr")

        server.should_receive(:udp_server).and_return(socket)
        server.should_receive(:process_job).with("data").and_return(true)

        server.should_receive(:process_all_statuses).and_return("status")
        server.should_receive(:notify).with("status")

        server.send(:process_loop)
      end

      it "should not process all statuses or notify when process job returns false" do
        socket = mock(:udp_socket)
        socket.stub!(:recvfrom).and_return("data", "addr")

        server.should_receive(:udp_server).and_return(socket)
        server.should_receive(:process_job).with("data").and_return(false)

        server.should_not_receive(:process_all_statuses)
        server.should_not_receive(:notify)

        server.send(:process_loop)
      end
    end

    describe "#load_store" do
      before do
        server.config.stub!(:store_file).and_return("/tmp/build")
      end

      it "initializes an empty hash if store file doesn't exist" do
        server.send(:load_store)
        server.store.should == {}
      end

      it "initializes an empty hash if store file is empty" do
        require "tempfile"
        f = Tempfile.new("server_spec")
        server.stub!(:store_file).and_return(f.path)

        server.send(:load_store)
        server.store.should == {}
      end

      it "initializes a hash with the contents of the store file" do
        server.config.stub!(:store_file).and_return("spec/support/build_result.yml")
        server.send(:load_store)

        server.store.should == {"blah" => "SUCCESS", "test" => "SUCCESS"}
      end
    end

    describe "#should_process_build" do
      context "when mask exists" do

        context "when policy is include" do
          before do
            server.config.stub!(:mask).and_return({"policy" => "include", "regex" => %r{.*(?:master).*}})
          end

          it "ignores builds if mask doesn't match build name" do
            server.send(:should_process_build, "blah-development").should be_false
          end

          it "processes builds if mask matches build name" do
            server.send(:should_process_build, "blah-master").should be_true
          end
        end

        context "when policy is exclude" do
          before do
            server.config.stub!(:mask).and_return({"policy" => "exclude", "regex" => %r{.*(?:master).*}})
          end

          it "ignores builds if mask matches build name" do
            server.send(:should_process_build, "blah-master").should be_false
          end

          it "processes builds if mask doesn't match build name" do
            server.send(:should_process_build, "blah-development").should be_true
          end
        end

        context "when policy is undefined it defaults to ignore" do
          before do
            server.config.stub!(:mask).and_return({"policy" => nil, "regex" => /.*(?:master).*/})
          end

          it "ignores builds if mask matches build name" do
            server.send(:should_process_build, "blah-master").should be_false
          end

          it "processes builds if mask doesn't match build name" do
            server.send(:should_process_build, "blah-development").should be_true
          end
        end

        context "when policy is unexpected it defaults to ignore" do
          before do
            server.config.stub!(:mask).and_return({"policy" => "trash", "regex" => /.*(?:master).*/})
          end

          it "ignores builds if mask matches build name" do
            server.send(:should_process_build, "blah-master").should be_false
          end

          it "processes builds if mask doesn't match build name" do
            server.send(:should_process_build, "blah-development").should be_true
          end
        end
      end

      context "when mask regex doesn't" do
        before do
          server.config.stub!(:mask).and_return({"policy" => "include", "regex" => nil})
        end

        it "should process all jobs" do
          server.send(:should_process_build, "blah-development").should be_true
        end
      end
    end

    describe "#process_job" do
      it "returns false if should_process_build returns false" do
        server.should_receive(:should_process_build).and_return(false)
        server.send(:process_job).should be_false
      end

      it "doesn't die if invalid JSON is passed in" do
        STDERR.should_receive(:puts).with("Invalid JSON! (Or at least JSON wasn't able to parse it...)\nReceived: {b => \"123\"}")
        expect { server.send(:process_job, '{b => "123"}') }.should_not raise_error(JSON::ParserError)
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

    describe "#notify" do
      let(:client) { mock(:client) }

      context "no exceptions" do
        before do
          options = {
            "pass" => "pass",
            "fail" => "fail",
            "host" => "host",
            "port" => "port"
          }
          config = mock(:config)
          config.should_receive(:tcp_client).and_return(options)
          config.should_receive(:verbose).and_return(true)

          server.should_receive(:config).twice.and_return(config)

          STDOUT.should_receive(:puts).with("answer")

          client.should_receive(:gets).and_return("answer")
          client.should_receive(:close)

          TCPSocket.should_receive(:new).with("host", "port").and_return(client)
        end

        it "should send passing packet to tcp socket when status is true" do
          client.should_receive(:print).with("GET pass HTTP/1.0\n\n")
          server.send(:notify, true)
        end

        it "should send failing packet to tcp socket when status is false" do
          client.should_receive(:print).with("GET fail HTTP/1.0\n\n")
          server.send(:notify, false)
        end
      end

      context "exceptions" do
        before do
          options = {
            "fail" => "fail",
            "host" => "host",
            "port" => "port",
            "attempts" => 2
          }
          config = mock(:config)
          config.should_receive(:tcp_client).and_return(options)
          config.should_receive(:verbose).and_return(false)

          server.should_receive(:config).twice.and_return(config)
          client.should_receive(:close)

          client.should_receive(:gets).and_return("answer")
        end

        it "should time out and retry 2 times" do
          TCPSocket.should_receive(:new).exactly(3).with("host", "port").and_return(client)
          STDERR.should_receive(:puts).exactly(2).with("Error: Timeout::Error while trying to send fail")
          client.should_receive(:print).exactly(2).with("GET fail HTTP/1.0\n\n").and_raise(Timeout::Error)
          client.should_receive(:print).with("GET fail HTTP/1.0\n\n")

          server.send(:notify, false)
        end

        it "should not connect and retry 2 times" do
          STDERR.should_receive(:puts).with("Error: Connection refused while trying to send fail")
          STDERR.should_receive(:puts).with("Error: No route to host while trying to send fail")
          STDERR.should_receive(:puts).with("Will wait for 2 seconds and try again...")
          STDERR.should_receive(:puts).with("Will wait for 4 seconds and try again...")

          TCPSocket.should_receive(:new).with("host", "port").and_raise(Errno::ECONNREFUSED)
          TCPSocket.should_receive(:new).with("host", "port").and_raise(Errno::EHOSTUNREACH)
          TCPSocket.should_receive(:new).with("host", "port").and_return(client)

          server.should_receive(:sleep).with(2)
          server.should_receive(:sleep).with(4)

          client.should_receive(:print).with("GET fail HTTP/1.0\n\n")

          server.send(:notify, false)
        end
      end

      it "should gracefully recover if config doesn't have attempts configured" do
        options = {
          "fail" => "fail",
          "host" => "host",
          "port" => "port"
        }

        config = mock(:config)
        config.should_receive(:tcp_client).and_return(options)
        config.should_receive(:verbose).and_return(false)

        server.should_receive(:config).twice.and_return(config)
        client.should_receive(:close)

        client.should_receive(:gets).and_return("answer")
        TCPSocket.should_receive(:new).exactly(3).with("host", "port").and_return(client)
        STDERR.should_receive(:puts).exactly(2).with("Error: Timeout::Error while trying to send fail")
        client.should_receive(:print).exactly(2).with("GET fail HTTP/1.0\n\n").and_raise(Timeout::Error)
        client.should_receive(:print).with("GET fail HTTP/1.0\n\n")

        server.send(:notify, false)
      end
    end

    describe "#process_all_statuses" do
      it "should return true if all values are SUCCESS" do
        server.should_receive(:store).and_return(mock(:blah, :values => %w(SUCCESS SUCCESS SUCCESS)))
        server.send(:process_all_statuses).should be_true
      end

      it "should return true if all values are pass" do
        server.should_receive(:store).and_return(mock(:blah, :values => %w(pass pass pass)))
        server.send(:process_all_statuses).should be_true
      end

      it "should return true if some values are pass and some are SUCCESS" do
        server.should_receive(:store).and_return(mock(:blah, :values => %w(SUCCESS pass SUCCESS)))
        server.send(:process_all_statuses).should be_true
      end

      it "should return false if at least one value isn't pass or SUCCESS" do
        server.should_receive(:store).and_return(mock(:blah, :values => %w(SUCCESS blah SUCCESS)))
        server.send(:process_all_statuses).should be_false
      end
    end

    describe "#job_internals" do
      it "should return build number and status" do
        params = {"build" => {"number" => "number", "status" => "status"}}
        server.send(:job_internals, params).should == "build=>number, status=>status"
      end

      it "should return only build if no status" do
        params = {"build" => {"number" => "number"}}
        server.send(:job_internals, params).should == "build=>number"
      end
    end

    describe "#wait_for" do
      it "should return 2**n for each attempt n up to 5" do
        server.send(:wait_for, 1).should == 2
        server.send(:wait_for, 5).should == 32
      end

      it "should return 60 for anything over 5" do
        server.send(:wait_for, 6).should == 60
        server.send(:wait_for, 1000).should == 60
      end
    end

  end
end

# vim:set foldmethod=syntax foldlevel=1:
