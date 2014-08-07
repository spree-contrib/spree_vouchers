module Spree
  Variant.class_eval do
    def vouchers_attributes_price_modifier_amount(attrs)
      attrs.map {|h| h[:original_amount].to_f}.sum
    end

    def vouchers_attributes_price_modifier_amount_in(currency, attrs)
      # CODE_REVIEW - I'm thinking currency won't matter here as we'll just 
      # return what the user entered
      attrs.map {|h| h[:original_amount].to_f}.sum
    end
  end
end
