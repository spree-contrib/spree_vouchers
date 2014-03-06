module Spree
  class PaymentMethod::Voucher < PaymentMethod
    delegate :authorize, :purchase, :capture, :void, :credit, to: :provider

    def payment_source_class
      ::Spree::Voucher
    end

    def provider
      @provider ||= self
    end

    def method_missing(method, *args)
      if @provider.nil? || !@provider.respond_to?(method)
        super
      else
        provider.send(method, *args)
      end
    end

    def actions
      %w{authorize capture void credit}
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      ['checkout', 'pending'].include?(payment.state)
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      payment.state != 'void'
    end

    def authorize(amount_in_cents, source, gateway_options = {})
      # a voucher is authorized if: it exists, is not expired, and has a postive balance
      # Voucher.where("balance > 0").where("date <= ?", Time.now).exists?
      voucher = Voucher.where(number: source.number).first

      if voucher.nil?
        ActiveMerchant::Billing::Response.new(false, "Could not find voucher: #{source.number}", {}, {})
      else
        action = ->(voucher) {
          voucher.authorize(amount_in_cents / 100, gateway_options[:currency])
        }
        handle_action_call(voucher, action, :authorize)
      end
    end

    def capture(amount_in_cents, auth_code, gateway_options)
      action = ->(voucher) {
        voucher.capture(amount_in_cents / 100, auth_code, gateway_options[:currency])
      }

      handle_action(action,:capture, auth_code)
    end

    def void(auth_code, *ignored_options)

      action = ->(voucher) {
        voucher.void(auth_code)
      }

      handle_action(action,:void, auth_code)
    end


    def credit(amount_in_cents, auth_code, gateway_options)
      action = ->(voucher) {
        voucher.credit(amount_in_cents / 100, auth_code, gateway_options[:currency])
      }

      handle_action(action,:credit, auth_code)
    end


    def source_required?
      true
    end

    private
      def find_voucher_for_authorization_code(auth_code)
        # work around the 'readonlyrecord' problem by using 'select' 
        # per http://stackoverflow.com/questions/639171/what-is-causing-this-activerecordreadonlyrecord-error
        Voucher.select('distinct spree_vouchers.*').
          joins(:voucher_events).
          where('spree_voucher_events.authorization_code = ?', auth_code).
          first rescue nil
      end

      def handle_action_call(voucher, action, action_name, auth_code=nil)
        if response = action.call(voucher)
          # note that we only need to return the auth code on an 'auth', but it's innocuous to always return
          ActiveMerchant::Billing::Response.new(true, 
                                                "Successful voucher #{action_name}: #{voucher.number}/#{auth_code || response}", 
                                                {},  {authorization: auth_code || response})
        else
          ActiveMerchant::Billing::Response.new(false, voucher.errors.full_messages.join, {}, {})
        end
      end

      def handle_action(action, action_name, auth_code)
        voucher = find_voucher_for_authorization_code(auth_code)

        if voucher.nil?
          ActiveMerchant::Billing::Response.new(false, "Could not find voucher having code: #{auth_code} for action #{action_name}", {}, {})
        else
          handle_action_call(voucher, action, action_name, auth_code)
        end
      end
  end
end
