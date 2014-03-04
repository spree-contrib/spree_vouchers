require 'spec_helper'

describe Spree::Voucher do
  let(:voucher) { create(:voucher) }
  let(:expired_voucher) { create(:expired_voucher) }
  let(:exhausted_voucher) { create(:exhausted_voucher) }
  let(:authorized_voucher) { create(:authorized_voucher) }
  let(:fully_authorized_voucher) { create(:fully_authorized_voucher) }
  let(:voucher_payment_method) { create(:voucher_payment_method) }

  context "authorize" do
    it "adjusts the authorized amount" do
      expect { voucher.authorize(1, voucher.currency) }.to change{voucher.authorized_amount}.from(voucher.authorized_amount).to(voucher.authorized_amount + 1)
    end
    it "allows no more than available" do
      voucher.authorize(100000, voucher.currency).should be_nil
    end
    it "disallows fully authorized vouchers" do
      fully_authorized_voucher.authorize(1, voucher.currency).should be_nil
    end
    it "disallows exhausted vouchers" do
      exhausted_voucher.authorize(1, voucher.currency).should be_nil
    end
    it "disallows expired vouchers" do
      expired_voucher.authorize(1, voucher.currency).should be_nil
    end
    it "allows vouchers with no expiration date" do
      voucher.update_attributes(expiration: nil)
      voucher.authorize(1, voucher.currency).should_not be_nil
    end
    it "returns non-nil on success" do
      voucher.authorize(1, voucher.currency).should_not be_nil
    end
    it "rejects a voucher not matching the order currency" do
      voucher.authorize(1, 'EUR').should be_nil
    end
  end

  context "capture" do
    before do
      @auth_code = authorized_voucher.voucher_events.first.authorization_code
    end

    it "adjusts the authorized amount upon successful capture" do
      expect { authorized_voucher.capture(1,@auth_code, authorized_voucher.currency) }.to change{ authorized_voucher.authorized_amount }.
                                                  from( authorized_voucher.authorized_amount ).
                                                  to( authorized_voucher.authorized_amount - 1 )
    end

    it "adjusts the remaining amount upon successful capture" do
      expect { authorized_voucher.capture(1,@auth_code, authorized_voucher.currency) }.to  change{ authorized_voucher.remaining_amount }.
                                                  from( authorized_voucher.remaining_amount ).
                                                  to( authorized_voucher.remaining_amount - 1 )
    end

    it "does not adjust the authorized amount upon failed capture" do
      expect { authorized_voucher.capture(100,@auth_code, authorized_voucher.currency) }.to_not change{ authorized_voucher.authorized_amount }
    end

    it "does not adjust the remaining amount upon failed capture" do
      expect { authorized_voucher.capture(100,@auth_code, authorized_voucher.currency) }.to_not change{ authorized_voucher.remaining_amount }
    end

    it "captures the authorized amount" do
      authorized_voucher.capture(10,@auth_code, authorized_voucher.currency)
      authorized_voucher.should have(0).errors
    end

    it "captures less than the authorized amount" do
      authorized_voucher.capture(9,@auth_code, authorized_voucher.currency)
      authorized_voucher.should have(0).errors
    end

    it "disallows capturing more than the authorized amount" do
      authorized_voucher.capture(11,@auth_code, authorized_voucher.currency)
      authorized_voucher.should have(1).errors
    end

    it "disallows capturing when the authorized amount is less than the amount but the remaining is amount is less than the authorized amount" do
      authorized_voucher.remaining_amount = authorized_voucher.authorized_amount - 1
      authorized_voucher.capture(authorized_voucher.authorized_amount, @auth_code, authorized_voucher.currency)
      authorized_voucher.should have(1).errors
    end

    it "rejects a voucher not matching the order currency" do
      authorized_voucher.capture(10,@auth_code, 'EUR')
      authorized_voucher.should have(1).errors
    end

    # assuming that auth was successful and we took too long to ship
    # TODO: CODE REVIEW - i'm thinking that it was valid on auth, and if we take a week to ship, it's not their fault..correct?
    it "allows capture on an expired vouchers" do 
      expired_voucher.authorized_amount = 1
      authorized_voucher.capture(1, @auth_code, authorized_voucher.currency)
      authorized_voucher.should have(0).errors
    end
  end

  context "void" do
    context "authorization only" do

      before do
        @voucher = create(:authorized_voucher)
        @voucher_event = @voucher.voucher_events.where(action: 'authorize').first
      end

      it "adjusts the authorized amount" do
        expect { @voucher.void(@voucher_event.authorization_code) }.
          to change{@voucher.authorized_amount}.
          from(@voucher.authorized_amount).
          to(@voucher.authorized_amount - @voucher_event.amount)
      end

      it "does not affect the remaining amount" do
        expect { @voucher.void(@voucher_event.authorization_code) }.
          to_not change{@voucher.remaining_amount}
      end
    end

    # TODO: dig deeper into the possibilites here...can you void a partially capture
    context "partial capture" do
      before do
        @voucher = create(:partially_captured_voucher)
        @auth_voucher_event = @voucher.voucher_events.where(action: 'authorize').first
        @capture_voucher_event = @voucher.voucher_events.where(action: 'capture').first
      end

      it "de-authorizes the full authorized amount (for this auth code)" do
        expect { @voucher.void(@auth_voucher_event.authorization_code) }.
          to change{@voucher.authorized_amount}.
          from(@voucher.authorized_amount).
          to(@voucher.authorized_amount - @auth_voucher_event.amount)
      end


      it "adjusts the remaining amount" do
        expect { @voucher.void(@capture_voucher_event.authorization_code) }.
          to change{@voucher.remaining_amount}.
          from(@voucher.remaining_amount).
          to(@voucher.remaining_amount + @capture_voucher_event.amount)
      end
    end

    context "full capture" do

      before do
        @voucher = create(:captured_voucher)
        @auth_voucher_event = @voucher.voucher_events.where(action: 'authorize').first
        @capture_voucher_event = @voucher.voucher_events.where(action: 'capture').first
      end

      it "de-authorizes the full authorized amount (for this auth code)" do
        expect { @voucher.void(@auth_voucher_event.authorization_code) }.
          to change{@voucher.authorized_amount}.
          from(@voucher.authorized_amount).
          to(@voucher.authorized_amount - @auth_voucher_event.amount)
      end

      it "adjusts the remaining amount" do
        expect { @voucher.void(@capture_voucher_event.authorization_code) }.
          to change{@voucher.remaining_amount}.
          from(@voucher.remaining_amount).
          to(@voucher.remaining_amount + @capture_voucher_event.amount)
      end
    end
  end # void

  context "credit" do
    before do
      @voucher = create(:captured_voucher)
      @voucher_event = @voucher.voucher_events.where(action: 'capture').first
    end

    it "does not affect the authorized amount" do
      expect { @voucher.credit(1, @voucher_event.authorization_code, @voucher.currency) }.
        to_not change{@voucher.authorized_amount}
    end

    it "adjusts the remaining amount" do
      expect { @voucher.credit(1, @voucher_event.authorization_code, @voucher.currency) }.
        to change{@voucher.remaining_amount}.from(@voucher.remaining_amount).to(@voucher.remaining_amount + 1)
    end

    it "prevents an excessive credit from changing the remaining amount" do
      expect { @voucher.credit(100000, @voucher_event.authorization_code, @voucher.currency) }.
        to_not change{@voucher.remaining_amount}
    end

    it "denies a credit that puts us above the original value" do
      @voucher.credit(100000, @voucher_event.authorization_code, @voucher.currency)
      @voucher.should have(1).errors
    end

    it "rejects a voucher not matching the order currency" do
      @voucher.credit(1, @voucher_event.authorization_code, 'EUR')
      @voucher.should have(1).errors
    end

  end
end
