FactoryGirl.define do
  factory :voucher, :class => 'Spree::Voucher' do
    number '12341234abcdefg'
    expiration 1.year.from_now
    original_amount 25.00
    remaining_amount 25.00
    currency 'GBP'

    factory :authorized_voucher do
      authorized_amount 10

      after(:create) { |v| 
        v.voucher_events.create!(action: 'authorize', amount: 10, authorization_code: v.number)
      }

      factory :partially_captured_voucher do
        remaining_amount 5

        after(:create) { |v| 
          v.voucher_events.create!(action: 'capture', amount: 5, authorization_code: v.number)
        }
      end

      factory :captured_voucher do
        remaining_amount 0

        after(:create) { |v| 
          v.voucher_events.create!(action: 'capture', amount: 10, authorization_code: v.number)
        }
      end
    end


    factory :expired_voucher  do
      expiration 1.second.ago
      remaining_amount 5
    end

    # auths and captures should fail
    factory :exhausted_voucher do
      remaining_amount 0
    end

    # auths should fail
    factory :fully_authorized_voucher, parent: :authorized_voucher do
      authorized_amount 25
    end
  end
end
