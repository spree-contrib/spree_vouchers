module Spree
  PermittedAttributes.module_eval do
    mattr_writer :line_item_attributes
  end

  unless PermittedAttributes.line_item_attributes.include? :vouchers_attributes
    PermittedAttributes.line_item_attributes += [vouchers_attributes: Voucher.permitted_attributes] 
  end

  LineItem.class_eval do
    has_many :vouchers #, inverse_of: :line_item # one per quantity
    accepts_nested_attributes_for :vouchers
  end
end
