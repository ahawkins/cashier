# Cashier: Tag Based Caching for Rails

[![Build Status](https://secure.travis-ci.org/twinturbo/cashier.png?branch=master)][travis]
[![Gem Version](https://badge.fury.io/rb/cashier.png)][gem]
[![Code Climate](https://codeclimate.com/github/twinturbo/cashier.png)][codeclimate]
[![Dependency Status](https://gemnasium.com/twinturbo/cashier.png?travis)][gemnasium]

[gem]: https://rubygems.org/gems/cashier
[travis]: http://travis-ci.org/twinturbo/cashier
[gemnasium]: https://gemnasium.com/twinturbo/cashier
[codeclimate]: https://codeclimate.com/github/twinturbo/cashier

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

caches_page :index
cachier_pages :index, :tag => 'complicated-page'

# need to access the controller?
caches_action :tag => proc {|c|
  # c is the controller
  "users/#{c.current_user.id}/dashboard"
}

# in your sweeper, in your observers, in your Resque jobs...wherever
Cashier.expire 'complicated-action'
Cashier.expire 'complicated-page'
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

# Clears out all tagged keys and tags
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

It can also hook into page caching by storing the page path that's
cached and passing that to [MaidService](https://github.com/ScotterC/maidservice) to clear.  (redis only)

### Adapters

Cashier has 2 adapters for the tags storing, `:cache_store` or `:redis_store`.

**IMPORTANT**: this store is ONLY for the tags, your fragments will still be stored in `Rails.cache`.

#### Setting an adapter for working with the cache as the tags storage

```ruby
# config/environment/production.rb

config.cashier.adapter = :cache_store
# or config.cashier.adapter = :redis_store
```

#### Setting an adapter for working with Redis as the tags storage


```ruby
# config/environment/production.rb
config.cashier.adapter.redis = Redis.new(:host => '127.0.0.1', :port => '3697') # or Resque.redis or any existing redis connection
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


### Notifications

Cashier will send out events when things happen inside the library.
The events are sent out through `ActiveSupport::Notifications` so you can pretty much subscribe to the events from anywhere you want.

Here are the way you can subscribe to the events and use the data from them.

```ruby
# Subscribe to the store fragment event, this is fired every time cashier will call the "store_fragment" method
# payload[:data] will be something like this: ["key", ["tag1", "tag2", "tag3"]]
ActiveSupport::Notifications.subscribe("store_fragment.cashier") do |name, start, finish, id, payload|

end

# Subscribe to the store page path event
# this event will fire every time there's a page written with the key
# payload[:data] will be the page path that's been written to the cache
ActiveSupport::Notifications.subscribe("store_page_path.cashier") do |name, start, finish, id, payload|

end

# Subscribe to the expire event.
# payload[:data] will be the list of tags expired.
ActiveSupport::Notifications.subscribe("expire.cashier") do |name, start, finish, id, payload|

end

# Subscribe to the clear event. (no data)
ActiveSupport::Notifications.subscribe("clear.cashier") do |name, start, finish, id, payload|

end

# Subscribe to the delete_cache_key event
# this event will fire every time there's a Rails.cache.delete with the key
# payload[:data] will be the key name that's been deleted from the cache
ActiveSupport::Notifications.subscribe("delete_cache_key.cashier") do |name, start, finish, id, payload|

end

# Subscribe to the o_write_cache_key event
# this event will fire every time there's a Rails.cache.write with the key
# payload[:data] will be the key name that's been written to the cache
ActiveSupport::Notifications.subscribe("write_cache_key.cashier") do |name, start, finish, id, payload|

end
```

### Notifications use case
At [Gogobot](http://www.gogobot.com) we have a plugin to invalidate the external CDN cache on full pages for logged out users.
The usage is pretty unlimited.

If you think we're missing a notification, please do open an issue or be awesome and do it yourself and open a pull request.

## Contributors

* [twinturbo](http://twitter.com/adman65) - Initial Implementation
* [KensoDev](http://twitter.com/kensodev) - Adding Redis support (Again \o/)
* [KensoDev](http://twitter.com/kensodev) - Adding plugins support for callback methods
* [ScotterC](http://twitter.com/scotterc) - Adding page caching support


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
