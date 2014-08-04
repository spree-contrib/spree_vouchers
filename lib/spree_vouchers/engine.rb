module SpreeVouchers
  class Engine < Rails::Engine
    require 'spree/core'
    isolate_namespace Spree
    engine_name 'spree_vouchers'

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end

      Spree::Order.register_line_item_comparison_hook(:vouchers_match) if Spree::Order.table_exists?
    end

    initializer "spree_vouchers.register.payment_methods" do |app|
      app.config.spree.payment_methods += [Spree::PaymentMethod::Voucher]
    end

    config.to_prepare &method(:activate).to_proc
  end
end
