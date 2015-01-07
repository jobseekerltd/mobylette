require 'spec_helper'

describe ApplicationController do

  describe 'Helmet' do

    describe "#force_mobile_request_agent" do
      it "should set request.user_agent to Android by default" do
        force_mobile_request_agent
        expect(request.user_agent).to eq('Android')
      end

      it "should set request.user_agent to whatever the argument is" do
        force_mobile_request_agent(:any_value)
        expect(request.user_agent).to eq(:any_value)
      end
    end

    describe "#reset_test_request_agent" do
      it "should reset request.user_agent to rails default" do
        force_mobile_request_agent(:something_else)
        expect(request.user_agent).to eq(:something_else)
        reset_test_request_agent
        expect(request.user_agent).to eq('Rails Testing')
      end
    end

    describe "#set_session_override" do
      it "should set the session[mobylette_override] to whatever value the argument is" do
        set_session_override(:super_testing)
        expect(session[:mobylette_override]).to eq(:super_testing)
      end
    end

  end

end
