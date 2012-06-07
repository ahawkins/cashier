module Cashier
  class Railtie < ::Rails::Railtie
    config.cashier = Cashier

    initializer "cashier.active_support.cache.instrumentation" do |app|
      ActiveSupport::Cache::Store.instrument = true

      ActiveSupport.on_load(:before_configuration) do
        require "cashier/application_controller"
      end
    end
  end
end
