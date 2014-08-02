module Spree
  LineItem.class_eval do
    has_many :vouchers # one per quantity

    # the line_item.variant is the 'voucher product'
    # here we'll customize the product
    def build_vouchers(options)
      return unless options 

      self.vouchers.build(options)
    end
  end
end
