$:.push File.expand_path("lib", __FILE__)

require 'spec_helper'
require 'build_status_server'

describe BuildStatusServer::Server do
  let(:server) { BuildStatusServer::Server.new }

  describe "#listen"

  context "private methods" do
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

    describe "#notify"
    describe "#process_all_statuses"
    describe "#process_job"

    describe "#should_process_build" do
      context "when mask exists" do
        before do
          server.stub!(:mask).and_return(%r{.*(?:master).*})
        end

        context "when policy is include" do
          before do
            server.stub!(:mask_policy).and_return("include")
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
            server.config.stub!(:mask).and_return({"policy" => "exclude", "regex" => /.*(?:master).*/})
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

      context "when mask doesn't" do
        before do
          server.config.stub!(:mask).and_return({"policy" => "include", "regex" => nil})
        end

        it "should process all jobs" do
          server.send(:should_process_build, "blah-development").should be_true
        end
      end
    end
  end
end

# vim:set foldmethod=syntax foldlevel=1:
