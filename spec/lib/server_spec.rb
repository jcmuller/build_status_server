require 'lib/server'

describe Server do

  describe "#initialize" do
    it "initializes"
  end

  describe "#listen"

  describe "#load_store" do
    let!(:server) { Server.new }

    before do
      server.stub!(:store_file).and_return("/tmp/build")
    end

    it "tries to load the store file" do
      YAML.should_receive(:load_file).with("/tmp/build")
      server.load_store
    end

    it "initializes an empty hash if store file doesn't exist" do
      server.load_store
      server.store.should == {}
    end

    it "initializes an empty hash if store file is empty" do
      require "tempfile"
      f = Tempfile.new("server_spec")
      server.stub!(:store_file).and_return(f.path)

      server.load_store
      server.store.should == {}
    end

    it "initializes a hash with the contents of the store file" do
      server.stub!(:store_file).and_return("spec/support/build_result.yml")
      server.load_store

      server.store.should == {"blah" => "SUCCESS", "test" => "SUCCESS"}
    end
  end

  describe "#notify"
  describe "#process_all_statuses"
  describe "#process_job"

end

# vim:set foldmethod=syntax foldlevel=1:
