source 'https://rubygems.org'

group :development, :test do
  gem 'pry'

  # gem 'spree', github: 'spree/spree', branch: '2-2-stable'
  surfd_branch = '2-4-stable-sd'

  gem 'spree_api',               github: 'surfdome/spree',                  branch: surfd_branch
  gem 'spree_backend',           github: 'surfdome/spree',                  branch: surfd_branch
  gem 'spree_core',              github: 'surfdome/spree',                  branch: surfd_branch
  gem 'spree_frontend',          github: 'surfdome/spree',                  branch: surfd_branch
  gem 'spree_sample',            github: 'surfdome/spree',                  branch: surfd_branch

  # Provides basic authentication functionality for testing parts of your engine
  gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: '2-4-stable'

# not even sure we need this gem any longer
#  gem 'spree_product_customizations', github: 'jsqu99/spree_product_customizations'
#  gem 'spree_product_customizations', path: '../product_customizations'
end

gemspec
