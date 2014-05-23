module Cashier

  CACHE_KEY = 'cashier-tags'

  def self.container_cache_key(tag)
    "cashier-tag-containers:#{tag}"
  end

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
      tags = canonize_tags(tags)

      ActiveSupport::Notifications.instrument("store_fragment.cashier", :data => [fragment, tags]) do
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

      # add tags of container fragments to expired tags list
      tags = canonize_tags(tags)
      containers = adapter.get_tags_containers(tags) || []
      tags = (tags + containers).compact.uniq

      ActiveSupport::Notifications.instrument("expire.cashier", :data => tags) do
        # delete them from the cache
        tags.each do |tag|
          fragment_keys = adapter.get_fragments_for_tag(tag)

          # Delete each fragment from the cache.
          fragment_keys.each do |fragment_key|
            Rails.cache.delete(fragment_key)
          end

          adapter.delete_tag(tag)
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
          fragment_keys = adapter.get_fragments_for_tag(tag)
          # Delete each fragment from the cache.
          fragment_keys.each do |fragment_key|
            Rails.cache.delete(fragment_key)
          end
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
      tag = canonize_tags(tag)
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

    # Public: add tags of a container fragment into the current container stack (used internally by ActiveSupport::Notifications)
    #
    # cache_adapter - :cache_store / :redis_store
    #
    # Examples
    #
    #   Cashier.push_container(['section2'])
    #
    def push_container(*tags)
      return unless perform_caching?
      @@container_stack ||= []
      tags = canonize_tags(tags)
      adapter.add_tags_containers(tags, @@container_stack)
      @@container_stack.push tags
    end
    
    # Public: remove tags of a container fragment from the current container stack
    #
    # cache_adapter - :cache_store / :redis_store
    #
    # Examples
    #
    #   Cashier.pop_container()
    #
    def pop_container()
      return unless perform_caching?
      @@container_stack ||= []
      container = @@container_stack.pop  
      container
    end

    # Public: get the tags of containers for the given fragment tags
    #
    # cache_adapter - :cache_store / :redis_store
    #
    # Examples
    #
    #   Cashier.get_containers(['article1'])
    #   # => ['section2', 'section3']
    #
    def get_containers(tags)
      tags = canonize_tags(tags)
      adapter.get_tags_containers(tags)
    end


    # Public: canonize tags: convert ActiveRecord objects to string (inc. id)
    #
    # cache_adapter - :cache_store / :redis_store
    #
    # Examples
    #
    #   Cashier.canonize_tags([1, :a, Article.find(123)])
    #   # => [1, :a, "Article-123"]
    #
    def canonize_tags(tags)
      tags = [tags || []].flatten
      tags.map do |tag| 
        if tag.is_a?(ActiveRecord::Base) 
          "#{tag.class.name}-#{tag.to_param}"
        else
          tag 
        end
      end
    end

  end

end

require 'rails'
require 'cashier/railtie'
require 'cashier/adapters/cache_store'
require 'cashier/adapters/redis_store'

# Connect cashier up to the low level Rails cache:

# When Rails cache is missing a fragment, it is going to be rendered - add its tags to the container stack
ActiveSupport::Notifications.subscribe("cache_read.active_support") do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload
  tag = payload[:tag]
  # if not a cache hit, we're going to build the fragment - add to container stack
  Cashier.push_container(*tag) if tag && !payload[:hit]
end

# When a fragment was written into Rails cache it is now rendered and done - remove its tags from the container stack
ActiveSupport::Notifications.subscribe("cache_write.active_support") do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload
  tag = payload[:tag]

  if tag
    Cashier.store_fragment(payload[:key], tag)
    Cashier.pop_container
  end
end

