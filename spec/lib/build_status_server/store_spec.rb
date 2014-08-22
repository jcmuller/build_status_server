require 'spec_helper'
require 'tempfile'

describe BuildStatusServer::Store do
  let(:config) { BuildStatusServer::Config.new }

  subject { described_class.new(config) }

  describe "#initialize" do
    before { described_class.any_instance.stub(:read) }

    it "should call read" do
      described_class.any_instance.should_receive(:read)
      subject
    end
  end

  describe "#read" do
    it "should parse store_file" do
      YAML.should_receive(:load_file).and_return({ a: :b })
      subject.send(:store).should == { a: :b }
    end

    it "should assign an empty hash if it fails parsing yaml" do
      YAML.should_receive(:load_file).and_raise
      subject.send(:store).should == {}
    end

    it "should assign an empty hash if yaml isn't a hash" do
      YAML.should_receive(:load_file).and_return([1, 2, 3])
      subject.send(:store).should == {}
    end
  end

  describe "#[]=" do
    before do
      subject.stub(:write)
    end

    it "should set name => status on store" do
      subject[:foo] = :bar
      subject.send(:store)[:foo].should == :bar
    end

    it "should write file with new contents" do
      subject.should_receive(:write)
      subject[:foo] = :bar
    end
  end

  describe "#write" do
    it "should write file with contents of store" do
      subject

      subject.should_receive(:store).and_return("store")

      file = double
      file.should_receive(:flock).with(File::LOCK_EX)
      file.should_receive(:flock).with(File::LOCK_UN)

      subject.should_receive(:store_file).and_return("store_file")

      File.should_receive(:open).with("store_file", "w").and_yield(file)

      YAML.should_receive(:dump).with("store", file)

      subject.write
    end

    it "the actual file should be written" do
      store_file = Tempfile.new("store_file")
      subject.should_receive(:store_file).and_return(store_file.path)
      subject.should_receive(:store).and_return({ 'foo' => 'bar' })
      subject.write

      store_file.read.should == "---\nfoo: bar\n"
      store_file.close
      store_file.unlink
    end
  end

  describe "#passing_builds?" do
    let(:values) { [] }
    let(:store) { double(values: values) }

    before do
      described_class.any_instance.stub(:read)
      subject.stub(:store).and_return(store)
    end

    it "returns true" do
      values << "pass"
      should be_passing_builds
    end

    it "returns true" do
      values << "pass" << "SUCCESS"
      should be_passing_builds
    end

    it "returns false" do
      values << "pass" << "fail"
      should_not be_passing_builds
    end

    it "returns false" do
      values << "SUCCESS" << "FAILURE"
      should_not be_passing_builds
    end
  end
end
