$(function() {
  $('.openid-selector').on('click', function(e) {
    // Remove the existing form, if any
    $('#openid_param_form').remove();

    var link_elem = $(this);
    var link_data = link_elem.data();

    if (typeof link_data['parameter'] === 'undefined')
    {
      window.location.href =  link_data['authUrl'] + "?openid_url=" + link_data['openIdUrl'];
    }
    else
    {
      var input_id = (typeof link_data['paramId'] === 'undefined') ? 'openid_param' : link_data['paramId'];
      var navigate_to_auth = function(e) {
        var substituted_url = link_data['openIdUrl'].replace('%{parameter}', $('#'+input_id).val());
        window.location.href = link_data['authUrl'] + "?openid_url=" + substituted_url;
        e.preventDefault();
      };

      var promptText = "Please enter your " + link_data['parameter'] + ".";
      var prompt = $("<div></div>").text(promptText);
      var input = $("<input>").attr('id', input_id)
                              .attr('size', 50)
                              .attr('placeholder', link_data['paramPlaceholder'])
                              .addClass('openid-input');
      var submit_btn = $("<input id='js_submit_openid' type='submit' value='Sign up using OpenID'/>").click(navigate_to_auth);
      var input_form = $("<form id='openid_param_form'></form>").submit(navigate_to_auth)
      input_form.insertAfter(link_elem.parent())
                .append(prompt)
                .append(input)
                .append(submit_btn);
    }
  });

  var disablePasswordInputs = function(elem) {
    // Disable the password change boxes iff the Remove password checkbox is checked
    var disable = elem.is(':checked');
    $('#user_password').prop('disabled', disable);
    $('#user_password_confirmation').prop('disabled', disable);
  };

  $('#user_remove_password').on('click', function(e) { disablePasswordInputs($(this)); });
  disablePasswordInputs($('#user_remove_password'));
});