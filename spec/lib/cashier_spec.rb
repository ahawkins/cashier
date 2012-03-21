require 'spec_helper'

describe "Cashier" do
  context "Tags store adapters" do
    subject { Cashier }

    it "should allow me to set the keys adapter" do
      subject.respond_to?(:adapter=).should be_true
    end

    it "shold allow to get the adapter" do
      subject.respond_to?(:adapter).should be_true
    end
  end

  context "Cashier adapters communication through the interface" do
    before(:each) do
      Cashier.adapter = :cache_store
    end
    subject { Cashier }
    let(:adapter) { Cashier.adapter }

    describe "#store_fragment" do
      it "should write the tag to the cache" do
        adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
        adapter.should_receive(:store_tags).with(["dashboard"])

        subject.store_fragment('fragment-key', 'dashboard')
      end

      it "should store the tag for book keeping" do
        adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
        adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'settings')

        adapter.should_receive(:store_tags).with(["dashboard", "settings"])

        subject.store_fragment('fragment-key', 'dashboard', 'settings')
      end
    end

    describe "#expire" do
      before do
        subject.store_fragment('fragment-key', 'dashboard')
      end

      it "should remove delete the fragment key" do
        adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return(["fragment-key"])
        adapter.should_receive(:delete_tag).with('dashboard')
        adapter.should_receive(:remove_tags).with(['dashboard'])

        subject.expire('dashboard')
      end

      it "should remove the tag" do 
        adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return([])
        adapter.should_receive(:delete_tag).with('dashboard')
        adapter.should_receive(:remove_tags).with(['dashboard'])

        subject.expire('dashboard')
      end

      it "should remove the tag from the list of tracked tags"  do
        adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return(['fragment-key'])
        adapter.should_receive(:delete_tag).with('dashboard')

        subject.expire('dashboard')
      end
    end

    describe "#tags" do
      it "should return a list of active tags" do
        subject.store_fragment('key1', 'dashboard')
        subject.store_fragment('key2', 'settings')
        subject.store_fragment('key3', 'email')

        subject.tags.should eql(%w(dashboard settings email))
      end
    end

    describe '#clear' do
      before(:each) do
        subject.store_fragment('key1', 'dashboard')
        subject.store_fragment('key2', 'settings')
        subject.store_fragment('key3', 'email')
      end

      it "should expire all tags" do
        adapter.should_receive(:clear)
        subject.clear
      end

      it "should clear the list of tracked tags" do
        subject.clear
        adapter.tags.should == []
      end
    end

    describe '#keys' do
      it "should return an array of all the tracked keys" do
        adapter.should_receive(:keys).and_return(%w(key1 key2 key3))
        subject.keys.should eql(%w(key1 key2 key3))
      end
    end

    describe '#keys_for' do
      it "should return an array of all the keys for the tag" do
        adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return(%w(key1 key2 key3))
        subject.keys_for('dashboard').should eql(%w(key1 key2 key3))
      end
    end
  end

  context "plugins" do
    subject { Cashier }
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
      subject.store_fragment("foo", "bar")
    end

    it "should raise a callback method when I call clear" do
      subject.should_receive(:call_plugin_method).with(:on_clear)
      subject.clear
    end

    it "should raise a callback method when I call expire" do
      subject.should_receive(:call_plugin_method).with(:on_expire, ["some_tag"])
      subject.expire("some_tag")
    end

    it "should raise a callback when I call Rails.cache.delete" do
      subject.should_receive(:call_plugin_method).with(:on_delete_key, "some_key")
      Rails.cache.delete("some_key")
    end



  end
end
