# frozen_string_literal: true

require 'spec_helper'

describe Cashier do
  subject(:cashier) { described_class }

  before do
    described_class.adapter = :cache_store
  end

  let(:adapter) { described_class.adapter }
  let(:cache) { Rails.cache }

  describe '#store_fragment' do
    it 'writes the tag to the cache' do
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
      adapter.should_receive(:store_tags).with(['dashboard'])

      cashier.store_fragment('fragment-key', 'dashboard')
    end

    it 'flattens tags' do
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
      adapter.should_receive(:store_tags).with(['dashboard'])

      cashier.store_fragment('fragment-key', ['dashboard'])
    end

    it 'stores the tag for book keeping' do
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'dashboard')
      adapter.should_receive(:store_fragment_in_tag).with('fragment-key', 'settings')

      adapter.should_receive(:store_tags).with(%w[dashboard settings])

      cashier.store_fragment('fragment-key', 'dashboard', 'settings')
    end
  end

  describe 'Cashier notifications' do
    let(:notification_system) { ActiveSupport::Notifications }

    it 'raises a callback when I call store_fragment' do
      notification_system.should_receive(:instrument).with('store_fragment.cashier', data: ['foo', ['bar']])
      cashier.store_fragment('foo', 'bar')
    end

    it 'raises a callback method when I call clear' do
      notification_system.should_receive(:instrument).with('clear.cashier')
      cashier.clear
    end

    it 'raises a callback method when I call expire' do
      notification_system.should_receive(:instrument).with('expire.cashier', data: ['some_tag'])
      cashier.expire('some_tag')
    end
  end

  describe '#expire' do
    before do
      cashier.store_fragment('fragment-key', 'dashboard')
    end

    it 'removes delete the fragment key' do
      adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return(['fragment-key'])
      adapter.should_receive(:delete_tag).with('dashboard')
      adapter.should_receive(:remove_tags).with(['dashboard'])

      cashier.expire('dashboard')
    end

    it 'removes the tag' do
      adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return([])
      adapter.should_receive(:delete_tag).with('dashboard')
      adapter.should_receive(:remove_tags).with(['dashboard'])

      cashier.expire('dashboard')
    end

    it 'removes the tag from the list of tracked tags' do
      adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return(['fragment-key'])
      adapter.should_receive(:delete_tag).with('dashboard')

      cashier.expire('dashboard')
    end
  end

  describe '#tags' do
    it 'returns a list of active tags' do
      cashier.store_fragment('key1', 'dashboard')
      cashier.store_fragment('key2', 'settings')
      cashier.store_fragment('key3', 'email')

      cashier.tags.sort.should eql(%w[dashboard settings email].sort)
    end
  end

  describe '#clear' do
    before do
      cashier.store_fragment('key1', 'dashboard')
      cashier.store_fragment('key2', 'settings')
      cashier.store_fragment('key3', 'email')
    end

    it 'is able to be cleared' do
      adapter.should_receive(:clear)
      cashier.clear
    end

    it 'expires all tagged fragments' do
      cache.write('a_cache_key', 'foo', tag: 'dashboard')
      cache.exist?('a_cache_key').should be true
      cashier.clear
      cache.exist?('a_cache_key').should be false
    end

    it 'expires all tags' do
      cashier.clear
      cache.exist?('a_cache_key').should be false
    end

    it 'clears the list of tracked tags' do
      cashier.clear
      adapter.tags.should == []
    end
  end

  describe '#keys' do
    it 'returns an array of all the tracked keys' do
      adapter.should_receive(:keys).and_return(%w[key1 key2 key3])
      cashier.keys.should eql(%w[key1 key2 key3])
    end
  end

  describe '#keys_for' do
    it 'returns an array of all the keys for the tag' do
      adapter.should_receive(:get_fragments_for_tag).with('dashboard').and_return(%w[key1 key2 key3])
      cashier.keys_for('dashboard').should eql(%w[key1 key2 key3])
    end
  end

  it 'allows me to set the adapter' do
    cashier.respond_to?(:adapter=).should be true
  end

  it 'shold allow to get the adapter' do
    cashier.respond_to?(:adapter).should be true
  end
end
