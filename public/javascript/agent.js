/*global window, document, jQuery, google, L */

var Agent = (function($, window) {

  "use strict";

  var _private = {

    id: "",
    graph: {
      nodes: [],
      edges: []
    },
    activity: { hits: { total: "" }, aggregations: { determinations: { buckets: [] }, recordings: { buckets: [] } } },
    chartData: { determinations : [["Year", "Identifications"]], recordings : [["Year", "Collected specimens"]]},
    map: {},
    layers: [],

    init: function(id, graph) {
      this.id = id;
      this.getActivity();
      this.createCharts();
      this.createMap();
      if(graph) {
        this.graph = graph;
        this.createGraph();
      }
      this.enableEdit();
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

      if(this.activity.aggregations.determinations.buckets.length > 0) {
        $.each(this.activity.aggregations.determinations.buckets, function() {
          self.chartData.determinations.push([this.key_as_string, this.doc_count]);
        });
      }
      if(this.activity.aggregations.recordings.buckets.length > 0) {
        $.each(this.activity.aggregations.recordings.buckets, function() {
          self.chartData.recordings.push([this.key_as_string, this.doc_count]);
        });
      }
      if(this.chartData.determinations.length > 1) {
        google.setOnLoadCallback(function() { self.drawCharts(self.chartData.determinations, 'determinations'); });
        $('#determinations').show();
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
        if(self.activity.aggregations.recordings.buckets.length > 0) {
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

      $.each(this.activity.aggregations.recordings.buckets, function() {
        if (this.geohash.buckets.length > 0) {
          layer = new L.DataLayer(this.geohash, options);
          self.map.addLayer(layer);
          self.layers.push(layer);
        }
      });
      if(this.layers.length > 0) {
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
      max = this.activity.aggregations.recordings.buckets.reduce(function(max, bucket) {
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
      var self = this,
          container = $('#social-graph')[0],
          options = {
            nodes: {
              shape: 'dot',
              scaling: {
                min: 10,
                max: 30
              },
              size: 10,
              font: {
                size: 8
              }
            },
            edges: {
              width: 0.15,
              font: {
                size: 8
              },
              smooth: {
                type: 'dynamic'
              }
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
          data = {},
          node_color = {},
          network = {},
          parsed = "";

          if(this.graph.nodes.length >= 50) {
            options['edges']['smooth']['type'] = 'continuous';
          }

      $.map(this.graph.nodes, function(n) {
        if(n["gender"] == "female") {
          n["color"] = { background: "pink", highlight: { background: "#FFE4E1" } };
        }
        if(n["id"] == self.id) {
          n["color"] = { background: "#FFFF33", highlight: { background: "#FFFF99" } };
        }
        return n;
      });
      network = new vis.Network(container, this.graph, options);
      network.on("showPopup", function(params) {
        $(container).css("cursor", "pointer");
      });
      network.on("hidePopup", function(params) {
        $(container).css("cursor", "normal");
      });
      network.on("selectNode", function(params) {
        if(self.id !== params["nodes"][0]) {
          window.location.href = "/agent/" + params["nodes"][0];
        }
      });
    },
    enableEdit: function() {
      var self = this, obj = {};

      $('#agent-title span')
        .on("blur", function() {
          obj[$(this).attr("data")] = $(this).text();
          $.ajax({
            type : 'PUT',
            data : JSON.stringify(obj),
            url  : '/agent/' + self.id,
            dataType : 'json',
            success : function(response) {
            },
            error : function(xhr, ajaxOptions, thrownError) {
              alert(xhr.responseText);
            }
          });
        })
        .on('keydown', function(e) {
          var code = e.keyCode || e.which;
          if(code === 13 || code === 40) {
            e.preventDefault();
            $(this).next().focus();
          }
        });
    }
  };

  return {
    init: function(id, graph) {
      _private.init(id, graph);
    }
  };

}(jQuery, window));