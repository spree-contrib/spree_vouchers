class AddMoreFieldsToSpreeVouchers < ActiveRecord::Migration
  def change
    add_column :spree_vouchers, :voucher_from, :string
    add_column :spree_vouchers, :voucher_to, :string
    add_column :spree_vouchers, :message, :string
    add_column :spree_vouchers, :delivery_method, :string, default: 'email'
    add_column :spree_vouchers, :active, :string, default: false
    add_reference :spree_vouchers, :address
  end
end
