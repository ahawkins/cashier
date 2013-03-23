require 'spec_helper'

describe Cashier::Adapters::RedisStore do
  subject { Cashier::Adapters::RedisStore }
  let(:cache) { Rails.cache }
  let(:redis) { subject.redis }

  context "setting and getting the redis instance" do
    it "should allow to set the redis instance" do
      subject.respond_to?(:redis=).should be_true
    end

    it "should allow to get the redis instance" do
      subject.respond_to?(:redis).should be_true
    end
  end

  context "setting and getting the namespace" do
    it "should allow to set the namespace" do
      subject.respond_to?(:namespace=).should be_true
    end

    it "should allow to get the namespace which should always be an array" do
      subject.namespace = 'test'
      subject.respond_to?(:namespace).should be_true
      subject.namespace.should eql(['test'])
    end
  end

  context "the namespace" do
    it "should always be prepended to any redis key that is written" do
      subject.namespace = 'test'
      subject.store_tags(["dashboard"])
      subject.store_fragment_in_tag("something", "dashboard")
      redis.exists("test:dashboard").should be_true
      redis.exists("test:#{Cashier::CACHE_KEY}").should be_true
      subject.delete_tag('dashboard')
      subject.clear
      redis.exists("test:dashboard").should be_false
      redis.exists("test:#{Cashier::CACHE_KEY}").should be_false
    end
  end

  it "should return the redis instance you set" do
    subject.redis = redis
    subject.redis.should == redis
  end

  it "should store the fragment in a tag" do
    subject.store_fragment_in_tag('fragment-key', 'dashboard')
    redis.smembers('dashboard').should eql(['fragment-key'])
  end

  it "should store the tag in the tags array" do
    subject.store_tags(["dashboard"])
    redis.smembers(Cashier::CACHE_KEY).should eql(['dashboard'])
  end

  it "should return all of the fragments for a given tag" do
    subject.store_fragment_in_tag('fragment-key', 'dashboard')
    subject.store_fragment_in_tag('fragment-key-2', 'dashboard')
    subject.store_fragment_in_tag('fragment-key-3', 'dashboard')

    subject.get_fragments_for_tag('dashboard').length.should == 3
  end

  it "should delete a tag from the cache" do
    subject.store_fragment_in_tag('fragment-key', 'dashboard')
    redis.smembers('dashboard').should_not be_nil

    subject.delete_tag('dashboard')
    redis.exists('dashboard').should be_false
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
      subject.clear
      redis.smembers(Cashier::CACHE_KEY).should eql([])
    end
  end

  context "keys" do
    it "should return the list of keys" do
      subject.store_tags(['dashboard', 'settings', 'email'])

      subject.store_fragment_in_tag('key1', 'dashboard')
      subject.store_fragment_in_tag('key2', 'settings')
      subject.store_fragment_in_tag('key3', 'email')

      subject.keys.sort.should eql(%w(key1 key2 key3))
    end
  end
end
