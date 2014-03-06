module Spree
  Payment.class_eval do

    delegate :voucher?, to: :payment_method

    durably_decorate :build_source, mode: 'strict', sha: '40c31bc22daa6cfa240d316c2d0a4f2611048420' do
      return if source_attributes.nil?

      if payment_method && payment_method.payment_source_class == Spree::Voucher
        self.source = Voucher.where(number: source_attributes[:number]).first
      elsif payment_method && payment_method.payment_source_class
        self.source = payment_method.payment_source_class.new(source_attributes)
      end
    end
  end
end
