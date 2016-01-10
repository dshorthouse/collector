/*global window, document, jQuery, google, L */
var SocialGraph = (function($, window) {

  "use strict";

  var _private = {

    init: function() {
      this.createGraph();
    },
    createGraph: function() {
      var container = $('#social-graph')[0],
          options = {
            nodes: {
              shape: 'dot',
              scaling: {
                min: 10,
                max: 30
              },
              size: 12
            },
            edges: {
              width: 0.15
            },
            interaction: {
              hideEdgesOnDrag: true
            },
            physics: {
              forceAtlas2Based: {
                gravitationalConstant: -25,
                springLength: 10
              },
              maxVelocity: 150,
              solver: 'forceAtlas2Based',
              timestep: 0.2
            }
          },
          network = "";

      $.ajax({
        type: 'GET',
        url: '/images/graphs/socialgraph.json',
        dataType: 'json',
        success: function(response) {
          network = new vis.Network(container, response, options);
        },
        error: function(xhr, ajaxOptions, thrownError) {
        }
      });
    }
  };

  return {
    init: function() {
      _private.init();
    }
  };

}(jQuery, window));