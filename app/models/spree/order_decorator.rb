module Spree
  Order.class_eval do
    def available_payment_methods
      @available_payment_methods ||= 
        ((PaymentMethod.available(:front_end) + PaymentMethod.available(:both)).uniq).reject { |pm| pm.class == Spree::PaymentMethod::Voucher }
    end

    def display_voucher_total
      Spree::Money.new(voucher_total, { currency: currency })
    end

    def display_total_minus_pending_vouchers
      Spree::Money.new(total_minus_pending_vouchers, { currency: currency })
    end

    def voucher_total
      (self.payments.select { |p| p.voucher? && p.pending? }.map(&:amount)).sum
    end

    def total_minus_pending_vouchers
      total - voucher_total
    end

    private
      # TODO - CODE REVIEW - i'm having trouble w/ this durable decorator.  the sha keeps bouncing back and forth.  then it doesn't take effect
      # need to handle zero params coming in when no amount due (due to voucher application)
      # durably_decorate :update_params_payment_source, mode: 'strict', sha: '78a50dd51923401e19c959485ad1fce2d85d3456' do
  
      def update_params_payment_source
        # respond_to check is necessary due to issue described in #2910
        if has_checkout_step?("payment") && self.payment?
          if @updating_params[:payment_source].present?
            if @updating_params[:order][:payments_attributes]
              source_params = @updating_params.delete(:payment_source)[@updating_params[:order][:payments_attributes].first[:payment_method_id].underscore]
  
              if source_params
                @updating_params[:order][:payments_attributes].first[:source_attributes] = source_params
              end
            end
          end
  
          if (@updating_params[:order][:payments_attributes])
            @updating_params[:order][:payments_attributes].first[:amount] = self.total
          end
        end
      end
    end
end
