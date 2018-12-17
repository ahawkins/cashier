# frozen_string_literal: true

require 'spec_helper'

describe Cashier::Adapters::RedisStore do
  subject(:redis_store) { described_class }

  let(:cache) { Rails.cache }
  let(:redis) { redis_store.redis }

  context 'setting and getting the redis instance' do
    it 'allows to set the redis instance' do
      redis_store.respond_to?(:redis=).should be true
    end

    it 'allows to get the redis instance' do
      redis_store.respond_to?(:redis).should be true
    end
  end

  it 'returns the redis instance you set' do
    redis_store.redis = redis
    redis_store.redis.should == redis
  end

  it 'stores the fragment in a tag' do
    redis_store.store_fragment_in_tag('fragment-key', 'dashboard')
    redis.smembers('dashboard').should eql(['fragment-key'])
  end

  it 'stores the tag in the tags array' do
    redis_store.store_tags(['dashboard'])
    redis.smembers(Cashier::CACHE_KEY).should eql(['dashboard'])
  end

  it 'returns all of the fragments for a given tag' do
    redis_store.store_fragment_in_tag('fragment-key', 'dashboard')
    redis_store.store_fragment_in_tag('fragment-key-2', 'dashboard')
    redis_store.store_fragment_in_tag('fragment-key-3', 'dashboard')

    redis_store.get_fragments_for_tag('dashboard').length.should == 3
  end

  it 'deletes a tag from the cache' do
    redis_store.store_fragment_in_tag('fragment-key', 'dashboard')
    redis.smembers('dashboard').should_not be_nil

    redis_store.delete_tag('dashboard')
    redis.exists('dashboard').should be false
  end

  it 'returns the list of tags' do
    (1..5).each { |i| redis_store.store_tags(["tag-#{i}"]) }
    redis_store.tags.length.should == 5
  end

  it 'returns the tags correctly' do
    redis_store.store_tags(['tag-1', 'tag-2', 'tag-3'])
    redis_store.tags.include?('tag-1').should be true
  end

  it 'removes tags from the tags list' do
    (1..5).each { |i| redis_store.store_tags(["tag-#{i}"]) }
    redis_store.remove_tags(['tag-1', 'tag-2', 'tag-3', 'tag-4', 'tag-5'])
    redis_store.tags.length.should == 0
  end

  context 'clear' do
    before do
      redis_store.store_tags(['dashboard'])
      redis_store.store_tags(['settings'])
      redis_store.store_tags(['email'])
    end

    it 'clears the cache and remove all of the tags' do
      redis_store.clear
      redis.smembers(Cashier::CACHE_KEY).should eql([])
    end
  end

  context 'keys' do
    it 'returns the list of keys' do
      redis_store.store_tags(%w[dashboard settings email])

      redis_store.store_fragment_in_tag('key1', 'dashboard')
      redis_store.store_fragment_in_tag('key2', 'settings')
      redis_store.store_fragment_in_tag('key3', 'email')

      redis_store.keys.sort.should eql(%w[key1 key2 key3])
    end
  end
end
