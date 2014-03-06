Spree::Core::Engine.routes.draw do
  post '/apply_voucher', to: 'checkout#apply_voucher', as: :apply_voucher
end
