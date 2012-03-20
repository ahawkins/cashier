# Hooks into ApplicationController's write_fragment method.
# write_fragment is used for action and fragment caching.
# Create an alias method chain to call our customer method
# which stores the associated key with the tag in a 
# Redis Set. Then we can expire all those keys from anywhere
# in the code using Rails.cache.delete
#
# I use alias_method_chain instead of calling 'super'
# because there is a very rare case where someone 
# may have redfined 'write_fragment' in their own 
# controllers. Using an alias method chain
# keeps those methods intact.

class ApplicationController < ActionController::Base
  def write_fragment_with_tagged_key(key, content, options = nil)
    tag_option = options.delete(:tag)
    tags = case tag_option.class.to_s
             when 'Proc', 'Lambda'
               tag_option.call(self)
             else 
               tag_option
             end

    options = options.merge({:tag => tags}) if tags
    write_fragment_without_tagged_key(key, content, options)
  end
  alias_method_chain :write_fragment, :tagged_key
end