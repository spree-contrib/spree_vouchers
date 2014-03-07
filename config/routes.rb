Spree::Core::Engine.routes.draw do
  post '/apply_voucher', to: 'checkout#apply_voucher', as: :apply_voucher
  post '/remove_voucher', to: 'checkout#remove_voucher', as: :remove_voucher
end
