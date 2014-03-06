# borrowed from spree_backend#admin.js.erb
$ ->
  ($ '#use_a_voucher').on 'click', (event) ->
    event.preventDefault()
    ($ '#voucher_fields').toggle()

  ($ '#apply_voucher').on 'click', (event) ->
    event.preventDefault()
    $.ajax
      type: "POST"
      url: "/apply_voucher"
      data:
        voucher_number: ($ '#voucher_number').val()
        voucher_order_id: ($ '#voucher_order_id').val()
      dataType: "script"
