module Cashier
  class Railtie < ::Rails::Railtie
    initializer "cashier.active_support.cache.instrumentation" do |app|
      ActiveSupport::Cache::Store.instrument = true
    end
  end
end
