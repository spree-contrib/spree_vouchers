module Spree
  class VoucherEvent < ActiveRecord::Base
    belongs_to :voucher
  end
end
