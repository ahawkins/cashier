module Cashier
  module Adapters
    class CacheStore
      def self.store_fragment_in_tag(fragment, tag)
        fragments = Rails.cache.fetch(tag) || []
        new_fragments = fragments + [fragment]
        Rails.cache.write(tag, new_fragments)
      end

      def self.store_path_in_tag(page_path, tag)
        tag = page_path_tag(tag)
        page_paths = Rails.cache.fetch(tag) || []
        new_page_paths = page_paths + [page_path]
        Rails.cache.write(tag, new_page_paths)
      end

      def self.store_tags(tags)
        cashier_tags = Rails.cache.fetch(Cashier::CACHE_KEY) || []
        cashier_tags = (cashier_tags + tags).uniq

        Rails.cache.write(Cashier::CACHE_KEY, cashier_tags)
      end

      def self.store_page_tags(tags)
        cashier_tags = Rails.cache.fetch(Cashier::CACHE_KEY) || []
        cashier_tags = (cashier_tags + tags.map {|t| "page-path:" + t}).uniq

        Rails.cache.write(Cashier::CACHE_KEY, cashier_tags)
      end

      def self.remove_tags(tags)
        cashier_tags = Rails.cache.fetch(Cashier::CACHE_KEY) || []
        cashier_tags = (cashier_tags - tags).uniq
        Rails.cache.write(Cashier::CACHE_KEY, cashier_tags)
      end

      def self.remove_page_tags(tags)
        cashier_tags = Rails.cache.fetch(Cashier::CACHE_KEY) || []
        cashier_tags = (cashier_tags - tags.map {|t| "page-path:" + t}).uniq
        Rails.cache.write(Cashier::CACHE_KEY, cashier_tags)
      end

      def self.tags
        Rails.cache.read(Cashier::CACHE_KEY) || []
      end

      def self.get_fragments_for_tag(tag)
        Rails.cache.read(tag) || []
      end

      def self.get_page_paths_for_tag(tag)
        Rails.cache.read(page_path_tag(tag)) || []
      end

      def self.delete_tag(tag)
        Rails.cache.delete(tag)
      end

      def self.delete_path_tag(tag)
        Rails.cache.delete(page_path_tag(tag))
      end

      def self.clear
        remove_tags(tags)
        Rails.cache.delete(Cashier::CACHE_KEY)
      end

      def self.keys
        tags.inject([]) { |arry, tag| arry += Rails.cache.fetch(tag) }.compact
      end

      private

      def self.page_path_tag(tag)
        "page-path:" + tag
      end
    end
  end
end
