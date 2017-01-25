/*global jQuery, window, document, self*/
var Roster = (function($, window) {

  "use strict";

  var _private = {

    init: function() {
      this.loadArrows();
      this.activateClick();
    },
    loadArrows: function() {
      var sort_field = this.getParameterByName("sort_field"),
          dir = this.getParameterByName("dir");
      var ele = $('*[data-field="'+sort_field+'"]');
      var arrow = ele.parent().find("span.arrow");

      if (sort_field != "") {
        $.each($("span.arrow"), function() {
          $(this).removeClass("arrow-up").removeClass("arrow-down");
        });
      }

      if (dir == "desc") {
        arrow.addClass("arrow-down");
      } else if (dir == "asc") {
        arrow.addClass("arrow-up");
      }
    },
    activateClick: function() {
      var arrow, dir;
      $("thead a", "#roster").on("click", function(e) {
        e.preventDefault();
        arrow = $(this).parent().find("span.arrow");
        if(arrow.hasClass("arrow-down")) {
          dir = "asc";
          arrow.removeClass("arrow-down").addClass("arrow-up");
        } else {
          dir = "desc";
          arrow.removeClass("arrow-up").addClass("arrow-down");
        }
        window.location.href = "/roster?sort_field="+$(this).attr("data-field")+"&dir="+dir;
      });
    },
    getParameterByName: function(name) {
      var cname   = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]"),
          regexS  = "[\\?&]" + cname + "=([^&#]*)",
          regex   = new RegExp(regexS),
          results = regex.exec(window.location.href);

      if(results === null) { return ""; }
      return decodeURIComponent(results[1].replace(/\+/g, " "));
    }
  };

  return {
    init: function() {
      _private.init();
    }
  };

}(jQuery, window));
