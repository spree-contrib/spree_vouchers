require 'spec_helper'

describe Spree::OrderPopulator do
  let(:order) { FactoryGirl.create(:order) }
  let(:variant) { FactoryGirl.create(:variant) }

  subject { Spree::OrderPopulator.new(order, "USD") }

  context "voucher" do
    it "builds a voucher" do
      expect {
        subject.populate(variant.id, 1, 
                         options: { vouchers: {
                             number: '1234',
                             original_amount: 10,
                             currency: 'USD'
                           }
                         }
                         )
      }.to change {
        order.line_items.map(&:vouchers).flatten.size
      }.by 1
    end
  end
end
