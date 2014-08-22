require 'spec_helper'

describe BuildStatusServer::TCPClient do
  let(:config) { double }
  subject { described_class.new(config) }

  before do
    STDERR.stub(:puts)
  end

  describe "#notify" do
    let(:client) { double(:client) }

    context "no exceptions" do
      before do
        options = {
          "pass" => "pass",
          "fail" => "fail",
          "host" => "host",
          "port" => "port"
        }
        config.stub(:tcp_client).and_return(options)
        config.stub(:verbose).and_return(true)

        STDOUT.should_receive(:puts).with("answer")

        client.stub(:gets).and_return("answer")
        client.stub(:close)

        TCPSocket.stub(:new).with("host", "port").and_return(client)
      end

      it "should send passing packet to tcp socket when status is true" do
        client.should_receive(:print).with("GET pass HTTP/1.0\n\n")
        subject.send(:notify, true)
      end

      it "should send failing packet to tcp socket when status is false" do
        client.should_receive(:print).with("GET fail HTTP/1.0\n\n")
        subject.send(:notify, false)
      end
    end

    context "exceptions" do
      before do
        options = {
          "fail" => "fail",
          "host" => "host",
          "port" => "port",
          "attempts" => 4
        }
        config.stub(:tcp_client).and_return(options)
        config.stub(:verbose).and_return(false)

        client.stub(:close)

        client.stub(:gets).and_return("answer")
      end

      it "should time out and retry 2 times" do
        TCPSocket.should_receive(:new).exactly(3).with("host", "port").and_return(client)
        STDERR.should_receive(:puts).exactly(2).with("Error: Timeout::Error while trying to send fail")
        client.should_receive(:print).exactly(2).with("GET fail HTTP/1.0\n\n").and_raise(Timeout::Error)
        client.should_receive(:print).with("GET fail HTTP/1.0\n\n")

        subject.send(:notify, false)
      end

      it "should not connect and retry 3 times" do
        STDERR.should_receive(:puts).with("Error: Connection refused while trying to send fail")
        STDERR.should_receive(:puts).with("Error: No route to host while trying to send fail")
        STDERR.should_receive(:puts).with("Error: Network is unreachable while trying to send fail")
        STDERR.should_receive(:puts).with("Will wait for 2 seconds and try again...")
        STDERR.should_receive(:puts).with("Will wait for 4 seconds and try again...")
        STDERR.should_receive(:puts).with("Will wait for 8 seconds and try again...")

        TCPSocket.should_receive(:new).with("host", "port").and_raise(Errno::ECONNREFUSED.new)
        TCPSocket.should_receive(:new).with("host", "port").and_raise(Errno::EHOSTUNREACH.new)
        TCPSocket.should_receive(:new).with("host", "port").and_raise(Errno::ENETUNREACH.new)
        TCPSocket.should_receive(:new).with("host", "port").and_return(client)

        subject.should_receive(:sleep).with(2)
        subject.should_receive(:sleep).with(4)
        subject.should_receive(:sleep).with(8)

        client.should_receive(:print).with("GET fail HTTP/1.0\n\n")

        subject.send(:notify, false)
      end

      it "just output when other kinds of errors" do
        TCPSocket.should_receive(:new).and_raise(StandardError)

        STDERR.should_receive(:puts).with(
          "There was an error, but we don't know how to handle it: StandardError"
        )

        subject.send(:notify, false)
      end

      it "client must close" do
        client = double
        TCPSocket.should_receive(:new).and_return(client)

        client.should_receive(:print).and_raise(StandardError)

        client.should_receive(:close)

        subject.send(:notify, false)
      end
    end

    it "should gracefully recover if config doesn't have attempts configured" do
      options = {
        "fail" => "fail",
        "host" => "host",
        "port" => "port"
      }

      config.should_receive(:tcp_client).at_least(1).times.and_return(options)
      config.should_receive(:verbose).and_return(false)

      client.should_receive(:close).at_least(1).times.and_return(options)

      client.should_receive(:gets).and_return("answer")
      TCPSocket.should_receive(:new).exactly(3).with("host", "port").and_return(client)
      STDERR.should_receive(:puts).exactly(2).with("Error: Timeout::Error while trying to send fail")
      client.should_receive(:print).exactly(2).with("GET fail HTTP/1.0\n\n").and_raise(Timeout::Error)
      client.should_receive(:print).with("GET fail HTTP/1.0\n\n")

      subject.send(:notify, false)
    end
  end
end
