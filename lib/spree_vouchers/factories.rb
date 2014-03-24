FactoryGirl.define do
  factory :voucher_payment_method, class: Spree::PaymentMethod::Voucher do
    name 'Voucher'
    environment 'test'
  end

  factory :voucher, :class => 'Spree::Voucher' do
    number '12341234abcdefg'
    expiration 1.year.from_now
    original_amount 25.00
    currency 'USD'

    factory :authorized_voucher do
      authorized_amount 10

      after(:create) { |v| 
        v.voucher_events.create!(action: 'authorize', amount: 10, authorization_code: v.number)
      }

      factory :partially_captured_voucher do

        after(:create) { |v| 
          v.update_column(:remaining_amount, 5.00)
          v.voucher_events.create!(action: 'capture', amount: 5, authorization_code: v.number)
        }
      end

      factory :captured_voucher do
        after(:create) { |v| 
          v.update_column(:remaining_amount, 0.00)
          v.voucher_events.create!(action: 'capture', amount: 10, authorization_code: v.number)
        }
      end
    end


    factory :expired_voucher  do
      expiration 1.second.ago
      after(:create) { |v| 
        v.update_column(:remaining_amount, 5.00)
      }
    end

    # auths and captures should fail
    factory :exhausted_voucher do
      after(:create) { |v| 
        v.update_column(:remaining_amount, 0.00)
      }
    end

    # auths should fail
    factory :fully_authorized_voucher, parent: :authorized_voucher do
      authorized_amount 25
    end
  end
end
