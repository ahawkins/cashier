require 'spec_helper'

describe Cashier::Addons::Plugins do
    subject { Cashier::Addons::Plugins }
    let(:cashier) { Cashier }

    before(:each) do
      Cashier.adapter = :cache_store
    end

    it "should have add_plugin method" do
      subject.respond_to?(:add_plugin).should be_true
    end

    it "should have plugins method that returns an array" do
      subject.plugins.should == []
    end

    it "should be able to add a plugin" do
      subject.add_plugin(DummyPlugin)
      subject.plugins.include?(DummyPlugin).should be_true
    end

    it "should raise a callback when I call store_fragment" do
      subject.should_receive(:call_plugin_method).with(:on_store_fragment, "foo", ["bar"])
      cashier.store_fragment("foo", "bar")
    end

    it "should raise a callback method when I call clear" do
      subject.should_receive(:call_plugin_method).at_least(:once)
      cashier.clear
    end

    it "should raise a callback method when I call expire" do
      subject.should_receive(:call_plugin_method).at_least(:once)
      cashier.expire("some_tag")
    end

    it "should raise a callback when I call Rails.cache.delete" do
      Cashier::Addons::Plugins.should_receive(:call_plugin_method).with(:on_delete_key, "some_key")
      Rails.cache.delete("some_key")
    end
end