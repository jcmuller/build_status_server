require 'spec_helper'

describe BuildStatusServer::CLI do
  describe ".run" do
    it "should instantiate and call run" do
      obj = double
      described_class.should_receive(:new).and_return(obj)
      obj.should_receive(:setup_and_run)
      described_class.run
    end
  end

  describe "#setup_and_run" do
    it "should setup and run" do
      subject.should_receive(:setup)
      subject.should_receive(:run)
      subject.setup_and_run
    end
  end

  describe "#setup" do
    before do
      subject.stub(:set_program_name)
      subject.stub(:process_command_line_options)
      subject.stub(:show_help_and_exit)
    end

    it "should set program name" do
      subject.should_receive(:set_program_name)
      subject.setup
    end

    it "should process command line options" do
      subject.should_receive(:process_command_line_options)
      subject.setup
    end

    it "should show help and exit on missing argument" do
      subject.should_receive(:process_command_line_options).and_raise(GetoptLong::MissingArgument)
      subject.should_receive(:show_help_and_exit)
      subject.setup
    end

    it "should show help and exit on invalid option" do
      subject.should_receive(:process_command_line_options).and_raise(GetoptLong::InvalidOption)
      subject.should_receive(:show_help_and_exit)
      subject.setup
    end
  end

  describe "#run" do
    it "should instantiate a runnner and call listen on it" do
      runner = double
      runner.should_receive(:listen)
      BuildStatusServer::Runner.should_receive(:new).and_return(runner)

      subject.run
    end
  end

  describe "#options_possible" do
    it "should return an array of options" do
      options = subject.send(:options_possible)
      options.class.should == Array
      options[0][0].should =~ /^--\w+/
      options[0][1].should =~ /^-\w$/
      options[0][2].class.should == Fixnum
    end
  end

  describe "#process_command_line_options" do
    let(:options) { {} }

    before do
      subject.stub(:cli_options).and_return(options)
    end

    it "should show help and exit when called with --help" do
      options["--help"] = nil
      subject.should_receive(:show_help_and_exit)
      subject.send(:process_command_line_options)
    end

    it "should override config option when called with --config" do
      options["--config"] = "config"
      subject.send(:process_command_line_options)
      subject.instance_variable_get(:"@options").should == { config: "config"}
    end

    it "should set verbose config option when called with --verbose" do
      options["--verbose"] = nil
      subject.send(:process_command_line_options)
      subject.instance_variable_get(:"@options").should == { verbose: true}
    end

    it "should show version and exit when called with --version" do
      options["--version"] = nil
      subject.should_receive(:version_info).and_return("version")
      STDOUT.should_receive(:puts).with("version")
      expect{ subject.send(:process_command_line_options) }.to raise_error SystemExit
    end

  end

  describe "#cli_options" do
    it "should instantiate a GetoptLong object" do
      GetoptLong.should_receive(:new)
      subject.send(:cli_options)
    end
  end

  describe "#version_info" do
    it "should print nice things" do
      subject.should_receive(:program_name).and_return("program_name")
      subject.should_receive(:version).and_return("version")
      subject.send(:version_info).should == <<-EOV
program_name, version version

(c) Juan C. Muller, 2012
http://github.com/jcmuller/build_status_server
      EOV
    end
  end

  describe "#show_help_and_exit" do
    it "should call help_info" do
      subject.should_receive(:help_info).and_return("help_info")
      STDOUT.should_receive(:puts).with("help_info")
      expect{ subject.send(:show_help_and_exit) }.to raise_error SystemExit
    end
  end

  describe "#set_program_name" do
    it do
      subject.should_receive(:version).and_return("version")
      subject.send(:set_program_name)
      subject.program_name.should == "rspec (version)"
    end
  end

  describe "version" do
    it { subject.send(:version).should match(/^\d+\.\d+$/) }
  end
end
