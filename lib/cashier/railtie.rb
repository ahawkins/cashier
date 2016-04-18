module Cashier
  class Railtie < ::Rails::Railtie
    config.cashier = Cashier

    initializer "cashier.active_support.cache.instrumentation" do |app|
      ActiveSupport.on_load(:action_controller) do
        require "cashier/action_controller_methods"

        ::ActionController::Base.send(:include, Cashier::ActionControllerMethods)
      end
    end
  end
end
