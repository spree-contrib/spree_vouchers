class CreateSpreeVoucherEvents < ActiveRecord::Migration
  def change
    create_table :spree_voucher_events do |t|
      t.integer :voucher_id,         null: false
      t.string  :action,             null: false
      t.decimal :amount,             precision: 8,  scale: 2
      t.string  :authorization_code, null: false
    end

    add_index :spree_voucher_events, :voucher_id
  end
end
