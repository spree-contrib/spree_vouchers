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
      voucher.authorize(100000, voucher.currency).should be_false
    end
    it "disallows fully authorized vouchers" do
      fully_authorized_voucher.authorize(1, fully_authorized_voucher.currency).should be_false
    end
    it "disallows exhausted vouchers" do
      exhausted_voucher.authorize(1, exhausted_voucher.currency).should be_false
    end
    it "disallows expired vouchers" do
      expired_voucher.authorize(1, expired_voucher.currency).should be_false
    end
    it "allows vouchers with no expiration date" do
      voucher.update_attributes(expiration: nil)
      voucher.authorize(1, voucher.currency).should be_true
    end
    it "returns true on success" do
      voucher.authorize(1, voucher.currency).should be_true
    end
    it "rejects a voucher not matching the order currency" do
      voucher.authorize(1, 'EUR').should be_false
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
    it "allows capture on an expired vouchers" do 
      authorized_voucher.update_column(:expiration, 1.minute.ago)
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

  # I'm thinking that this whole section is irrelevant as payments are individually manipulated
  # in the admin app.  TODO: discuss
  context "Refunds" do
    context "expired voucher" do
      pending "it behaves however we decide it behaves"
    end

    context "order fully paid by voucher" do
      pending "adds the full order balance back on to the voucher"
    end

    context "order partially paid by voucher" do

      context "refund is less than the amount paid on voucher" do
        pending "adds the refund amount back to the voucher"
        pending "does not affect the credit card"
      end

      context "refund exceeds the amount paid on voucher(s)" do
        pending "adds the amount paid back to the voucher"
        
        context "single voucher" do
          pending "adds the remainder to the credit card"
        end
        context "multiple vouchers" do
          pending "Jeff is thinking: pick the highest one first, try to completely refill it, then move on the the next"
          context "first voucher can hold the remaining amount" do
            pending "One highest-valued voucher has its balance adjusted by the refund amount"
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


# can only create a payment if credit owed
