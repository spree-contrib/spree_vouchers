//= require spree/frontend/apply_voucher
//= require spree/frontend/remove_voucher
//= require spree/frontend/voucher_product
//= require_self

var SpreeVouchers = {
  show_flash: function(type, message) {
    var flash_div;

    flash_div = $(".flash." + type);
    if (flash_div.length === 0) {
      flash_div = $("<div class=\"flash " + type + "\" />");
      $("#wrapper").prepend(flash_div);
    }
    flash_div.html(message).show().delay(5000).fadeOut(500);
  },
  attach_remove_voucher_event: function() {
    $('.remove_voucher').on('click', function(event) {
      event.preventDefault();

      $.ajax({
        type: "POST",
        url: "/remove_voucher",
        data: {
          payment_id: $(this).data('payment-id')
        },
        dataType: "script"
      });
    });
  }
};
