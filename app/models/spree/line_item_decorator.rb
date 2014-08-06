module Spree
  PermittedAttributes.module_eval do
    mattr_writer :line_item_attributes
  end

  PermittedAttributes.line_item_attributes += [vouchers_attributes: Voucher.permitted_attributes]

  LineItem.class_eval do
    has_many :vouchers #, inverse_of: :line_item # one per quantity
    accepts_nested_attributes_for :vouchers
  end
end
