World(Cashier::Matchers)

Before('@caching') do
  Rails.cache.clear
  Cashier.clear
end
