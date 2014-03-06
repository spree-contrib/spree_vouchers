module Spree
  CheckoutController.class_eval do
    respond_to :html, :js

    
    def apply_voucher
      @order = Order.find params[:voucher_order_id]
      voucher = Voucher.find_by_number params[:voucher_number]

      if voucher
        voucher_payment_method = Spree::PaymentMethod.available.detect { |pm| 
          pm.class == Spree::PaymentMethod::Voucher 
        }
        @payment = @order.payments.build(source: voucher,
                                         payment_method: voucher_payment_method,
                                         amount: [voucher.remaining_amount - voucher.authorized_amount, 
                                                  @order.outstanding_balance - @order.voucher_total].min)
        @payment.process!

        voucher.reload

        # unfortunately I can't use the wonderful ActiveMerchant::Billing::Response messages 
        # I carefully crafted as they are dumped before calling payment.failure
        if @payment.failed?
          flash[:error] = Spree.t(:unable_to_apply_voucher_with_remaining_balance, {
                                   available: Spree::Money.new((voucher.remaining_amount - voucher.authorized_amount),
                                                               { currency: @order.currency })})
        else
          @no_more_payment_required = @order.total_minus_pending_vouchers <= 0
            
          flash[:notice] = Spree.t(:voucher_applied_for_amount_with_remaining_balance, 
                                 {
                                   payment_amount: Spree::Money.new(@payment.amount, { currency: @order.currency }),
                                   available: Spree::Money.new((voucher.remaining_amount - voucher.authorized_amount),{ currency: @order.currency })
                                 })
        end
      else
        flash[:error] = Spree.t(:no_voucher_exists_for_number, number: params[:voucher_number])
      end

      respond_with(@order)
    end
  end
end
