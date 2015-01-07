require 'spec_helper'

module Mobylette
  describe RespondToMobileRequests do
    describe 'Configuration' do

      class MockConfigurationController < ActionController::Base
        include Mobylette::RespondToMobileRequests
      end

      subject { MockConfigurationController.new }

      describe "basic configuration delegation" do

        describe "#mobilette_config" do
          it "should set mobylette_options" do
            subject.class.mobylette_config do |config|
              config[:fallback_chains]   = { mobile: [:mobile, :html, :js] }
              config[:skip_xhr_requests] = false
            end
            expect(subject.mobylette_options[:fallback_chains]).to eq({ mobile: [:mobile, :html, :js] })
            expect(subject.mobylette_options[:skip_xhr_requests]).to be_falsey
          end
        end

        describe "devices" do
          it "should register devices to Mobylette::Devices" do
            subject.class.mobylette_config do |config|
              config[:devices] = {phone1: %r{phone_1}, phone2: %r{phone_2}}
            end
            expect(Mobylette::Devices.instance.device(:phone1)).to eq(/phone_1/)
            expect(Mobylette::Devices.instance.device(:phone2)).to eq(/phone_2/)
          end
        end

        describe "fallbacks" do
          context "compatibility with deprecated fall back" do
            it "should configure the fallback device with only one fallback" do
              mobylette_resolver = double("resolver", replace_fallback_formats_chain: "")
              expect(mobylette_resolver).to receive(:replace_fallback_formats_chain).with({ mobile: [:mobile, :spec] })
              allow(subject.class).to receive(:mobylette_resolver).and_return(mobylette_resolver)
              subject.class.mobylette_config do |config|
                config[:fall_back] = :spec
                config[:fallback_chains] = { mobile: [:mobile, :mp3] }
              end
            end
          end

          context "chained fallback" do
            it "should use the fallback chain" do
              mobylette_resolver = double("resolver", replace_fallback_formats_chain: "")
              expect(mobylette_resolver).to receive(:replace_fallback_formats_chain).with({ iphone: [:iphone, :mobile], mobile: [:mobile, :html] })
              allow(subject.class).to receive(:mobylette_resolver).and_return(mobylette_resolver)
              subject.class.mobylette_config do |config|
                config[:fall_back] = nil # reset to the default state
                config[:fallback_chains] = { iphone: [:iphone, :mobile], mobile: [:mobile, :html] }
              end
            end
          end

        end
      end
    end
  end
end
