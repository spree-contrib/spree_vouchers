module Spree
  PermittedAttributes.module_eval do
    mattr_writer :line_item_attributes
  end

  unless PermittedAttributes.line_item_attributes.include? :vouchers_attributes
    PermittedAttributes.line_item_attributes += [vouchers_attributes: Voucher.permitted_attributes] 
  end

  LineItem.class_eval do
    has_many :vouchers
    # holy cow man, i had no idea nested objects wouldn't get autosaved (even w/ the autosave:true option)
    before_save :persist_vouchers, :on => :create  
    accepts_nested_attributes_for :vouchers

    private
      def persist_vouchers
        self.vouchers.map(&:save)
      end
  end
end
