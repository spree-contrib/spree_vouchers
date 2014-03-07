require 'spec_helper'

describe "Checkout/Payment", inaccessible: true do

  let!(:country) { create(:country, :states_required => true) }
  let!(:state) { create(:state, :country => country) }
  let!(:shipping_method) { create(:shipping_method) }
  let!(:stock_location) { create(:stock_location) }
  let!(:mug) { create(:product, :name => "RoR Mug") }
  let!(:zone) { create(:zone) }

  let!(:credit_card_payment_method) { create(:credit_card_payment_method, environment: 'test') }
  let!(:voucher_payment_method) { create(:voucher_payment_method) }

  let(:voucher) { create(:voucher, original_amount: 10000, remaining_amount: 10000) }
  let(:expired_voucher) { create(:expired_voucher) }
  let(:exhausted_voucher) { create(:exhausted_voucher) }
  let(:authorized_voucher) { create(:authorized_voucher) }
  let(:fully_authorized_voucher) { create(:fully_authorized_voucher) }

  let(:low_balance_voucher1) { create(:voucher, number: 'abcd', original_amount: 1, remaining_amount: 1) }
  let(:low_balance_voucher2) { create(:voucher, number: 'wxyz', original_amount: 1, remaining_amount: 1) }
  let(:zero_dollars) { Spree::Money.new(0, { currency: low_balance_voucher1.currency }) }
  let(:one_dollar) { Spree::Money.new(1, { currency: low_balance_voucher1.currency }) }

  def apply_more_than_one_voucher
    click_link Spree.t(:use_a_voucher)
    fill_in 'voucher_number', with: low_balance_voucher1.number
    click_link Spree.t(:apply_voucher)

    # wait for the order summary to reload
    find(:xpath, '//tr[@class="summary-order-voucher-detail"][1]/td[1]/strong').should have_content low_balance_voucher1.number

    click_link Spree.t(:use_a_voucher)
    fill_in 'voucher_number', with: low_balance_voucher2.number
    click_link Spree.t(:apply_voucher)

    find(:xpath, '//tr[@class="summary-order-voucher-detail"][2]/td[1]/strong').should have_content low_balance_voucher2.number
  end

  after do
    Capybara.ignore_hidden_elements = true
  end

  before do
    Capybara.ignore_hidden_elements = false

    @order = OrderWalkthrough.up_to(:delivery)
    @order.stub :confirmation_required? => true
    @order.stub(:available_payment_methods => [ create(:credit_card_payment_method, :environment => 'test') ])

    user = create(:user)
    @order.user = user
    @order.update!
    
    Spree::CheckoutController.any_instance.stub(:current_order => @order)
    Spree::CheckoutController.any_instance.stub(:try_spree_current_user => user)

    visit spree.checkout_state_path(:delivery)
    click_button "Save and Continue"
  end

  context "Voucher Redemption" do
    it "supports paying solely by voucher", js: true  do
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: voucher.number
      click_link Spree.t(:apply_voucher)

      # the 'Amount Due' should now show zero
      find("#summary-order-minus-vouchers-total").should have_content(Spree::Money.new(0, { currency: voucher.currency }))

      # the other payment fields should be hidden
      find("#payment-method-fields, [data-hook=payment-method-fields]").visible?.should be_false
      find("#payment-methods, [data-hook=payment-methods]").visible?.should be_false

      click_button Spree.t(:save_and_continue)
      current_path.should == spree.checkout_state_path(:confirm)
    end

    it "supports paying solely by other payment method (e.g. credit card)", js: true do
      choose "Credit Card"
      fill_in "Card Number", :with => '4111111111111111'
      fill_in "card_expiry", :with => '04 / 20'
      fill_in "Card Code", :with => '123'

      click_button Spree.t(:save_and_continue)
      click_button Spree.t(:place_order)
      current_path.start_with?(spree.order_path(@order.number)).should be_true
    end

    it "gracefully handles fully-authorized vouchers", js: true do
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: fully_authorized_voucher.number
      click_link Spree.t(:apply_voucher)
      page.should have_content(Spree.t(:unable_to_apply_voucher_with_remaining_balance, 
                                       { available: Spree::Money.new(fully_authorized_voucher.authorizable_amount, { currency: fully_authorized_voucher.currency }),
                                         expiration: fully_authorized_voucher.expiration,
                                         currency: fully_authorized_voucher.currency
                                       })
                               )
    end

    it "gracefully handles exhausted vouchers", js: true do
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: exhausted_voucher.number
      click_link Spree.t(:apply_voucher)
      page.should have_content(Spree.t(:unable_to_apply_voucher_with_remaining_balance, {
                                         available: Spree::Money.new(exhausted_voucher.authorizable_amount, { currency: exhausted_voucher.currency }),
                                         expiration: exhausted_voucher.expiration,
                                         currency: exhausted_voucher.currency
                                       })
                               )
    end

    it "gracefully handles expired vouchers", js: true do
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: expired_voucher.number
      click_link Spree.t(:apply_voucher)
      page.should have_content(Spree.t(:unable_to_apply_voucher_with_remaining_balance, {
                                         available: Spree::Money.new(expired_voucher.authorizable_amount, { currency: expired_voucher.currency }),
                                         expiration: expired_voucher.expiration,
                                         currency: expired_voucher.currency
                                       })
                               )
    end

    it "gracefully handles unknown voucher payment errors", js: true do
      bogus_number = 'asdfasfdasfdfdf'
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: bogus_number
      click_link Spree.t(:apply_voucher)
      page.should have_content(Spree.t(:no_voucher_exists_for_number, number: bogus_number))
    end

    it "updates the order summary with the applied voucher information", js: true do
      voucher.update_attributes(original_amount: 1, remaining_amount: 1)
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: voucher.number
      click_link Spree.t(:apply_voucher)

      find(".summary-order-voucher-detail .summary-order-voucher-amount").should have_content(Spree::Money.new(1, { currency: voucher.currency }))
    end

    it "updates the order summary with the amount still owed", js: true do
      voucher.update_attributes(original_amount: 1, remaining_amount: 1)
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: voucher.number
      click_link Spree.t(:apply_voucher)

      # the 'Amount Due' should now show the updated total
      find("#summary-order-minus-vouchers-total").should have_content(Spree::Money.new(@order.total - 1, { currency: voucher.currency }))
    end

    it "handles payment after a failed voucher application", js: true do
      bogus_number = 'asdfasfdasfdfdf'
      click_link Spree.t(:use_a_voucher)
      fill_in 'voucher_number', with: bogus_number
      click_link Spree.t(:apply_voucher)

      choose "Credit Card"
      fill_in "Card Number", :with => '4111111111111111'
      fill_in "card_expiry", :with => '04 / 20'
      fill_in "Card Code", :with => '123'

      click_button Spree.t(:save_and_continue)
      click_button Spree.t(:place_order)
      current_path.start_with?(spree.order_path(@order.number)).should be_true
    end

    it "should support paying without a voucher even after clicking 'use a voucher'", js: true do
      click_link Spree.t(:use_a_voucher)

      choose "Credit Card"
      fill_in "Card Number", :with => '4111111111111111'
      fill_in "card_expiry", :with => '04 / 20'
      fill_in "Card Code", :with => '123'

      click_button Spree.t(:save_and_continue)
      click_button Spree.t(:place_order)
      current_path.start_with?(spree.order_path(@order.number)).should be_true
    end

    context "redeem multiple vouchers on same order" do
      before do
        apply_more_than_one_voucher()
      end

      it "updates the order summary with the applied voucher information for each voucher", js: true do
        page.all(".summary-order-voucher-detail .summary-order-voucher-amount").count.should == 2
      end

      it "updates the order summary with the amount still owed", js: true do
        find("#summary-order-minus-vouchers-total").should have_content(Spree::Money.new(@order.total - 2, { currency: voucher.currency }))
      end
    end
  end # voucher redemption

  context "Removing a voucher from an order" do
    context "More than one voucher" do

      before do
        apply_more_than_one_voucher()
        first(".summary-order-voucher-detail").find("a").click
        # use the technique listed in the capybara readme (search for: always use the latter!)
        # in order to wait for the ajax to complete
        page.should have_no_xpath('//tr[@class="summary-order-voucher-detail"][2]')
      end

      it "modifies the order total in the order summary", js: true do
        find("#summary-order-minus-vouchers-total").should have_content(Spree::Money.new(@order.total - 1, { currency: voucher.currency }))
      end

      it "removes the removed voucher entry from the order summary", js: true do
        find(:xpath, '//tr[@class="summary-order-voucher-detail"][1]/td[1]/strong').should have_content low_balance_voucher2.number
        page.all(".summary-order-voucher-detail .summary-order-voucher-amount").count.should == 1
      end
    end # more than one voucher

    context "Voucher is the only payment" do
      before do
        click_link Spree.t(:use_a_voucher)
        fill_in 'voucher_number', with: voucher.number
        click_link Spree.t(:apply_voucher)
        find(".summary-order-voucher-detail a").click
        page.should have_no_xpath('//tr[@class="summary-order-voucher-detail"][1]')
      end

      it "notifies the user in the flash section", js: true do
        msg = Spree.t(:voucher_removed_for_amount_with_remaining_balance, 
                      { payment_amount: Spree::Money.new(@order.total, { currency: voucher.currency }),
                        available: Spree::Money.new(voucher.reload.authorizable_amount, { currency: voucher.currency }) })

        page.should have_content(msg)
      end

      it "removes the 'Amount Due' line from the order summary", js: true do
        page.should_not have_selector "#summary-order-minus-vouchers-total"
      end

      it "removes the line pertaining to this voucher payment in the order summary", js: true do
        page.should_not have_selector(".summary-order-voucher-detail .summary-order-voucher-amount")
      end
    end # voucher is the only payment
    
  end # removing a voucher
end
