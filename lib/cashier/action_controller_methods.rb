module Cashier
  module ActionControllerMethods
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
