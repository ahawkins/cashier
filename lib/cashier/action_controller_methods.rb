module Cashier
  module ActionControllerMethods
    def self.included(base)
      base.extend ClassMethods
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      def cashiered_page(path, extension, tags)
        return unless perform_caching
        Cashier.store_page_path(path, tags)
      end

      def cashier_pages(*actions)
        return unless perform_caching
        options = actions.extract_options!

        tags = options.delete(:tag)

        after_filter({:only => actions}.merge(options)) do |c|
          c.cashier_page(tags)
        end
      end
    end

    module InstanceMethods
      def cashier_page(tags)
        return unless self.class.perform_caching && caching_allowed?

        path = request.path

        if (type = Mime::LOOKUP[self.content_type]) && (type_symbol = type.symbol).present?
          extension = ".#{type_symbol}"
        end

        new_tags = tags.is_a?(Proc) ? tags.call(self) : tags

        self.class.cashiered_page(path, extension, new_tags)
      end

      def read_fragment(path, options)
        options ? super(path, options.clone) : super(path, options)
      end

      def write_fragment(key, content, options = { })
        if options
          options = options.clone
          tag_option = options.delete(:tag)
          tags = tag_option.is_a?(Proc) ? tag_option.call(self) : tag_option

          options = options.merge({ :tag => tags }) if tags
          ActiveSupport::Cache::Store.instrument = true
        end
        super(key, content, options)
      end
    end
  end
end
