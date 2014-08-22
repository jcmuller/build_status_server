require "spec_helper"
require "tempfile"

describe BuildStatusServer::Config do
  subject(:config) { described_class.new({}, false) }

  describe "#load" do
    it "should call load_config_file with options passed in" do
      options = { config: nil }
      subject.should_receive(:load_config_file).with(options[:config])
      subject.load(options)
    end

    it "should set the config values from yaml file" do
      config = subject.send(:get_example_config)
      subject.should_receive(:load_config_file).and_return(YAML.load(config))
      subject.load
      subject.udp_server.should == {"address" => "127.0.0.1", "port" => 1234}
      subject.verbose.should == false
    end
  end

  describe "#load_config_file" do
    it "should load the yaml file passed in as a file argument" do
      file_name = nil

      Tempfile.open(["config", ".yml"]) do |f|
        f.puts "---"
        f.puts "key: value"
        f.puts "key2: value2"
        file_name = f.path
      end

      subject.send(:load_config_file, file_name).should == {
        "key" => "value",
        "key2" => "value2"
      }
    end

    it "should try to load paths from the locations to try" do
      file_name = nil
      Tempfile.open(["config", ".yml"]) do |f|
        f.puts "---"
        f.puts "key: value"
        f.puts "key2: value2"
        file_name = f.path
      end

      subject.stub(:locations_to_try).and_return([file_name])
      subject.send(:load_config_file).should == {
        "key" => "value",
        "key2" => "value2"
      }
    end

    it "should throw an exception if the config file doesn't exist" do
      file_name = "/tmp/i_dont_exist.yml"
      expect { subject.send(:load_config_file, file_name) }.to raise_error RuntimeError, "Supplied config file (#{file_name}) doesn't seem to exist"
    end

    it "should throw an exception if the config file isn't a hash" do
      file_name = nil
      Tempfile.open(["base", ".yml"]) do |f|
        f.puts "YADDA YADDA"
        file_name = f.path
      end
      expect { subject.send(:load_config_file, file_name) }.to raise_error RuntimeError, "This is an invalid configuration file!"
    end

    it "should return the default options if no default location is found" do
      subject.should_receive(:show_config_file_suggestion)
      config_hash = subject.send(:load_config_file)
      config_hash["udp_server"]["address"].should == '127.0.0.1'
      config_hash["verbose"].should == false
    end
  end

  describe "#store_file" do
    before do
      subject.stub(:config).and_return({})
    end

    it "returns the store file configured" do
      subject.stub(:store).and_return("filename" => "/tmp/build_result.yml")
      subject.store_file.should == "/tmp/build_result.yml"
    end

    it "returns nil if config doesn't have store option" do
      subject.stub(:store).and_return(nil)
      subject.store_file.should be_nil
    end
  end

  describe "#method_missing" do
    it "should respond to methods named after elements in the config hash" do
      subject.send(:import_config, "blah" => 1)
      subject.blah.should == 1
    end

    it "should not respond to methods named after elements that don't exist" do
      expect{ subject.blah }.to raise_error NoMethodError
    end
  end

  describe "#respond_to_missing" do
    before { config.send(:import_config, "foo" => "bar") }
    it { expect(subject.send(:respond_to_missing?, :foo)).to eq true }
    it { expect(subject.send(:respond_to_missing?, :bar)).to eq false }
  end
end
