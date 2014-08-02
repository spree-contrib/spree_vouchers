module Spree
  class Voucher < ActiveRecord::Base
    has_many :payments, as: :source
    has_many :voucher_events
    belongs_to :address
    belongs_to :line_item
    before_validation(on: :create) { self.remaining_amount = original_amount }
    before_validation :generate_voucher_number, on: :create

    validates :number, :original_amount, :currency, presence: true
    validates :remaining_amount, :numericality => { :less_than_or_equal_to => :original_amount }
    validates :number, uniqueness: true

    scope :created_between, ->(start_date, end_date) { where(created_at: start_date..end_date) }

    def address
      if self[:address_id]
        return Address.find self[:address_id]
      else
        return line_item.order.ship_address
      end
    end

    def order
      line_item.try(:order)
    end

    def authorize(amount, order_currency)
      if soft_authorize(amount, order_currency)
        update_attributes(authorized_amount: self.authorized_amount + amount)

        event = self.voucher_events.create!(action: 'authorize', :amount => amount, authorization_code: generate_authorization_code)
        return event.authorization_code
      else
        return  false
      end
    end

    def soft_authorize(amount, order_currency)
      Rails.logger.debug "#{amount} - #{order_currency} - #{remaining_amount} - #{authorizable_amount} - #{self.number}"

      if !active?
        errors.add(:base, "Inactive voucher")
      elsif authorizable_amount <  amount
        errors.add(:base,"Insufficient funds for voucher: #{self.number}")
      elsif expiration && expiration <= Time.now
        errors.add(:base,"Expired voucher: #{self.number}")
      elsif currency != order_currency
        errors.add(:base,"Currency mismatch: Your order has currency: #{order_currency} but voucher #{self.number} has currency #{self.currency}")
      end

      return errors.blank?
    end

    def capture(amount, authorization_code, order_currency)
      errors.add(:base, "Inactive voucher") and return false unless active?

      if (amount <= authorized_amount)
        # this is a data integrity problem.  Should never occur (unless we race-condition 2 auths then 1 capture)
        if amount > remaining_amount 
          errors.add(:base, "Authorized amount is greater than the remaining amount!") 
          return false
        elsif currency != order_currency  # sanity check to make sure the order currency hasn't changed since the auth
          errors.add(:base,"Currency mismatch: Your order has currency: #{order_currency} but voucher #{self.number} has currency #{self.currency}")
          return false
        end

        self.remaining_amount  = self.remaining_amount - amount
        self.authorized_amount = self.authorized_amount - amount

        save!

        self.voucher_events.create!(action: 'capture', :amount => amount, authorization_code: authorization_code)

      else
        errors.add(:base, "Attempting to capture more than the Authorized amount!")
        return false
      end
    end

    def void(authorization_code)
      errors.add(:base, "Inactive voucher") and return false unless active?

      # find the amount related to this authorization_code.  That's how much we'll put back on the voucher
      auth_event    = self.voucher_events.where(action: 'authorize').where(authorization_code: authorization_code).first rescue nil
      capture_event = self.voucher_events.where(action: 'capture').where(authorization_code: authorization_code).first rescue nil

      if capture_event
        self.remaining_amount  = self.remaining_amount + capture_event.amount

        # de-auth the fully authorized amount
        if auth_event
          auth_amount = auth_event.amount
        else
          Rails.logger.error "Missing auth event but we have a capture event: capture_event.inspect"
          auth_amount = capture_event.amount
        end

        self.authorized_amount = self.authorized_amount - auth_amount
        self.save!
        self.voucher_events.create!(action: 'void', :amount => capture_event.amount, authorization_code: authorization_code)
        return true
      elsif auth_event  # we are voiding an auth...is that even possible?
        self.authorized_amount = self.authorized_amount - auth_event.amount
        self.save!
        self.voucher_events.create!(action: 'void', :amount => auth_event.amount, authorization_code: authorization_code)
        return true
      else
        errors.add(:base, "Unable to void code: #{authorization_code}")
        return false
      end
    end


    def credit(amount, authorization_code, order_currency)
      # TODO: CODE REVIEW - i'm enforcing that you can't credit more than the capture amount - correct behavior?

      errors.add(:base, "Inactive voucher") and return false unless active?

      # find the amount related to this authorization_code.  That's how much we'll put back on the voucher
      capture_event = self.voucher_events.where(action: 'capture').where(authorization_code: authorization_code).first rescue nil

      if currency != order_currency  # sanity check to make sure the order currency hasn't changed since the auth
        errors.add(:base,"Currency mismatch: Your order has currency: #{order_currency} but voucher #{self.number} has currency #{self.currency}")
        return false
      elsif capture_event && amount <= capture_event.amount
        self.update_attributes(remaining_amount: self.remaining_amount + amount)
        self.voucher_events.create!(action: 'credit', :amount => amount, authorization_code: authorization_code)
        return true
      else
        errors.add(:base, "Unable to credit code: #{authorization_code}")
        return false
      end
    end

    def actions
      %w{capture void credit}
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      active? && (payment.pending? || payment.checkout?)
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      active? && !payment.void? # if it's not an active voucher, that means it's no longer part of a 'complete' order (it wasn't paid for or canceled)
    end

    # Indicates whether its possible to credit the payment.  Note that most gateways require that the
    # payment be settled first which generally happens within 12-24 hours of the transaction.
    def can_credit?(payment)
      return false unless payment.completed?
      return false unless payment.order.payment_state == 'credit_owed'
      return false unless active? 
      payment.credit_allowed > 0
    end

    def authorizable_amount
      remaining_amount - authorized_amount
    end

    private
      def generate_authorization_code
        record = true
        while record
          random = "VE#{Array.new(9){rand(8)}.join}"
          record = VoucherEvent.where(authorization_code: random).first
        end
        code = random
        code
      end

      def generate_voucher_number
        record = true
        while record
          random = "V#{Array.new(9){rand(9)}.join}"
          record = self.class.where(number: random).first
        end
        self.number = random if self.number.blank?
        self.number
      end
  
  end
end
