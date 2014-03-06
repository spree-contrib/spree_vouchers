//= require spree/frontend/apply_voucher
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
  }
}
