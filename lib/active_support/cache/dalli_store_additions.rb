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
      def write_with_tags(key, value, options = {})
        ActiveSupport::Notifications.instrument("cashier.write_cache_key", :data => key) do
          tags = (options.nil?) ? options : options.delete(:tag)
          Cashier.store_fragment(key, tags) if tags

          write_without_tags(key, value, options)
        end
      end
      alias_method_chain :write, :tags

      def delete_with_tags(key, options = nil)
        ActiveSupport::Notifications.instrument("cashier.delete_cache_key", :data => key) do
          delete_without_tags(key, options)  
        end
      end

      alias_method_chain :delete, :tags
    end
  end
end