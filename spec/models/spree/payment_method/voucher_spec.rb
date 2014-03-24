require 'spec_helper'

describe Spree::PaymentMethod::Voucher do

  let (:gateway_options) {
    create(:payment, 
           order: create(:order, 
                         currency: build(:voucher).currency)
          ).gateway_options
  }

  context "authorize" do
    it "declines an unknown voucher" do
      Spree::Voucher.all.map(&:destroy)
      resp = subject.authorize(100, Spree::Voucher.new(number: '1234', remaining_amount: 100000), gateway_options)
      resp.success?.should be_false
      resp.message.should include 'Could not find voucher'
    end

    it "declines a voucher with insuffient funds" do
      voucher = create(:voucher)
      resp = subject.authorize((voucher.remaining_amount * 100) + 1, Spree::Voucher.new(number: voucher.number), gateway_options)
      resp.success?.should be_false
      resp.message.should include "Insufficient funds for voucher"
    end

    it "declines an expired voucher" do
      voucher = create(:expired_voucher)
      resp = subject.authorize((voucher.remaining_amount * 100) - 1, Spree::Voucher.new(number: voucher.number), gateway_options)
      resp.success?.should be_false
      resp.message.should include "Expired voucher"
    end

    it "declines a voucher not matching the order currency" do
      voucher = create(:voucher, currency: 'AUD')
      resp = subject.authorize((voucher.remaining_amount * 100) - 1, Spree::Voucher.new(number: voucher.number), gateway_options)
      resp.success?.should be_false
      resp.message.should include "Currency mismatch"
    end

    # not the right place for this spec...it's a dupe of the one in the right place
    it "allows a voucher having no expiration" do
      voucher = create(:voucher, expiration: nil)
      resp = subject.authorize((voucher.remaining_amount * 100) - 1, Spree::Voucher.new(number: voucher.number), gateway_options)
      resp.success?.should be_true
      resp.authorization.should_not be_nil
    end

    it "authorizes a valid voucher" do
      voucher = create(:voucher)
      resp = subject.authorize((voucher.remaining_amount * 100) - 1, Spree::Voucher.new(number: voucher.number), gateway_options)

      resp.success?.should be_true
      resp.authorization.should_not be_nil
    end
  end

  context "capture" do
    it "declines an unknown voucher" do
      resp = subject.capture(100, 1, gateway_options)
      resp.success?.should be_false
      resp.message.should include 'Could not find voucher'
    end

    it "declines a voucher with insuffient funds (authorized, but remaining amount lower than authorized)" do
      voucher = create(:authorized_voucher)
      auth_code = voucher.voucher_events.where(action: 'authorize').first.authorization_code

      voucher.update_attributes(remaining_amount: voucher.authorized_amount - 1)
      resp = subject.capture((voucher.authorized_amount * 100), auth_code, gateway_options)
      resp.success?.should be_false
      resp.message.should include "Authorized amount is greater than the remaining amount!"
    end

    it "declines a voucher with a requested amount greater than the authorized amount" do
      voucher = create(:authorized_voucher)
      resp = subject.capture((voucher.authorized_amount * 100) + 1, voucher.voucher_events.where(action: 'authorize').first.authorization_code, gateway_options)
      resp.success?.should be_false
      resp.message.should include "Attempting to capture more than the Authorized amount!"
    end

    it "declines a voucher not matching the order currency" do
      voucher = create(:authorized_voucher, currency: 'AUD')
      resp = subject.capture((voucher.authorized_amount * 100) - 1, voucher.voucher_events.where(action: 'authorize').first.authorization_code, gateway_options)

      resp.success?.should be_false
      resp.message.should include "Currency mismatch"
    end

    it "captures a valid voucher" do
      voucher = create(:authorized_voucher)
      resp = subject.capture((voucher.authorized_amount * 100), voucher.voucher_events.where(action: 'authorize').first.authorization_code, gateway_options)

      resp.success?.should be_true
      resp.message.should include "Successful voucher capture"
    end
  end

  context "void" do
    it "declines an unknown voucher" do
      resp = subject.void(1)
      resp.success?.should be_false
      resp.message.should include 'Could not find voucher'
    end

    it "returns an error response when an 'error condition' void request arrives" do
      voucher = create(:captured_voucher)
      auth_code = voucher.voucher_events.where(action: 'authorize').first.authorization_code

      # force an error
      Spree::Voucher.stub_chain(:select, :joins, :where, :first).and_return(voucher)
      voucher.stub(void: nil)

      resp = subject.void(auth_code, gateway_options)
      resp.success?.should be_false
    end

    it "voids a valid voucher void request" do
      voucher = create(:captured_voucher)

      auth_code = voucher.voucher_events.where(action: 'authorize').first.authorization_code

      resp = subject.void(auth_code)
      resp.success?.should be_true
      resp.message.should include "Successful voucher void"
    end

  end

  context "credit" do
    it "declines an unknown voucher" do
      resp = subject.credit(100, 1, gateway_options)
      resp.success?.should be_false
      resp.message.should include 'Could not find voucher'
    end

    it "returns an error response when an 'error condition' credit request arrives" do
      voucher = create(:captured_voucher)
      auth_code = voucher.voucher_events.where(action: 'authorize').first.authorization_code

      # force an error
      Spree::Voucher.stub_chain(:select, :joins, :where, :first).and_return(voucher)
      voucher.stub(credit: nil)

      resp = subject.credit(100000000, auth_code, gateway_options)
      resp.success?.should be_false
    end

    it "declines a voucher not matching the order currency" do
      voucher = create(:captured_voucher, currency: 'AUD')
      auth_code = voucher.voucher_events.where(action: 'authorize').first.authorization_code

      # force an error
      Spree::Voucher.stub_chain(:select, :joins, :where, :first).and_return(voucher)

      resp = subject.credit(100000000, auth_code, gateway_options)
      resp.message.should include "Currency mismatch"
    end

    it "credits a valid voucher credit request" do
      voucher = create(:captured_voucher)

      auth_code = voucher.voucher_events.where(action: 'authorize').first.authorization_code

      resp = subject.credit(1, auth_code, gateway_options)
      resp.success?.should be_true
      resp.message.should include "Successful voucher credit"
    end

  end
end
