require 'spec_helper'

describe Cashier::Adapters::CacheStore do
  subject { Cashier::Adapters::CacheStore }
  let(:cache) { Rails.cache }

  it "should store the fragment in a tag" do
    subject.store_fragment_in_tag('fragment-key', 'dashboard')
    cache.fetch('dashboard').should eql(['fragment-key'])
  end

  it "should store the tag in the tags array" do
    subject.store_tags(["dashboard"])
    cache.fetch(Cashier::CACHE_KEY).should eql(['dashboard'])
  end

  it "should return all of the fragments for a given tag" do
    subject.store_fragment_in_tag('fragment-key', 'dashboard')
    subject.store_fragment_in_tag('fragment-key-2', 'dashboard')
    subject.store_fragment_in_tag('fragment-key-3', 'dashboard')

    subject.get_fragments_for_tag('dashboard').length.should == 3
  end

  it "should delete a tag from the cache" do
    subject.store_fragment_in_tag('fragment-key', 'dashboard')
    Rails.cache.read('dashboard').should_not be_nil

    subject.delete_tag('dashboard')
    Rails.cache.read('dashboard').should be_nil
  end

  it "should return the list of tags" do
    (1..5).each {|i| subject.store_tags(["tag-#{i}"])}
    subject.tags.length.should == 5
  end

  it "should return the tags correctly" do
    subject.store_tags(["tag-1", "tag-2", "tag-3"])
    subject.tags.include?("tag-1").should be_true
  end

  it "should remove tags from the tags list" do
    (1..5).each {|i| subject.store_tags(["tag-#{i}"])}
    subject.remove_tags(["tag-1", "tag-2", "tag-3", "tag-4", "tag-5"])
    subject.tags.length.should == 0
  end

  context "clear" do
    before(:each) do
      subject.store_tags(['dashboard'])
      subject.store_tags(['settings'])
      subject.store_tags(['email'])
    end

    it "should clear the cache and remove all of the tags" do
      subject.should_receive(:remove_tags).with(['dashboard','settings','email'])
      subject.clear
      Rails.cache.read(Cashier::CACHE_KEY).should be_nil
    end
  end

  context "keys" do
    it "should return the list of keys" do
      subject.store_tags(['dashboard', 'settings', 'email'])

      subject.store_fragment_in_tag('key1', 'dashboard')
      subject.store_fragment_in_tag('key2', 'settings')
      subject.store_fragment_in_tag('key3', 'email')

      subject.keys.should eql(%w(key1 key2 key3))
    end
  end
end
