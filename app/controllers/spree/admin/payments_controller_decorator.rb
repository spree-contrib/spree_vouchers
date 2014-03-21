module Spree
  module Admin
    PaymentsController.class_eval do

      before_action :handle_voucher_create, :only => :create

      def handle_voucher_create
        @payment = @order.payments.build(object_params)
        if @payment.payment_method.is_a?(Spree::PaymentMethod::Voucher)

          voucher = Voucher.find_by_number object_params[:source_attributes][:number]

          if voucher
            amount = [params[:payment][:amount].to_f, voucher.authorizable_amount, 
                      @order.outstanding_balance - @order.voucher_total].min

            # we don't actually want to authorize until the order is completed,
            # so do a 'pretend' auth to get the approve/reject as well as the new totals
            if amount > 0 && voucher.soft_authorize(amount, @order.currency)
              @payment.source = voucher
              @payment.amount = amount
            else
              flash[:error] = Spree.t(:unable_to_apply_voucher_with_remaining_balance, {
                                        available: Spree::Money.new((voucher.authorizable_amount),
                                                                    { currency: @order.currency }),
                                        expiration: voucher.expiration || Spree.t('no_voucher_expiration_applicable'),
                                        currency: voucher.currency})
              redirect_to spree.admin_order_payments_path(@order) and return false
            end
          else
            flash[:error] = Spree.t(:no_voucher_exists_for_number, {number: object_params[:source_attributes][:number]})
            redirect_to spree.admin_order_payments_path(@order) and return false
          end

        end
      end
    end
  end
end
