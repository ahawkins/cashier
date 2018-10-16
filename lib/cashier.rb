# frozen_string_literal: true

module Cashier
  CACHE_KEY = 'cashier-tags'

  class << self
    # Public: whether the module will perform caching or not. this is being set in the application layer .perform_caching configuration
    #
    # Examples
    #
    #   Cashier.perform_caching?
    #   # => true
    #
    def perform_caching?
      ::ApplicationController.perform_caching
    end

    # Public: store a fragment with an array of tags for this fragment.
    #
    # fragment - cached fragment.
    # tags - array of tags you want to assign this fragments.
    #
    # Examples
    #
    #   Cachier.store_fragment('foo', 'tag1', 'tag2', 'tag3')
    #
    def store_fragment(fragment, *tags)
      return unless perform_caching?

      tags = tags.flatten

      ActiveSupport::Notifications.instrument('store_fragment.cashier', data: [fragment, tags]) do
        tags.each do |tag|
          # store the fragment
          adapter.store_fragment_in_tag(fragment, tag)
        end

        # now store the tag for book keeping
        adapter.store_tags(tags)
      end
    end

    # Public: expire tags. expiring the keys 'assigned' to the tags you expire and removes the tags from the tags list
    #
    # tags - array of tags to expire.
    #
    # Examples
    #
    #   Cashier.expire('tag1', 'tag2')
    #
    def expire(*tags)
      return unless perform_caching?

      ActiveSupport::Notifications.instrument('expire.cashier', data: tags) do
        # delete them from the cache
        delete_fragments_from_cache(tags)

        # now remove them from the list
        # of stored tags
        adapter.remove_tags(tags)
      end
    end

    # Public: returns the array of tags stored in the tags store.
    #
    #
    # Examples
    #
    #   Cashier.tags
    #   # => ['tag1', 'tag2']
    #
    def tags
      adapter.tags
    end

    # Public: clears the tags.
    #
    #
    # Examples
    #
    #   Cashier.clear
    #
    def clear
      ActiveSupport::Notifications.instrument('clear.cashier') do
        # delete them from the cache
        delete_fragments_from_cache(tags)

        adapter.clear
        tags.count
      end
    end

    # Public: get all the keys names as an array.
    #
    #
    # Examples
    #
    #   Cachier.keys
    #   # => ['key1', 'key2', 'key3']
    #
    def keys
      adapter.keys
    end

    # Public: get all the keys for a specific tag as an array.
    #
    #
    # Examples
    #
    #   Cashier.tags_for('tag1')
    #   # => ['key1', 'key2', 'key3']
    #
    def keys_for(tag)
      adapter.get_fragments_for_tag(tag)
    end

    # Public: adapter which is used by cashier.
    # Defaults to :cache_store
    #
    # Examples
    #
    #   Cashier.adapter
    #   # => Cashier::Adapters::CacheStore
    #
    #   Cashier.adapter
    #   # => Cashier::Adapters::RedisStore
    #
    def adapter
      @adapter ||= :cache_store
      if @adapter == :cache_store
        Cashier::Adapters::CacheStore
      else
        Cashier::Adapters::RedisStore
      end
    end

    # Public: set the adapter the Cashier module will use to store the keys
    #
    # cache_adapter - :cache_store / :redis_store
    #
    # Examples
    #
    #   Cashier.adapter = :redis_store
    #
    attr_writer :adapter

    private

    def delete_fragments_from_cache(tags)
      tags.each do |tag|
        fragment_keys = adapter.get_fragments_for_tag(tag)

        # Delete each fragment from the cache.
        fragment_keys.each_slice(100) do |keys|
          keys.each do |key|
            Rails.cache.delete(key)
          end
        end

        adapter.delete_tag(tag)
      end
    end
  end
end

require 'rails'
require 'cashier/railtie'
require 'cashier/adapters/cache_store'
require 'cashier/adapters/redis_store'

# Connect cashier up to the low level Rails cache.
ActiveSupport::Notifications.subscribe('cache_write.active_support') do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload
  Cashier.store_fragment payload[:key], payload[:tag] if payload[:tag]
end
