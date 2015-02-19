// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree

$(function() {
  $('[data-remote][data-replace]')
    .data('type', 'html')
    .on('ajax:success', function(event, data) {
      var $this = $(this);
      $($this.data('replace')).html(data);
      $this.trigger('ajax:replaced');
    });

  $('[data-multiverse-select]').each( function(ix) {
    var elem = $(this);
    elem.animate({'opacity': 0}, function () { $(this).css('visibility', 'hidden') });

    $.ajax({
      url: elem.data('multiverse-select'),
      error: function() { elem.css('visibility', 'visible')
                              .animate({'opacity': 1}); },
      success: function(data) {
        var select = $(data);
        select.hide().insertAfter(elem);
        elem.remove();
        select.fadeIn();
      }
    });
  })
});

$(document).ajaxError(function (e, xhr, settings) {
  if (xhr.status == 401) {
    window.location.replace(window.new_user_session_path);
  }
});
