require "rails_helper"

module Scram
  describe Scram::Holder do

    it "cannot be used without an implementation" do
      expect {UnimplementedHolder.new.policies}.to raise_error(NotImplementedError)
      expect {UnimplementedHolder.new.scram_compare_value}.to raise_error(NotImplementedError)
    end

    it "holds model permissions" do
      target = Target.new
      target.actions << "woot"

      policy = Policy.new
      policy.context = TestModel.name # A misc policy for strings
      policy.targets << target
      dude = SimpleHolder.new(policies: [policy]) # This is a test holder, his scram_compare_value by default is "Mr. Holder Guy"

      # Check that it tests a field equals something
      target.conditions = {:equals => { :targetable_int =>  3}}
      policy.save
      expect(dude.can? :woot, TestModel.new).to be true

      # Check that it tests a field is less than something
      target.conditions = {:less_than => { :targetable_int =>  4}}
      policy.save
      expect(dude.can? :woot, TestModel.new).to be true

      # Test that it checks if an array includes something
      target.conditions = {:includes => {:targetable_array => "a"}}
      policy.save
      expect(dude.can? :woot, TestModel.new).to be true

      # Test that it checks if a document is owned by holder
      target.conditions = {:equals => {:owner => "*holder"}}
      policy.save
      expect(dude.can? :woot, TestModel.new(owner: "Mr. Holder Guy")).to be true
      expect(dude.can? :woot, TestModel.new(owner: "Mr. Holder Dude")).to be false

    end


    it "provides a negated check helper" do
      target = Target.new
      target.conditions = {:equals => { :'*target_name' =>  "donk"}}
      target.actions << "woot"

      policy = Policy.new
      policy.name = "globals" # A misc policy for strings, context wil be nil!
      policy.targets << target

      policy.save

      dude = SimpleHolder.new(policies: [policy]) # This is a test holder
      expect(dude.cannot? :woot, :donk).to be false
      expect(dude.cannot? :woot, :donkers).to be true
    end

    it "holds string permissions" do
      target = Target.new
      target.conditions = {:equals => { :'*target_name' =>  "donk"}}
      target.actions << "woot"

      policy = Policy.new
      policy.name = "globals" # A misc policy for strings, context wil be nil!
      policy.targets << target

      policy.save

      dude = SimpleHolder.new(policies: [policy]) # This is a test holder
      expect(dude.can? :woot, :donk).to be true
      expect(dude.can? :woot, :donkers).to be false
    end

    it "differentiates model and string policies" do
      string_policy = Policy.new
      string_policy.context = "non-existent-model"
      string_policy.save

      expect(string_policy.model?).to be false

      model_policy = Policy.new
      model_policy.context = SimpleHolder.name
      model_policy.save

      expect(model_policy.model?).to be true
    end

    it "prioritizes policies" do
      # Allow zing and woot
      target1 = Target.new
      target1.actions << "woot"
      target1.actions << "zing"

      policy1 = Policy.new
      policy1.context = TestModel.name # A misc policy for strings
      policy1.targets << target1

      # Deny woot in higher priority policy
      target2 = Target.new
      target2.actions << "woot"
      target2.allow = false

      policy2 = Policy.new
      policy2.context = TestModel.name # A misc policy for strings
      policy2.priority = 1
      policy2.targets << target2

      user = SimpleHolder.new(policies: [policy1, policy2])
      expect(user.can? :woot, TestModel.new).to be false
      expect(user.can? :donk, TestModel.new).to be false
      expect(user.can? :zing, TestModel.new).to be true
    end

  end
end
