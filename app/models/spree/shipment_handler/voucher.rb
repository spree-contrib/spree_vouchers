module Spree
  module ShipmentHandler
    class Voucher < Spree::ShipmentHandler
      def perform
# CODE_REVIEW: pros/cons of using this vs. the standard shipment email.  We certainly don't want both
=begin        
        @shipment.line_items.each do |line_item|
          next unless line_item.voucher?

          line_item.vouchers.each do |voucher|
            if voucher.delivery_method == 'email'
              VoucherMailer.voucher_email(voucher).deliver
            end
          end
        end
=end
        super
      end
    end
  end
end
