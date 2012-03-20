# Cashier: Tag Based Caching for Rails

Manage your cache keys with tags, forget about keys!

## What Is It?

```ruby
# in your view
cache @some_record, :tag => 'some-component'

# in another view
cache @some_releated_record, :tag => 'some-component'

# can have multiple tags
cache @something, :tag => ['dashboard', 'settings'] # can expire from either tag

# in an observer
Cashier.expire 'some-component' # don't worry about keys! Much easier to sweep with confidence

# in your controller
caches_action :tag => 'complicated-action', :cache_path => proc { |c| 
  # huge complicated mess of parameters
  c.params
}

# need to access the controller?
caches_action :tag => proc {|c|
  # c is the controller
  "users/#{c.current_user.id}/dashboard"      
}

# in your sweeper, in your observers, in your Resque jobs...wherever
Cashier.expire 'complicated-action'
Cashier.expire 'tag1', 'tag2', 'tag3', 'tag4'

# It integrates smoothly with Rails.cache as well, not just the views
Rails.cache.fetch("user_1", :tag => ["users"]) { User.find(1) }
Rails.cache.fetch("user_2", :tag => ["users"]) { User.find(2) }
Rails.cache.fetch("user_3", :tag => ["users"]) { User.find(3) }
Rails.cache.fetch("admins", :tag => ["users"]) { User.where(role: "Admin").all }

# You can then expire all your users 
Cashier.expire "users"

# You can also use Rails.cache.write
Rails.cache.write("foo", "bar", :tag => ["some_tag"])

# what's cached
Cashier.tags

# sweep all stored keys
Cashier.clear
```

## How it Came About

I work on an application that involves all sorts of caching. I try to use action caching whenever I possible.
I had an index action that had maybe ~20 different combination of filters and sorting. If you want to use
action caching you have to create a **unique** key for every combination. This created a nice 6 nested loop
to expire the cache. Once you had pagination, then you have even more combinations of possible cache keys.
I needed a better solution. I wanted to expire things logically as a viewed them on the page. IE, if 
a record was added, I wanted to say "expire that page". Problem was that page contained ~1000 different keys.
So I needed something to store the keys for me and associate them with tags. That's exactly what cashier does.
Cache associate individual cache keys with a tag, then expire them all at once. This took my 7 layer loop
down to one line of code. It's also made managing the cache throught my application much easier.

## Why Tag Based Caching is Useful

1. You don't worry about keys. How many times have you created a complicated key for a fragment or action
then messed up when you tried to expire the cache
2. Associate your cached content into groups of related content. If you have records that are closely associated
or displayed together, then you can tag them and expire them at once.
3. **Expire cached content from anywhere.** If you've done any serious development, you know that Rails caching
does not work (easily) outside the scope of an HTTP request. If you have background jobs that manipulate data
or potentially invalidate cached data, you know how much of a pain it is to say `expire_fragment` in some random code.
4. Don't do anything differently! All you have to do is pass `:tag => 'something'` into `cache` (in the view) or `caches_action` 
in the controller.

## How it Works

Cashier hooks into Rails' `store_fragment` method using `alias_method_chain` to run some code that captures the key
and tag then stores that in the rails cache. 

### Adapters

Cashier has 2 adapters for the tags storing, `:cache_store` or `:redis_store`.

**IMPORTANT**: this store is ONLY for the tags, your fragments will still be stored in `Rails.cache`.

#### Setting an adapter for working with the cache as the tags storage

`config/initializers/cashier.rb`

```ruby
Cachier.adapter = :cache_store
```

#### Setting an adapter for working with Redis as the tags storage

`config/initializers/cashier.rb`

```ruby
Cashier.adapter = :redis_store
Cashier.adapter.redis = Redis.new(:host => '127.0.0.1', :port => '3697')
```

### Why Redis?

The reason Redis was introduced is that while the Rails.cache usage 
for the tags store is clean and involves no "outer" dependencies, 
since memcached is limited to read/write, it can slow down the application quite a bit.

If you work with very large arrays of keys and tags, you may see slowness in the cache communication.

Redis was introduces since it has the ability to work with "sets", and 
you can add/remove tags from this set without reading the entire array.


### Benchmarking

Using the cache adapter, this piece of code takes 3 seconds on average

```ruby
Benchmark.measure do
  500.times do
    key = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
    tag = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
    tag2 = (0...50).map{ ('a'..'z').to_a[rand(26)] }.join
    Cashier.store_fragment(key, tag, tag2)
  end
end
```

Using the Redis adapter, the same piece of code takes 0.8 seconds, quite the difference :)

## Testing

Use can use cashier to test caching as well. First things first:

```ruby
# test.rb

config.application_controller.perform_caching = true
```

I've also included some Rspec Matchers and a cucumber helper for testing
caching. The rspec matchers can be used like this:

```ruby
describe "get index" do
  include Cashier::Matchers

  it "should cache the action" do
    get :index
    'some-tag'.should be_cached
  end
end
```

Testing w/cucumber is more involved.

```ruby
# features/support/cashier.rb
require 'cashier/cucumber'
```

is an example of a possible step

```ruby
Then /the dashboard should be cached/ do
  "dashboard".should be_cached
end
```
Including `cashier/cucumber` will also wipe the cache before every
scenario.

## Contributors

* [adman65](http://twitter.com/adman65) - Initial Implementation
* [KensoDev](http://twitter.com/kensodev) - Adding Redis support (Again \o/)

## Contributing to Cashier
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2010 Adam Hawkins. See LICENSE.txt for
further details.
