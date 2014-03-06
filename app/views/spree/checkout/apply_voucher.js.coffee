<% if flash[:error] %>
  SpreeVouchers.show_flash 'error', '<%= flash[:error] %>'
<% elsif flash[:notice] %>
  SpreeVouchers.show_flash 'notice', '<%= flash[:notice] %>'
  ($ '#voucher_fields').hide()
  ($ "[data-hook=checkout_summary_box]" ).html('<%= escape_javascript(render :partial => 'summary', :locals => { :order => @order }) %>')

  # should we clear out all the payment fields so we can proceed withouth validation errors?
  <% if @no_more_payment_required %>
  $('#use_a_voucher').hide()
  $("#payment-methods, [data-hook=payment-methods]").hide()
  $("#payment-method-fields, [data-hook=payment-method-fields]").find("input[type=radio]").attr "checked", false
  $("#payment-method-fields, [data-hook=payment-method-fields]").hide()
  <% end %>
<% end %>
