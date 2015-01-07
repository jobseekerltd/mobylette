require 'spec_helper'

module Mobylette
  describe RespondToMobileRequests do

    class MockController < ActionController::Base
      include Mobylette::RespondToMobileRequests
    end

    subject { MockController.new }

    describe "#is_mobile_request?" do
      it "should be false for a normal request" do
        subject.stub_chain(:request, :user_agent).and_return('some mozilla')
        expect(subject.send(:is_mobile_request?)).to be_falsey
      end

      Mobylette::MobileUserAgents.new.call.to_s.split('|').each do |agent|
        agent.gsub!('\\', '')
        it "should be true for the agent #{agent}" do
          subject.stub_chain(:request, :user_agent).and_return(agent)
          expect(subject.send(:is_mobile_request?)).to be_truthy
        end
      end
    end

    describe "#is_mobile_view?" do
      context "from param" do

        before(:each) do
          request = double("request")
          allow(request).to receive(:format).and_return(false)
          allow(subject).to receive(:request).and_return(request)
        end

        it "should be true if param[:format] is mobile" do
          allow(subject).to receive(:params).and_return({format: 'mobile'})
          expect(subject.send(:is_mobile_view?)).to be_truthy
        end

        it "should be false if param[:format] is not mobile" do
          allow(subject).to receive(:params).and_return({format: 'html'})
          expect(subject.send(:is_mobile_view?)).to be_falsey
        end
      end

      context "from request" do

        before(:each) do
          allow(subject).to receive(:params).and_return({format: 'html'})
          @request = double("request")
          allow(subject).to receive(:request).and_return(@request)
        end

        it "should be true if request.format is :mobile" do
          allow(@request).to receive(:format).and_return(:mobile)
          expect(subject.send(:is_mobile_view?)).to be_truthy
        end

        it "should be false if request.format is not :mobile" do
          allow(@request).to receive(:format).and_return(:html)
          expect(subject.send(:is_mobile_view?)).to be_falsey
        end
      end
    end

    describe "#stop_processing_because_xhr?" do

      context "this is a xhr request" do
        before(:each) do
          subject.stub_chain(:request, :xhr?).and_return(true)
        end

        it "should return false if :skip_xhr_requests is false" do
          subject.mobylette_options[:skip_xhr_requests] = false
          expect(subject.send(:stop_processing_because_xhr?)).to be_falsey
        end

        it "should return true if :skip_xhr_requests is true" do
          subject.mobylette_options[:skip_xhr_requests] = true
          expect(subject.send(:stop_processing_because_xhr?)).to be_truthy
        end

      end

      context "this is not a xhr request" do
        before(:each) do
          subject.stub_chain(:request, :xhr?).and_return(false)
        end

        it "should return false when :skip_xhr_requests is false" do
          subject.mobylette_options[:skip_xhr_requests] = false
          expect(subject.send(:stop_processing_because_xhr?)).to be_falsey
        end

        it "should return false when :skip_xhr_requests is true" do
          subject.mobylette_options[:skip_xhr_requests] = true
          expect(subject.send(:stop_processing_because_xhr?)).to be_falsey
        end

      end
    end

    describe "#stop_processing_because_param?" do
      it "should be true if the param is present" do
        allow(subject).to receive(:params).and_return(skip_mobile: 'true')
        expect(subject.send(:stop_processing_because_param?)).to be_truthy
      end

      it "should be false if the param is not present" do
        allow(subject).to receive(:params).and_return({})
        expect(subject.send(:stop_processing_because_param?)).to be_falsey
      end
    end

    describe "#force_mobile_by_session?" do
      it "should be true if the force_mobile is enabled in the session" do
        allow(subject).to receive(:session).and_return({mobylette_override: :force_mobile})
        expect(subject.send(:force_mobile_by_session?)).to be_truthy
      end

      it "should be false if the force_mobile is not enabled in the session" do
        allow(subject).to receive(:session).and_return({})
        expect(subject.send(:force_mobile_by_session?)).to be_falsey
      end
    end

    describe "#respond_as_mobile?" do
      context "with impediments" do

        before(:each) do
          allow(subject).to receive(:stop_processing_because_xhr?).and_return(false)
          allow(subject).to receive(:stop_processing_because_param?).and_return(false)
          allow(subject).to receive(:force_mobile_by_session?).and_return(true)
          allow(subject).to receive(:is_mobile_request?).and_return(true)
          allow(subject).to receive(:params).and_return({format: 'mobile'})
        end

        it "should return false if stop_processing_because_xhr? is true" do
          allow(subject).to receive(:stop_processing_because_xhr?).and_return(true)
          expect(subject.send(:respond_as_mobile?)).to be_falsey
        end

        it "should return false if stop_processing_because_xhr? is false" do
          allow(subject).to receive(:stop_processing_because_xhr?).and_return(false)
          expect(subject.send(:respond_as_mobile?)).to be_truthy
        end

        it "should return false if stop_processing_because_param? is true" do
          allow(subject).to receive(:stop_processing_because_param?).and_return(true)
          expect(subject.send(:respond_as_mobile?)).to be_falsey
        end

        it "should return false if stop_processing_because_param? is false" do
          allow(subject).to receive(:stop_processing_because_param?).and_return(false)
          expect(subject.send(:respond_as_mobile?)).to be_truthy
        end
      end

      context "with no impediments" do
        before(:each) do
          allow(subject).to receive(:stop_processing_because_xhr?).and_return(false)
          allow(subject).to receive(:stop_processing_because_param?).and_return(false)
          allow(subject).to receive(:force_mobile_by_session?).and_return(false)
          allow(subject).to receive(:is_mobile_request?).and_return(false)
          allow(subject).to receive(:params).and_return({})
          request = double("request", user_agent: "android")
          allow(subject).to receive(:request).and_return(request)
        end

        it "should be true if force_mobile_by_session? is true" do
          allow(subject).to receive(:force_mobile_by_session?).and_return(true)
          expect(subject.send(:respond_as_mobile?)).to be_truthy
        end

        it "should be true if is_mobile_request? is true" do
          allow(subject).to receive(:is_mobile_request?).and_return(true)
          expect(subject.send(:respond_as_mobile?)).to be_truthy
        end

        it "should be true if params[:format] is mobile" do
          allow(subject).to receive(:params).and_return({format: 'mobile'})
          expect(subject.send(:respond_as_mobile?)).to be_truthy
        end
      end

      context "with skip_user_agents config option set" do
        before(:each) do
          allow(subject).to receive(:stop_processing_because_xhr?).and_return(false)
          allow(subject).to receive(:stop_processing_because_param?).and_return(false)
          allow(subject).to receive(:force_mobile_by_session?).and_return(false)
          #subject.stub(:is_mobile_request?).and_return(true)
          allow(subject).to receive(:params).and_return({})
          request = double("request", user_agent: "ipad")
          allow(subject).to receive(:request).and_return(request)
        end

        it "should be false if skip_user_agents contains the current user agent" do
          subject.mobylette_options[:skip_user_agents] = [:ipad, :android]
          expect(subject.send(:respond_as_mobile?)).to be_falsey
        end

        it "should be true if skip_user_agents is not set" do
          subject.mobylette_options[:skip_user_agents] = []
          expect(subject.send(:respond_as_mobile?)).to be_truthy
        end

        it "should be true if skip_user_agents does not contain the current user agent" do
          subject.mobylette_options[:skip_user_agents] = [:android]
          expect(subject.send(:respond_as_mobile?)).to be_truthy
        end

      end
    end

    describe "#handle_mobile" do
      it "should be false when mobylette_override is set to ignore_mobile in the session" do
        allow(subject).to receive(:session).and_return({mobylette_override: :ignore_mobile})
        expect(subject.send(:handle_mobile)).to be_falsey
      end

      it "should be nil if this is not supposed to respond_as_mobile" do
        allow(subject).to receive(:session).and_return({})
        allow(subject).to receive(:respond_as_mobile?).and_return(false)
        expect(subject.send(:handle_mobile)).to be_nil
      end

      context "respond_as_mobile? is true" do
        before(:each) do
          allow(subject).to receive(:session).and_return({})
          allow(subject).to receive(:respond_as_mobile?).and_return(true)
          @format  = double("old_format", to_sym: :old_format)
          @formats = []
          @request = double("request", user_agent: "android", format: @format, formats: @formats)
          allow(@request).to receive(:format=) { |new_value| @format = new_value }
          allow(subject).to receive(:request).and_return(@request)
          subject.mobylette_options[:fall_back] = false
        end

        it "should set request.format to :mobile" do
          subject.send(:handle_mobile)
          expect(@format).to eq(:mobile)
        end

      end
    end

    describe "#request_device?" do
      it "should match a device" do
        subject.stub_chain(:request, :user_agent).and_return('very custom browser WebKit')
        Mobylette.devices.register(custom_phone: %r{custom\s+browser})
        expect(subject.send(:request_device?, :iphone)).to be_falsey
        expect(subject.send(:request_device?, :custom_phone)).to be_truthy
      end
      it "should match an android phone" do
        subject.stub_chain(:request, :user_agent).and_return('This is Android browser Mobile')
        expect(subject.send(:request_device?, :iphone)).to be_falsey
        expect(subject.send(:request_device?, :android_phone)).to be_truthy
      end
    end

    describe "#set_mobile_format" do
      context "matching format in fallback chain" do
        it "should return the request device format when it is in a chain" do
          subject.mobylette_options[:fallback_chains] = { html: [:html, :htm], mp3: [:mp3, :wav, :mid] }
          allow(subject).to receive(:request_device?).with(:mp3).and_return(true)
          allow(subject).to receive(:request_device?).with(:html).and_return(false)
          expect(subject.send(:set_mobile_format)).to eq(:mp3)
        end
      end

      context "not matching format in fallback chain" do
        it "should return :mobile" do
          subject.mobylette_options[:fallback_chains] = { html: [:html, :htm], mp3: [:mp3, :wav, :mid] }
          subject.stub_chain(:request, :user_agent).and_return("android")
          expect(subject.send(:set_mobile_format)).to eq(:mobile)
        end
      end
    end

  end
end
