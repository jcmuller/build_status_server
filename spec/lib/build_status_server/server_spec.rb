require 'spec_helper'

class SomeClassDefinedInServer
end

describe BuildStatusServer::Server do
  let(:config) { double }
  let(:store) { double }

  subject { described_class.new(config, store) }

  describe "#setup" do
    it "#noop" do
      subject.setup
    end

    it "should raise if..." do
      subject.stub(:class).and_return(SomeClassDefinedInServer)
      expect{ subject.setup }.to raise_error(RuntimeError)
    end
  end

  describe "#process" do
    it "#noop" do
      subject.process
    end

    it "should raise if..." do
      subject.stub(:class).and_return(SomeClassDefinedInServer)
      expect{ subject.process }.to raise_error(RuntimeError)
    end
  end

  describe "#address_in_use_error" do
    it "should show info and exit" do
      STDERR.should_receive(:puts).with(<<-EOT)
There appears that another instance is running, or another process
is listening on the same port (address:port)

      EOT
      expect{ subject.address_in_use_error("address", "port") }.to raise_error SystemExit
    end
  end

  describe "#address_not_available_error" do
    it "should show info and exit" do
      STDERR.should_receive(:puts).with(<<-EOT)
The address configured is not available (address)

      EOT
      expect{ subject.address_not_available_error("address") }.to raise_error SystemExit
    end
  end

  describe "#run_loop" do
    it "should process" do
      subject.should_receive(:process).and_raise(SystemExit)
      expect{ subject.run_loop }.to raise_error(SystemExit)
    end
  end
end
