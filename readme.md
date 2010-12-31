# Cashier: Tag Based Caching for Rails

Manage your cache keys with tags, forget about keys!

## What Is It?

    # in your view
    cache @some_record, :tag => 'some-component'
    
    # in another view
    cache @some_releated_record, :tag => 'some-component'

    # in your sweeper
    Cashier.expire 'some-component' # don't worry about keys! Much easier to sweep with confidence

    # in your controller
    caches_action :tag => 'complicated-action', :cache_path => proc { |c| 
      # huge complicated mess of parameters
      c.params
    }

    # in your sweeper, in your observers, in your resque jobs...wherever
    Cashier.expire 'complicated-action'

## How it Came About

I work on an application that involves all sorts of caching. I try to use action caching whenever I possible.
I had an index action that had maybe ~20 different combination of filters and sorting. If you want to use
action caching you have to create a **unique** key for every combination. This created a nice 6 nested loop
to expire the cache. Once you had pagination, then you have even more combinations of possible cache keys.
I needed a better solution. I wanted to expire things logically as a viewed them on the page. IE, if 
a record was added, I wanted to say "expire that page". Problem was that page contained ~1000 different keys.
So I needed something to store the keys for me and associate them with tags. That's exactly what cashier does.
Cache associate individual cache keys with a tag, then expire them all at once. This took my 7 layer loop
down two one line of code. It's also made managing the cache throught my application much easier.

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

Cashier hooks into Rails' `expire_fragment` method using `alias_method_chain` to run some code that captures they key
and tag then stores that as a set in redis. Then uses the set members to loop over keys to deleting using `Rails.cache.delete`

## Configuration

Cashier needs Redis to function correctly. Create a yaml file. You may call it `config/cashier.yml`

    development: localhost:6379
    test: localhost:6379/test

Then write a simple initializer to configure Cahiser. Drop this file in in `config/initializers/cashier.rb`

    rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
    rails_env = ENV['RAILS_ENV'] || 'development'

    resque_config = YAML.load_file(rails_root + '/config/cashier.yml')
    Cashier.redis = resque_config[rails_env]

Now in your `application_controller.rb` file just include these lines:

    require 'cashier'

    class ApplicationController < ActionController::Base
      include Cashier::ControllerHelper
    end

Now you're good to go!

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

