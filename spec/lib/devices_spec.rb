require 'spec_helper'

module Mobylette
  describe Devices do
    
    describe "#register" do
      it "should accept a {key:value} and insert it into the devices list" do
        Devices.instance.register(crazy_phone: /woot/)
        expect(Devices.instance.instance_variable_get("@devices")[:crazy_phone]).to eq(/woot/)
      end

      it "should accept more than one key:value" do
        Devices.instance.register(awesomephone: /waat/, notthatcool: /sad/)
        expect(Devices.instance.instance_variable_get("@devices")[:awesomephone]).to eq(/waat/)
        expect(Devices.instance.instance_variable_get("@devices")[:notthatcool]).to eq(/sad/)
      end
    end

    describe "#device" do
      it "should return the regex for the informed device" do
        expect(Devices.instance.device(:iphone)).to eq(/iphone/i)
      end
    end
  end

  describe "#devices" do
    it "should be an alias to Mobylette::Devices.instance" do
      expect(Mobylette.devices).to eq(Mobylette::Devices.instance)
    end
  end
end
