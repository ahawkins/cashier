require 'spec_helper'

describe "Cashier" do
  before(:each) do
    Cashier.adapter = :cache_store
  end

  subject { Cashier }

  let(:adapter) { Cashier.adapter }
  let(:cache) { Rails.cache }

  describe "#store_fragment" do
    it "should write the tag to the cache" do
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
      adapter.should_receive(:store_tags).with(["dashboard"])

      subject.store_fragment('fragment-key', 'dashboard')
    end

    it "should flatten tags" do
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
      adapter.should_receive(:store_tags).with(["dashboard"])

      subject.store_fragment('fragment-key', ['dashboard'])
    end

    it "should store the tag for book keeping" do
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'settings')

      adapter.should_receive(:store_tags).with(["dashboard", "settings"])

      subject.store_fragment('fragment-key', 'dashboard', 'settings')
    end
  end

  describe "Cashier notifications" do
    let(:notification_system) { ActiveSupport::Notifications }

    it "should raise a callback when I call store_fragment" do
      notification_system.should_receive(:instrument).with("store_fragment.cashier", :data => ["foo", ["bar"]])
      subject.store_fragment("foo", "bar")
    end

    it "should raise a callback method when I call clear" do
      notification_system.should_receive(:instrument).with("clear.cashier")
      subject.clear
    end

    it "should raise a callback method when I call expire" do
      notification_system.should_receive(:instrument).with("cache_read.active_support", :key => "cashier-tag-containers:some_tag")
      notification_system.should_receive(:instrument).with("expire.cashier", :data => ["some_tag"])
      subject.expire("some_tag")
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

      subject.tags.sort.should eql(%w(dashboard settings email).sort)
    end
  end

  describe '#clear' do
    before(:each) do
      subject.store_fragment('key1', 'dashboard')
      subject.store_fragment('key2', 'settings')
      subject.store_fragment('key3', 'email')
    end

    it "should be able to be cleared" do
      adapter.should_receive(:clear)
      subject.clear
    end

    it "should expire all tagged fragments" do
      cache.write('a_cache_key', 'foo', tag: 'dashboard')
      cache.exist?('a_cache_key').should be_true
      subject.clear
      cache.exist?('a_cache_key').should be_false
    end

    it "should expire all tags" do 
      subject.clear
      cache.exist?('a_cache_key').should be_false
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

  it "should allow me to set the adapter" do
    subject.respond_to?(:adapter=).should be_true
  end

  it "shold allow to get the adapter" do
    subject.respond_to?(:adapter).should be_true
  end

  it "should set a container cache key" do
    subject.container_cache_key(:something).should match(/something/)
  end

  it "should canonize ActiveRecord tags" do
    require 'active_record'

    ar_class = double("ar_class")
    ar_class.stub(name: :AR)

    ar = double("active_record")
    ar.stub(class: ar_class)
    ar.stub(is_a?: true)
    ar.stub(to_param: 123)

    res = Cashier.canonize_tags([1, 2, ar])
    res.should == [1, 2, "AR-123"]
  end
end
