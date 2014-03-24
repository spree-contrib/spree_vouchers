module Spree
  LineItem.class_eval do
    has_many :vouchers # one per quantity

    def voucher_original_amount
      # vouchers.first.original_amount # all vouchers _must_ have this same value if they came from the same line item
      # TODO: this is where possibly flexi-variants comes in to play
      return 100
    end

    def voucher_expiration
      # vouchers.first.expiration # all vouchers _must_ have this same value if they came from the same line item

      # TODO: this is where possibly flexi-variants comes in to play
      return 1.year.from_now
    end
  end
end
