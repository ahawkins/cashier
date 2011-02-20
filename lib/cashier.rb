# Cashier

module Cashier
  extend self

  CACHE_KEY = 'cashier-tags'

  def perform_caching?
    ::ApplicationController.perform_caching
  end

  def store_fragment(fragment, *tags)
    return unless perform_caching?

    tags.each do |tag|
      # store the fragment
      fragments = Rails.cache.fetch(tag) || []
      Rails.cache.write(tag, fragments + [fragment])
    end

    # now store the tag for book keeping
    cashier_tags = Rails.cache.fetch(CACHE_KEY) || []
    cashier_tags = (cashier_tags + tags).uniq
    Rails.cache.write(CACHE_KEY, cashier_tags)
  end

  def expire(*tags)
    return unless perform_caching?

    # delete them from the cache
    tags.each do |tag|
      if fragment_keys = Rails.cache.fetch(tag)
        fragment_keys.each do |fragment_key|
          Rails.cache.delete(fragment_key)
        end
      end
      Rails.cache.delete(tag)
    end

    # now remove them from the list
    # of stored tags
    cashier_tags = Rails.cache.fetch(CACHE_KEY) || []
    cashier_tags = (cashier_tags - tags).uniq
    Rails.cache.write(CACHE_KEY, cashier_tags)
  end

  def tags
    Rails.cache.fetch(CACHE_KEY) || []
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

require 'cashier/controller_helper'
require 'cashier/matchers'

if defined?(::Rails)
  if Rails::VERSION::MAJOR == 3
    require 'cashier/railtie'
  end
end
