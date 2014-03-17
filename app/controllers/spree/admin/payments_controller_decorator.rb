module Spree
  module Admin
    PaymentsController.class_eval do
      durably_decorate(:create, mode: 'strict', sha: 'b9a1a623d9c664e88e5bf795f22962c2e49fb7ca') do 
        @payment = @order.payments.build(object_params)

        if @payment.payment_method.is_a?(Spree::PaymentMethod::Voucher)
          voucher = Voucher.find_by_number @payment.source.number

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
              render :new and return
            end
          else
            flash[:error] = Spree.t(:no_voucher_exists_for_number, {number: @payment.source.number})
            render :new and return
          end
        elsif params[:card].present? and params[:card] != 'new'
          @payment.source = @payment.payment_method.payment_source_class.find_by_id(params[:card])
        end

        begin
          if @payment.save
            # Transition order as far as it will go.
            while @order.next; end
            @payment.process! if @order.completed?
            flash[:success] = flash_message_for(@payment, :successfully_created)
            redirect_to admin_order_payments_path(@order)
          else
            flash[:error] = Spree.t(:payment_could_not_be_created)
            render :new
          end
        rescue Spree::Core::GatewayError => e
          flash[:error] = "#{e.message}"
          redirect_to new_admin_order_payment_path(@order)
        end
      end

    end
  end
end
