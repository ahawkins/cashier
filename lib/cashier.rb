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

      ActiveSupport::Notifications.instrument("store_fragment.cashier", :data => [fragment, tags]) do
        tags.each do |tag|
          # store the fragment
          adapter.store_fragment_in_tag(fragment, tag)
        end

         # now store the tag for book keeping
        adapter.store_tags(tags)
      end
    end

    # Public: store a page path with an array of tags for this page
    #
    # page_path - cached page location.
    # tags - array of tags you want to assign this fragments.
    #
    # Examples
    #
    #   Cashier.store_page_path("page/path", "tag1", "tag2")
    #
    def store_page_path(page_path, *tags)
      return unless perform_caching?

      tags = tags.flatten

      ActiveSupport::Notifications.instrument("store_page_path.cashier", :data => [page_path, tags]) do
        tags.each do |tag|
          # store the page_path
          adapter.store_path_in_tag(page_path, tag)
        end

         # now store the tag for book keeping
        adapter.store_page_tags(tags)
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

      ActiveSupport::Notifications.instrument("expire.cashier", :data => tags) do
        # delete them from the cache
        tags.each do |tag|
          clear_fragments_for(tag)

          clear_page_paths_for(tag)
        end

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
      ActiveSupport::Notifications.instrument("clear.cashier") do
        # delete them from the cache
        tags.each do |tag|
          clear_fragments_for(tag)

          clear_page_paths_for(tag)

          # Delete the tag itself
          adapter.delete_tag(tag)
        end

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
      @@adapter ||= :cache_store
      if @@adapter == :cache_store
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
    def adapter=(cache_adapter)
      @@adapter = cache_adapter
    end

    private

    # Private: clear fragments
    #
    # Examples
    #
    #   Cashier.clear_fragments_for('tag1')
    #
    def clear_fragments_for(tag)
      fragment_keys = adapter.get_fragments_for_tag(tag)
      # Delete each fragment from the cache.
      fragment_keys.each do |fragment_key|
        Rails.cache.delete(fragment_key)
      end

      adapter.delete_tag(tag)
    end

    # Private: clear page paths
    #
    # Examples
    #
    #   Cashier.clear_page_paths_for('tag1')
    #
    def clear_page_paths_for(tag)
      page_paths = adapter.get_page_paths_for_tag(tag)

      # Clear each fragment from the page cache.
      page_paths.each do |page_path|
        ActionController::Base.expire_page(page_path)
      end

      adapter.delete_path_tag(tag)
    end
  end
end

require 'rails'
require 'cashier/railtie'
require 'cashier/adapters/cache_store'
require 'cashier/adapters/redis_store'

# Connect cashier up to the low level Rails cache.
ActiveSupport::Notifications.subscribe("cache_write.active_support") do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload
  Cashier.store_fragment payload[:key], payload[:tag] if payload[:tag]
end