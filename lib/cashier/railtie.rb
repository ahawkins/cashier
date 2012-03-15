module Cashier
  class Railtie < Rails::Railtie
    initializer 'cashier.initialize' do
      ActiveSupport.on_load(:action_controller) do
        require 'cashier/application_controller'
      end
    end
  end
end