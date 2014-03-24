SpreeVouchers
=============

[ ![Codeship Status for spree-contrib/spree_vouchers](https://www.codeship.io/projects/592544d0-9592-0131-ced3-1619ce81f0d2/status?branch=master)](https://www.codeship.io/projects/592544d0-9592-0131-ced3-1619ce81f0d2)



Spree Vouchers implemented as 1st-class payment method

Installation
------------

Add spree_vouchers to your Gemfile:

```ruby
gem 'spree_vouchers'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_vouchers:install
```

To create some sample vouchers:

```shell
bundle exec rake spree_vouchers:load_sample
```

This creates four vouchers (with the following numbers:

VALID
EXPIRED
FULLY_AUTHED
EXHAUSTED

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_vouchers/factories'
```

Copyright (c) 2014 [name of extension creator], released under the New BSD License
