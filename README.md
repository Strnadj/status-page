# status-page

[![Gem Version](https://badge.fury.io/rb/status-page.svg)](http://badge.fury.io/rb/status-page) [![Build Status](https://travis-ci.org/rails-engine/status-page.svg)](https://travis-ci.org/rails-engine/status-page) [![Dependency Status](https://gemnasium.com/rails-engine/status-page.svg)](https://gemnasium.com/rails-engine/status-page) [![Coverage Status](https://coveralls.io/repos/rails-engine/status-page/badge.svg)](https://coveralls.io/r/rails-engine/status-page)

This is a health monitoring Rails mountable plug-in, which checks various services (db, cache, sidekiq, redis, etc.).

Mounting this gem will add a '/check' route to your application, which can be used for health monitoring the application and its various services. The method will return an appropriate HTTP status as well as a JSON array representing the state of each provider.

## Setup

If you are using bundler add status-page to your Gemfile:

```ruby
gem 'status-page'
```

Then run:

```bash
$ bundle install
```

Otherwise install the gem:

```bash
$ gem install status-page
```

## Usage
You can mount this inside your app routes by adding this to config/routes.rb:

```ruby
mount StatusPage::Engine, at: '/'
```

## Supported service providers
The following services are currently supported:
* DB
* Cache
* Redis
* Sidekiq
* Resque

## Configuration

### Adding providers
By default, only the database check is enabled. You can add more service providers by explicitly enabling them via an initializer:

```ruby
StatusPage.configure do |config|
  config.cache
  config.redis
  config.sidekiq
end
```

### Providers configuration

Some of the providers can also accept additional configuration:

```ruby
StatusPage.configure do |config|
  config.sidekiq.configure do |sidekiq_config|
    sidekiq_config.latency = 3.hours
  end
end
```

The currently supported settings are:

#### Sidekiq

* `latency`: the latency (in seconds) of a queue (now - when the oldest job was enqueued) which is considered unhealthy (the default is 30 seconds, but larger processing queue should have a larger latency value).

### Adding a custom provider
It's also possible to add custom health check providers suited for your needs (of course, it's highly appreciated and encouraged if you'd contribute useful providers to the project).

In order to add a custom provider, you'd need to:

* Implement the `StatusPage::Providers::Base` class and its `check!` method (a check is considered as failed if it raises an exception):

```ruby
class CustomProvider < StatusPage::Providers::Base
  def check!
    raise 'Oh oh!'
  end
end
```
* Add its class to the configuration:

```ruby
StatusPage.configure do |config|
  config.add_custom_provider(CustomProvider)
end
```

### Adding a custom error callback
If you need to perform any additional error handling (for example, for additional error reporting), you can configure a custom error callback:

```ruby
StatusPage.configure do |config|
  config.error_callback = proc do |e|
    logger.error "Health check failed with: #{e.message}"

    Raven.capture_exception(e)
  end
end
```

### Adding authentication credentials
By default, the `/check` endpoint is not authenticated and is available to any user. You can authenticate using HTTP Basic Auth by providing authentication credentials:

```ruby
StatusPage.configure do |config|
  config.basic_auth_credentials = {
    username: 'SECRET_NAME',
    password: 'Shhhhh!!!'
  }
end
```

### Adding environmet variables
By default, environmet variables is nil, you need to provide a Hash with your custom environmet variables:

```ruby
StatusPage.configure do |config|
  config.environmet_variables = {
    build_number: 'BUILD_NUMBER',
    git_sha: 'GIT_SHA'
  }
end
```

## License

The MIT License (MIT)

Copyright (c) 2014

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
