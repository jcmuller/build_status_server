require 'lib/server'

describe Server do
  let!(:server) { Server.new }

  describe "#load_store" do

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

  describe "#should_process_build" do
    context "when mask exists" do
      before do
        server.stub!(:mask).and_return(/.*master.*/)
      end

      context "when policy is include" do
        before do
          server.stub!(:mask_policy).and_return("include")
        end

        it "ignores builds if mask doesn't match build name" do
          server.should_process_build("blah-development").should be_false
        end

        it "processes builds if mask matches build name" do
          server.should_process_build("blah-master").should be_true
        end
      end

      context "when policy is exclude" do
        before do
          server.stub!(:mask_policy).and_return("exclude")
        end

        it "ignores builds if mask matches build name" do
          server.should_process_build("blah-master").should be_false
        end

        it "processes builds if mask doesn't match build name" do
          server.should_process_build("blah-development").should be_true
        end
      end

      context "when policy is undefined" do
        before do
          server.stub!(:mask_policy).and_return(nil)
        end

        it "ignores builds if mask matches build name" do
          server.should_process_build("blah-master").should be_false
        end

        it "processes builds if mask doesn't match build name" do
          server.should_process_build("blah-development").should be_true
        end
      end

      context "when policy is unexpected" do
        before do
          server.stub!(:mask_policy).and_return("trash")
        end

        it "ignores builds if mask matches build name" do
          server.should_process_build("blah-master").should be_false
        end

        it "processes builds if mask doesn't match build name" do
          server.should_process_build("blah-development").should be_true
        end
      end
    end

    context "when mask doesn't" do
      before do
        server.stub!(:mask).and_return(nil)
      end

      it "should process all jobs" do
        server.should_process_build("blah-development").should be_true
      end
    end
  end
end

# vim:set foldmethod=syntax foldlevel=1:
