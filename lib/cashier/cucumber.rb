World(Cashier::Matchers)

Before('@caching') do
  Cashier.clear
  Rails.cache.clear
end
