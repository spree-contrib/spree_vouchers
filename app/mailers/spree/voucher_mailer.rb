module Spree
  class VoucherMailer < BaseMailer
    def voucher_email(voucher)
      @voucher = voucher
      subject = "#{Spree::Store.current.name} #{Spree.t('voucher_mailer.voucher_email.subject')} ##{voucher.order.number}"
      mail(to: voucher.order.email, from: from_address, subject: subject)
    end
  end
end
