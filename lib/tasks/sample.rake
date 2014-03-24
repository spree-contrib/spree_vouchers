namespace :spree_vouchers do
  desc 'Loads sample vouchers'
  task :load_sample => :environment do
    Spree::Voucher.create!(number: 'VALID',
                           expiration: 1.year.from_now,
                           original_amount: 250.00,
                           currency: 'USD')

    # expired voucher
    Spree::Voucher.create!(number: 'EXPIRED',
                           expiration: 1.year.ago,
                           original_amount: 250.00,
                           currency: 'USD')

    # fully authorized voucher
    Spree::Voucher.create!(number: 'FULLY_AUTHED',
                           original_amount: 250.00,
                           authorized_amount: 250.00,
                           currency: 'USD')

    # fully exhausted voucher
    Spree::Voucher.create!(number: 'EXHAUSTED',
                           original_amount: 250.00,
                           remaining_amount: 0.00,
                           currency: 'USD')
    
  end
end


