/*global window, document, jQuery, google, L */

var Waypoint = (function($, window) {

  "use strict";

  var _private = {

    id: "",
    map: {},
    layers: [],

    init: function(id) {
      this.id = id;
      $('#recordings-wrapper').show();
      this.createMap();
    },
    createMap: function() {
      var baseLayer, self = this, mapZoom, zoom;

      this.map = L.map('map').setView([55.0, -100.0], 3);
      baseLayer = new L.StamenTileLayer('toner-lite', {
        detectRetina: true
      });
      baseLayer.addTo(this.map);
      this.addWayPoints();
    },
    addWayPoints: function() {
      var self = this, parsed, coord, latlng, days = [], points = [];

      $.ajax({
        type: 'GET',
        url: '/images/graphs/waypoints/' + self.id + '.dot',
        success: function(response) {
          parsed = vis.network.convertDot(response);
          points = $.map(parsed.nodes, function(n) {
            coord = n["coordinate"].split(",");
            latlng = new L.latLng(coord[0], coord[1]);
            days.push(n["day"]);
            latlng.day = n["day"];
            return latlng;
          });

          var polyline = new L.multiOptionsPolyline(points, {
              multiOptions: {
                  optionIdxFn: function (latLng) {
                      var i, mod = 365, x = [];
                      for (i = Math.min.apply(Math, days); i <= Math.max.apply(Math, days); i++) {
                        if(i % mod == 0) {
                          x.push(i);
                        }
                      }
                      for (i = 0; i < x.length; ++i) {
                          if (latLng.day <= x[i]) {
                              return i;
                          }
                      }
                      return x.length;
                  },
                  options: [
                      {color: '#0000FF'}, {color: '#0040FF'}, {color: '#0080FF'},
                      {color: '#00FFB0'}, {color: '#00E000'}, {color: '#80FF00'},
                      {color: '#FFFF00'}, {color: '#FFC000'}, {color: '#FF0000'}
                  ]
              },
              weight: 5,
              lineCap: 'butt',
              opacity: 0.75,
              smoothFactor: 1}).addTo(self.map);

        },
        error: function(xhr, ajaxOptions, thrownError) {
          //alert(xhr.responseText);
        }
      });
    }
  };

  return {
    init: function(id) {
      _private.init(id);
    }
  };

}(jQuery, window));