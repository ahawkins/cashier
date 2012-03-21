require 'spec_helper'

describe Cashier::Addons::Plugins do
  subject { Cashier::Addons::Plugins }
  let(:plugin) { DummyPlugin }
  let(:cashier) { Cashier }

  before(:each) do
    Cashier::Addons::Adapters.adapter = :cache_store
  end

  context "Adding and getting plugins" do
    it "should have add_plugin method" do
      subject.should respond_to(:add_plugin)
    end

    it "should have plugins method that returns an array" do
      subject.plugins.should == []
    end

    it "should be able to add a plugin" do
      subject.add_plugin(DummyPlugin)
      subject.plugins.should include(DummyPlugin)
    end

    it "should not add the same plugin class twice" do
      subject.add_plugin(DummyPlugin)
      subject.add_plugin(DummyPlugin)
      subject.plugins.length.should == 1
    end
  end

  context "Cashier callbacks" do
    it "should raise a callback when I call store_fragment" do
      subject.should_receive(:call_plugin_method).with(:on_store_fragment, ["foo", ["bar"]])
      Rails.cache.should_receive(:write).at_least(:twice)
      
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
      subject.should_receive(:call_plugin_method).with(:on_cache_delete, "some_key")
      Rails.cache.delete("some_key")
    end

    it "should raise a callback when I call Rails.cache.write" do
      subject.should_receive(:call_plugin_method).with(:on_cache_write, "foo")
      Rails.cache.write("foo", "bar")
    end
  end


  context "Plugin class callback methods" do
    before(:each) do
      subject.add_plugin(DummyPlugin)
      subject.plugins.should include(DummyPlugin)
    end

    it "should call the :on_cache_write method on the plugin" do
      plugin.should_receive(:on_cache_write).with("some_key")
      Rails.cache.write("some_key", "some_value")
    end

    it "should call the exception report if a method raises an exception" do
      exception = Exception.new("Boom!")
      plugin.should_receive(:on_cache_write).with("some_key").and_raise(exception)
      plugin.should_receive(:exception_report).with(exception)

      subject.call_plugin_method(:on_cache_write, "some_key")
    end
  end
end