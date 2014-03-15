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
      (self.payments.select { |p| p.voucher? && (p.pending? || p.checkout?)}.map(&:amount)).sum
    end

    def total_minus_pending_vouchers
      total - voucher_total
    end

    # let's always force a confirmation if any of our payment methods support it.
    # vouchers don't meet the 'payment profiles' criteria and I don't want to add that hack
    # into them just for the confirmation step
    durably_decorate :confirmation_required?, mode: 'soft', sha: '63e6ea9a16bfd8f2ce715265a761d5d4ed9a48dc' do
      Spree::Config[:always_include_confirm_step] ||
        available_payment_methods.any?(&:payment_profiles_supported?) ||
        
        # Little hacky fix for #4117
        # If this wasn't here, order would transition to address state on confirm failure
        # because there would be no valid payments any more.
        state == 'confirm'
    end

    # ok genius, YOU figure out why I get a 'no pending payments' during the execution of
    # checkout_payments_spec:"Voucher Redemption":"paying solely by voucher":it "allows completion without entering other payment"
    # and I'll remove this line...which is only here to make the test pass...which makes me sick
    durably_decorate :pending_payments, mode: 'soft', sha: '221b0bab98b0dcde509ba39048c34da57d88cfba' do
      payments.reload.select { |payment| payment.checkout? || payment.pending? }
    end

    private
      # TODO - CODE REVIEW - i'm having trouble w/ this durable decorator.  the sha keeps bouncing back and forth.  then it doesn't take effect
      # need to handle zero params coming in when no amount due (due to voucher application)
      # durably_decorate :update_params_payment_source, mode: 'soft', sha: '78a50dd51923401e19c959485ad1fce2d85d3456' do
  
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
