require 'dalli'
require 'digest/md5'
require 'active_support/cache'

module ActiveSupport
  module Cache
    # A cache store implementation which stores data in Memcached:
    # http://www.memcached.org
    #
    # DalliStore implements the Strategy::LocalCache strategy which implements
    # an in memory cache inside of a block.
    class DalliStore < Store
      def fetch_with_tags(key, options)
        puts "Something fancy happened :: fetch"  
        fetch_without_tags(key, options)
      end

      alias_method_chain :fetch, :tags

      def write_with_tags(key, value, options)
        puts "Something fancy happened :: write"  
        write_without_tags(key, options)
      end

      alias_method_chain :write, :tags

      def delete_with_tags(key, options = nil)
        puts "Something fancy happened :: delete"  
        delete_without_tags(key, options)
      end

      alias_method_chain :delete, :tags
    end
  end
end