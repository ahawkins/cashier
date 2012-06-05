class ApplicationController < ActionController::Base
  def read_fragment(path, options)
    super(path, options.clone)
  end

  def write_fragment(key, content, options = {})
    options = options.clone
    tag_option = options.delete(:tag)
    tags = tag_option.is_a?(Proc) ? tag_option.call(self) : tag_option

    options = options.merge({ :tag => tags }) if tags
    ActiveSupport::Cache::Store.instrument = true
    super(key, content, options)
  end
end