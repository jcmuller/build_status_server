require 'spec_helper'

describe BuildStatusServer::HTTPServer do
  let(:tcp_server) { { "address" => "address", "port" => "port" }}
  let(:config) { double(tcp_server: tcp_server, verbose: false) }
  let(:store) { double }

  subject { described_class.new(config, store, false) }

  before do
    TCPServer.stub(:new)
  end

  describe "#setup" do
    after { subject.setup }

    it { TCPServer.should_receive(:new).with("address", "port") }

    it "should let us all know about it if verbose" do
      config.should_receive(:verbose).and_return(true)
      STDOUT.should_receive(:puts).with("Listening on TCP address:port")
    end

    it "should report error on address in use" do
      subject.should_receive(:address_in_use_error)
      TCPServer.should_receive(:new).and_raise(Errno::EADDRINUSE)
    end

    it "should report error on address not available" do
      subject.should_receive(:address_not_available_error)
      TCPServer.should_receive(:new).and_raise(Errno::EADDRNOTAVAIL)
    end
  end

  describe "#process" do
    it "should start thread and process request" do
      request = double
      server = double(accept: request)
      subject.should_receive(:server).and_return(server)
      Thread.should_receive(:start).with(request).and_yield(request)
      subject.should_receive(:process_request).with(request)

      subject.process
    end
  end

  describe "#process_request" do
    let(:request) { double }

    before do
      request.stub(:print)
      request.stub(:close)

      subject.stub(:headers).and_return("headers")
      subject.stub(:body).and_return("body")
    end

    it { request.should_receive(:print).with("headers") }
    it { request.should_receive(:print).with("body") }
    it { request.should_receive(:close) }

    after { subject.send(:process_request, request) }
  end

  describe "#headers" do
    it { subject.send(:headers).should == "HTTP/1.1 200/OK\r\nContent-type:text/html\r\n\r\n" }
  end

  describe "#body" do
    it "should print body" do
      subject.should_receive(:build_status).and_return("build_status")
      subject.send(:body).should == <<-EOB
<html>
  <head>
    <meta http-equiv="refresh" content="5; url=http://address:port/">
  </head>
  <body>
    Build is build_status
  </body>
</html>
      EOB
    end
  end

  describe "#build_status" do
    it "should return passing if builds are passing" do
      store.should_receive(:passing_builds?).and_return(true)
      subject.send(:build_status).should == "passing"
    end

    it "should return failing if builds are failing" do
      store.should_receive(:passing_builds?).and_return(false)
      subject.send(:build_status).should == "failing"
    end
  end

end
