module Spree
  PaymentMethod.class_eval do
    def voucher? 
      self.class == Spree::PaymentMethod::Voucher
    end
  end
end
