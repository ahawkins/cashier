module Cashier
  module Addons
    class Plugins
        def self.call_plugin_method(method_name, *args)
          plugins.each do |plugin|
            begin
              plugin.send(method_name, args) if plugin.respond_to?(method_name)  
            rescue Exception => e
              
            end
          end
        end

        # Public: Add plugin klass to the plugins array.
        #
        # plugin_klass - the plugin klass which defines all/some of the callback methods.
        #
        # Examples
        #
        #   Cashier.add_plugin(CashierCotendo)
        #
        def self.add_plugin(plugin_klass)
          plugins << plugin_klass
        end

        # Public: plugins array.
        #
        # Examples
        #
        #   Cashier.plugins
        #   # => [CashierCotendo, SomeOtherPlugin]
        #
        def self.plugins
          @@plugins ||= []
          @@plugins
        end
    end
  end
end