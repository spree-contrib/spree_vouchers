Spree.ready ($) ->
  Spree.Voucher = {}

  Spree.onVoucherAddress = () ->
    if ($ '#inside-product-cart-form').is('*')
      ($ '#inside-product-cart-form').closest('form').validate()

      Spree.updateState = () ->
        countryId = $('#vcountry select').val()
        if countryId?
          unless Spree.Voucher[countryId]?
            $.get Spree.routes.states_search, {country_id: countryId}, (data) ->
              Spree.Voucher[countryId] =
                states: data.states
                states_required: data.states_required
              Spree.fillStates(Spree.Voucher[countryId])
          else
            Spree.fillStates(Spree.Voucher[countryId])

      Spree.fillStates = (data) ->
        statesRequired = data.states_required
        states = data.states

        statePara = ($ '#vstate')
        stateSelect = statePara.find('select')
        stateInput = statePara.find('input')
        stateSpanRequired = statePara.find('[id$="state-required"]')
        if states.length > 0
          selected = parseInt stateSelect.val()
          stateSelect.html ''
          statesWithBlank = [{ name: '', id: ''}].concat(states)
          $.each statesWithBlank, (idx, state) ->
            opt = ($ document.createElement('option')).attr('value', state.id).html(state.name)
            opt.prop 'selected', true if selected is state.id
            stateSelect.append opt

          stateSelect.prop('disabled', false).show()
          stateInput.hide().prop 'disabled', true
          statePara.show()
          stateSpanRequired.show()
          stateSelect.addClass('required') if statesRequired
          stateSelect.removeClass('hidden')
          stateInput.removeClass('required')
        else
          stateSelect.hide().prop 'disabled', true
          stateInput.show()
          if statesRequired
            stateSpanRequired.show()
            stateInput.addClass('required')
          else
            stateInput.val ''
            stateSpanRequired.hide()
            stateInput.removeClass('required')
          statePara.toggle(!!statesRequired)
          stateInput.prop('disabled', !statesRequired)
          stateInput.removeClass('hidden')
          stateSelect.removeClass('required')

      ($ '#vcountry select').change ->
        Spree.updateState()

      ($ '#voucher_address').find('input,select').prop 'disabled', true
  Spree.onVoucherAddress()

  $('#physical_delivery').click (ele)->
    if $('#physical_delivery').prop("checked")
      ($ '#voucher_address').show()
      ($ '#voucher_address').find('input,select').prop 'disabled', false


  $('#email_delivery').click (ele)->
    if $('#email_delivery').prop("checked")
      ($ '#voucher_address').hide()
      ($ '#voucher_address').find('input,select').prop 'disabled', true

