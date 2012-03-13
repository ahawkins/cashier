module Cashier
  extend self

  CACHE_KEY = 'cashier-tags'

  def adapter
    if @@adapter == :cache_store
      Cashier::Adapters::CacheStore
    else
      Cashier::Adapters::RedisStore
    end
  end
  
  def adapter=(cache_adapter)
    @@adapter = cache_adapter
  end

  def perform_caching?
    ::ApplicationController.perform_caching
  end

  def store_fragment(fragment, *tags)
    return unless perform_caching?

    tags.each do |tag|
      # store the fragment
      adapter.store_fragment_in_tag(tag, fragment)
    end

     # now store the tag for book keeping
    adapter.store_tags(tags)
  end

  def expire(*tags)
    return unless perform_caching?

    # delete them from the cache
    tags.each do |tag|
      fragment_keys = adapter.get_fragments_for_tag(tag)
      
      fragment_keys.each do |fragment_key|
        Rails.cache.delete(fragment_key)
      end

      adapter.delete_tag(tag)
    end
    
    # now remove them from the list
    # of stored tags
    adapter.remove_tags(tags)
  end

  def tags
    adapter.tags
  end

  def clear
    expire(*tags)
    Rails.cache.delete(CACHE_KEY)
  end

  def wipe
    clear
  end

  def keys
    tags.inject([]) do |arry, tag|
      arry += Rails.cache.fetch(tag)
    end.compact
  end

  def keys_for(tag)
    Rails.cache.fetch(tag) || []
  end
end

require 'rails'
require 'cashier/railtie'
require 'cashier/adapters/cache_store'
require 'cashier/adapters/redis_store'
