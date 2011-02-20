module Cashier
  class Railtie < Rails::Railtie
    initializer 'cashier.initialize' do
      ApplicationController.send :include, Cashier::ControllerHelper
    end
  end
end

