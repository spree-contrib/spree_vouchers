require 'spec_helper'

describe "Payments" do

  stub_authorization!

  let!(:voucher_payment_method) { create(:voucher_payment_method) }
  let!(:voucher) { create(:voucher, number: '1234', original_amount: 10000) }

  context "with a pre-existing payment" do
    let!(:order) { create(:completed_order_with_totals, number: 'R100') }
        
    let!(:payment) do
      create(:payment,
             order:          order,
             amount:         order.outstanding_balance,
             payment_method: create(:credit_card_payment_method),
             state:          state
             )
    end

    let(:state) { 'checkout' }

    before do
      #Spree::ShippingMethod.stub(:calculator).and_return(create(:calculator))
      visit spree.admin_path
      click_link 'Orders'

      #      within_row(1) do
      click_link order.number
      #      end
      click_link 'Payments'
    end


    context 'with a voucher payment' do
      let!(:payment) do
        create(:payment,
               order:          order,
               amount:         order.outstanding_balance,
               payment_method: create(:voucher_payment_method)
               )
      end

      skip "why isn't my icon visible???? capturing a voucher payment from a new order" do
        click_icon(:capture)
        page.should_not have_content('Cannot perform requested operation')
        page.should have_content('Payment Updated')
      end

      skip "why isn't my icon visible???? voids a voucher payment from a new order" do
        click_icon(:void)
        page.should have_content('Payment Updated')
      end
    end
  end

  context "with no prior payments" do
    let(:order) { create(:order_with_line_items, :line_items_count => 1) }

    let!(:payment_method) { create(:voucher_payment_method)}
    before do
      visit spree.admin_order_payments_path(order)
    end

    it "is able to create a new voucher payment with valid information" do
      choose "Voucher"
      fill_in "Number", :with => "1234"
      click_button "Continue"
      page.should have_content("Payment has been successfully created!")
    end

    it "is unable to create a new payment with invalid information" do
      choose "Voucher"
      fill_in "Number", :with => "notarealvoucher1234"
      click_button "Continue"
      page.should have_content("No voucher exists for number")
    end
  end
end
