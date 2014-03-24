module Spree
  module ShipmentHandler
    class Voucher < Spree::ShipmentHandler
      def perform
        @shipment.line_items.each do |line_item|
          next unless line_item.voucher?

          line_item.quantity.times do |x|
            Spree::Voucher.create!(original_amount: line_item.voucher_original_amount, 
                                   expiration: line_item.voucher_expiration, 
                                   line_item_id: line_item.id)
          end
        end

        super
      end
    end
  end
end
