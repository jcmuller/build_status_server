require 'spec_helper'

describe BuildStatusServer::Runner do
  let(:config) { mock }
  let(:store) { mock }
  let(:udp_server) { mock(run_loop: true) }
  let(:http_server) { mock(run_loop: true) }

  before do
    BuildStatusServer::Config.stub(:new).and_return(config)
    BuildStatusServer::Store.stub(:new).and_return(store)
    BuildStatusServer::UDPServer.stub(:new).and_return(udp_server)
    BuildStatusServer::HTTPServer.stub(:new).and_return(http_server)
  end

  describe "#listen" do
    before { Thread.stub(:start) }

    it "shouild start a udp thread and run loop on udp server" do
      Thread.should_receive(:start).with(udp_server).and_yield(udp_server)
      udp_server.should_receive(:run_loop)

      subject.listen(false)
    end

    it "shouild start a tcp thread and run loop on tcp server" do
      Thread.should_receive(:start).with(http_server).and_yield(http_server)
      http_server.should_receive(:run_loop)

      subject.listen(false)
    end

    it "should kill udp_thread on exit" do
      udp_thread = mock

      http_server.should_receive(:run_loop).and_raise(Interrupt)

      Thread.should_receive(:start).with(udp_server).and_return(udp_thread)
      Thread.should_receive(:start).with(http_server).and_yield(http_server)

      udp_thread.should_receive(:exit)

      expect{ subject.listen(false) }.to raise_error SystemExit
    end

    it "should sleep" do
      subject.should_receive(:sleep).and_raise SystemExit
      expect{ subject.listen }.to raise_error SystemExit
    end
  end
end
