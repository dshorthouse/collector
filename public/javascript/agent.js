/*global window, document, jQuery, google, L */
var Agent = (function($, window) {

  "use strict";

  var _private = {

    id: "",
    activity: { hits: { total: "" }, aggregations: { determinations: { histogram: { buckets: [] } }, recordings: { histogram: { buckets: [] } } } },
    chartData: { determinations : [["Year", "Identifications"]], recordings : [["Year", "Collected specimens"]]},
    map: {},
    layers: [],

    init: function(id) {
      this.id = id;
      this.getActivity();
      this.createCharts();
      this.createMap();
      this.createGraph();
    },
    getActivity: function(zoom) {
      var self = this;

      $.ajax({
        async: false,
        type : 'GET',
        data : { zoom: zoom },
        url  : '/agent/' + this.id + '/activity.json',
        dataType : 'json',
        success : function(response) {
          self.activity = response;
        }
      });
    },
    createCharts: function() {
      var self = this;

      if(this.activity.aggregations.determinations.histogram.buckets.length > 0) {
        $.each(this.activity.aggregations.determinations.histogram.buckets, function() {
          self.chartData.determinations.push([this.key_as_string, this.doc_count]);
        });
      }
      if(this.activity.aggregations.recordings.histogram.buckets.length > 0) {
        $.each(this.activity.aggregations.recordings.histogram.buckets, function() {
          self.chartData.recordings.push([this.key_as_string, this.doc_count]);
        });
      }
      if(this.chartData.determinations.length > 1) {
        google.setOnLoadCallback(function() { self.drawCharts(self.chartData.determinations, 'determinations'); });
        $('#determinations-wrapper').show();
      }
      if(this.chartData.recordings.length > 1) {
        google.setOnLoadCallback(function() { self.drawCharts(self.chartData.recordings, 'recordings'); });
        $('#recordings-wrapper').show();
      }
    },
    drawCharts: function(data, ele) {
      var chart = new google.visualization.ColumnChart(document.getElementById(ele)),
          options = {
            legend : { position : 'none'},
            animation:{
                    duration: 1000,
                    easing: 'inAndOut',
                  },
            vAxis: { minValue:0,maxValue:5,gridlines:{count:6} }
          };
      chart.draw(google.visualization.arrayToDataTable(data), options);
    },
    createMap: function() {
      var baseLayer, self = this, mapZoom, zoom;

      this.map = L.map('map').setView([55.0, -100.0], 3);
      baseLayer = new L.StamenTileLayer('toner-lite', {
        detectRetina: true
      });
      baseLayer.addTo(this.map);

      this.addGeoHash();

      this.map.on('draw:created', function (e) {
          var type = e.layerType,
              layer = e.layer;

          map.addLayer(layer);
      });

      this.map.on('zoomend', function() {
        mapZoom = self.map.getZoom();
        if(self.activity.aggregations.recordings.histogram.buckets.length > 0) {
          if(mapZoom < 2) {
            zoom = 2;
          }
          if(mapZoom >= 3 && mapZoom <= 5) {
            zoom = 3;
          }
          if(mapZoom >= 6 && mapZoom <= 7) {
            zoom = 4;
          }
          if(mapZoom >= 8 && mapZoom <= 10) {
            zoom = 5;
          }
          if(mapZoom >= 11 && mapZoom <= 13) {
            zoom = 6;
          }
          if(mapZoom >= 14 && mapZoom <= 15) {
            zoom = 7;
          }
          if(mapZoom >= 16) {
            zoom = 8;
          }
          self.getActivity(zoom);
          self.removeLayers();
          self.addGeoHash();
        }
      });
    },
    addGeoHash: function() {
      var self = this, colorFunction, fillColorFunction, options, layer, max = this.geohashMax();

      colorFunction = new L.HSLHueFunction(new L.Point(0,200), new L.Point(max,0), {outputSaturation: '100%', outputLuminosity: '25%'});
      fillColorFunction = new L.HSLHueFunction(new L.Point(0,200), new L.Point(max,0), {outputSaturation: '100%', outputLuminosity: '50%'});
      options = {
        locationMode: L.LocationModes.GEOHASH,
        recordsField: 'buckets',
        geohashField: 'key',
        displayOptions: {
          doc_count: {
            color: colorFunction,
            fillColor: fillColorFunction,
            gradient: true,
            displayName: "Records"
          }
        },
        layerOptions: {
          fillOpacity: 0.7,
          opacity: 1,
          weight: 1,
          gradient: true,
          numberOfSides: 6
        },
        getMarker: function (latLng, layerOptions, record) {
            return new L.RegularPolygonMarker(latLng, layerOptions);
         }
      };

      $.each(this.activity.aggregations.recordings.histogram.buckets, function() {
        if (this.geohash.buckets.length > 0) {
          layer = new L.DataLayer(this.geohash, options);
          self.map.addLayer(layer);
          self.layers.push(layer);
        }
      });
      if(this.layers.length > 0) {
        //L.control.layers(null, this.layers).addTo(this.map);
        //TODO: layer.getLegend is too arbitrary - just takes last one from the each loop above
        $('#legend').append(layer.getLegend({
          numSegments: (max/10 > 5) ? 20 : 5,
          width: 80
        }));
      }
    },
    removeLayers: function() {
      var self = this;

      $.each(this.layers, function() {
        self.map.removeLayer(this);
      });
      $('#legend').empty();
    },
    geohashMax: function() {
      var _max,
      max = this.activity.aggregations.recordings.histogram.buckets.reduce(function(max, bucket) {
          _max = 0;
          if (bucket.geohash.buckets.length > 0) {
            _max = bucket.geohash.buckets.reduce(function(max2, inner_bucket) {
              return Math.max(max2, inner_bucket.doc_count);
            }, -Infinity);
          }
          return Math.max(max, _max);
        }, -Infinity);
      return max;
    },
    createGraph: function() {
      var self = this;
      $.ajax({
        url: '/images/graphs/' + this.id + '.dot',
        success: function(data) {
          var container = $('#social-graph')[0];
          var parsedData = vis.network.convertDot(data);
          var edges = $.map(parsedData.edges, function(n) {
            n['value'] = n.label;
            return n;
          });
          var data = {
                nodes: parsedData.nodes,
                edges: edges
              },
              options = {
                physics: {
                  stabilization: true
                },
                interaction: {
                  dragNodes: false
                },
                nodes: {
                  color: {
                    border: '#ccc'
                  }
                },
                edges: {
                  color: {
                    color: '#ccc'
                  },
                  scaling: {
                    min: 1,
                    max: 10,
                    label: false
                  }
                }
              };
          var network = new vis.Network(container, data, options);
          network.fit();
        },
        error: function() {
          $('#social-graph').height(0);
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
