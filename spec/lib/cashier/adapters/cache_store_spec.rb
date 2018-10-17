# frozen_string_literal: true

require 'spec_helper'

describe Cashier::Adapters::CacheStore do
  subject(:cache_store) { described_class }

  let(:cache) { Rails.cache }

  it 'stores the fragment in a tag' do
    cache_store.store_fragment_in_tag('fragment-key', 'dashboard')
    expect(cache.fetch('dashboard')).to eq(['fragment-key'])
  end

  it 'stores the tag in the tags array' do
    cache_store.store_tags(['dashboard'])
    expect(cache.fetch(Cashier::CACHE_KEY)).to eq(['dashboard'])
  end

  it 'returns all of the fragments for a given tag' do
    cache_store.store_fragment_in_tag('fragment-key', 'dashboard')
    cache_store.store_fragment_in_tag('fragment-key-2', 'dashboard')
    cache_store.store_fragment_in_tag('fragment-key-3', 'dashboard')

    expect(cache_store.get_fragments_for_tag('dashboard').length).to eq(3)
  end

  it 'deletes a tag from the cache' do
    cache_store.store_fragment_in_tag('fragment-key', 'dashboard')
    expect(Rails.cache.read('dashboard')).not_to be_nil

    cache_store.delete_tag('dashboard')
    expect(Rails.cache.read('dashboard')).to be_nil
  end

  it 'returns the list of tags' do
    (1..5).each { |i| cache_store.store_tags(["tag-#{i}"]) }
    expect(cache_store.tags.length).to eq(5)
  end

  it 'returns the tags correctly' do
    cache_store.store_tags(['tag-1', 'tag-2', 'tag-3'])
    expect(cache_store.tags).to include('tag-1')
  end

  it 'removes tags from the tags list' do
    (1..5).each { |i| cache_store.store_tags(["tag-#{i}"]) }
    cache_store.remove_tags(['tag-1', 'tag-2', 'tag-3', 'tag-4', 'tag-5'])
    expect(cache_store.tags.length).to be_zero
  end

  describe 'clear' do
    before do
      cache_store.store_tags(['dashboard'])
      cache_store.store_tags(['settings'])
      cache_store.store_tags(['email'])
    end

    it 'clears the cache and remove all of the tags' do
      cache_store.clear
      expect(Rails.cache.read(Cashier::CACHE_KEY)).to be_nil
    end
  end

  describe 'keys' do
    it 'returns the list of keys' do
      cache_store.store_tags(%w[dashboard settings email])

      cache_store.store_fragment_in_tag('key1', 'dashboard')
      cache_store.store_fragment_in_tag('key2', 'settings')
      cache_store.store_fragment_in_tag('key3', 'email')

      expect(cache_store.keys).to eq(%w[key1 key2 key3])
    end
  end
end
