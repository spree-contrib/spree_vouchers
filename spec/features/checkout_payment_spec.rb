require 'spec_helper'

describe "Checkout/Payment", inaccessible: true do

  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:payment_method) { create(:check_payment_method) }
  let!(:zone) { create(:zone) }
  let!(:credit_card_payment_method) { create(:credit_card_payment_method) }
  let!(:voucher_payment_method) { create(:voucher_payment_method) }

  before(:each) do
    order = OrderWalkthrough.up_to(:delivery)
    order.stub :confirmation_required? => true
    order.stub(:available_payment_methods => [ voucher_payment_method, credit_card_payment_method ])

    user = create(:user)
    order.user = user
    order.update!

    Spree::CheckoutController.any_instance.stub(:current_order => order)
    Spree::CheckoutController.any_instance.stub(:try_spree_current_user => user)
  end

  context "Voucher Redemption" do
    pending "supports paying solely by voucher"
    pending "supports paying solely by other payment method (e.g. credit card)"
    pending "gracefully handles fully-authorized vouchers"
    pending "gracefully handles exhausted vouchers"
    pending "gracefully handles expired vouchers"
    pending "gracefully handles unknown voucher payment errors"
    pending "updates the order summary with the applied voucher information"
    pending "updates the order summary with the amount still owed"
    pending "allows progression when the application of a voucher fully covers the order total"

    context "redeem multiple vouchers on same order" do
      pending "updates the order summary with the applied voucher information for each voucher"
      pending "updates the order summary with the amount still owed"
    end

    # this is pretty explicitly handled in the design of the page.  Payment by anything other than voucher 
    # submits the whole form and spree handles the rest, so I don't think we need to test this?
    # context "redeem voucher(s) and a SINGLE instance of ONE other payment type in the same order (e.g. 1 credit card. 1 paypal payment)"
  end

#=========== jeff is going to move many of these contexts into a model spec where they belong ======== #

  context "Refunds" do
    context "expired voucher" do
      pending "it behaves however we decide it behaves"
    end

    context "order fully paid by voucher" do
      pending "adds the full order balance back on to the voucher"
    end

    context "order partially paid by voucher" do
      # Jeff is thinking we'll want to refund vouchers last

      context "refund is less than the amount paid on credit card" do
        pending "adds the amount paid back to the credit card"
        pending "does not affect the voucher balance"
      end

      context "refund exceeds the amount paid on credit card" do
        pending "adds the amount paid back to the credit card"
        
        context "single voucher" do
          pending "adds the remainder to the voucher"
        end
        context "multiple vouchers" do
          pending "Jeff is thinking: pick the highest one first, try to completely refill it, then move on the the next"
          context "first voucher can hold the remaining amount" do
            pending "One highest-valued voucher has its balance adjusted the refund amount"
          end

          context "first voucher can not hold the remaining amount" do
            pending "The highest-valued voucher has its balance adjusted the original 'max' voucher amount"
            pending "The next-highest-valued voucher has its balance adjusted for the remaining amount"
          end

        end
      end
    end
  end
end
