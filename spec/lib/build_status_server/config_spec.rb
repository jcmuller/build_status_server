require "spec_helper"
require "build_status_server"
require "tempfile"

describe BuildStatusServer::Config do
  let(:config) { BuildStatusServer::Config.new }

  describe "#load" do
    it "should call load_config_file with options passed in" do
      options = {:config => nil}
      config.should_receive(:load_config_file).with(options[:config])
      config.load(options)
    end

    it "should set the config values from yaml file" do
      config.should_receive(:load_config_file).and_return(YAML.load(config.send(:get_example_config)))
      config.load
      config.udp_server.should == {"address" => "127.0.0.1", "port" => 1234}
      config.verbose.should == false
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

      config.send(:load_config_file, file_name).should == {
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

      config.stub!(:locations_to_try).and_return([file_name])
      config.send(:load_config_file).should == {
        "key" => "value",
        "key2" => "value2"
      }
    end

    it "should throw an exception if the config file doesn't exist" do
      file_name = "/tmp/i_dont_exist.yml"
      expect { config.send(:load_config_file, file_name) }.to raise_error RuntimeError, "Supplied config file (#{file_name}) doesn't seem to exist"
    end

    it "should throw an exception if the config file isn't a hash" do
      file_name = nil
      Tempfile.open(["base", ".yml"]) do |f|
        f.puts "YADDA YADDA"
        file_name = f.path
      end
      expect { config.send(:load_config_file, file_name) }.to raise_error RuntimeError, "This is an invalid configuration file!"
    end

    it "should return the default options if no default location is found" do
      STDERR.should_receive(:puts)
      config_hash = config.send(:load_config_file)
      config_hash["udp_server"]["address"].should == '127.0.0.1'
      config_hash["verbose"].should == false
    end
  end

  describe "#store_file" do
    it "returns the store file configured" do
      config.stub!(:store).and_return("filename" => "/tmp/build_result.yml")
      config.store_file.should == "/tmp/build_result.yml"
    end

    it "returns nil if config doesn't have store option" do
      config.stub!(:store).and_return(nil)
      config.store_file.should be_nil
    end
  end

  describe "#method_missing" do
    it "should respond to methods named after elements in the config hash" do
      config.send(:import_config, "blah" => 1)
      config.blah.should == 1
    end

    it "should not respond to methods named after elements that don't exist" do
      expect { config.blah }.should raise_error NoMethodError
    end
  end
end
