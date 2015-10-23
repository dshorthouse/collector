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
      var self = this,
          container = $('#social-graph')[0],
          width = container.offsetWidth,
          height = container.offsetHeight,
          nominal_text_size = 10,
          max_text_size = 24,
          focus_node = null,
          highlight_node = null,
          highlight_color = "#3366cc";

      var zoom = d3.behavior.zoom().scaleExtent([0.5, 12]);

      var vis = d3.select("#social-graph")
          .append("svg")
          .style("cursor", "move")
          .attr("width", width)
          .attr("height", height)
          .attr("pointer-events", "all")
          .append('g')
          .call(zoom)
          .append('g');

      vis.append('rect')
          .attr('width', width)
          .attr('height', height)
          .attr('fill', 'white');

      var force = d3.layout.force()
          .charge(-250)
          .linkDistance(80)
          .size([width, height]);

      d3.json("/images/graphs/" + this.id + ".json", function(error, graph) {
        if (error) { throw error; }

        var linkedByIndex = {};
        var maxEdges = [];
        graph.edges.forEach(function(d) {
          linkedByIndex[d.source + "," + d.target] = d.value;
          if (d.source === 0) {
            maxEdges.push(d.value);
          }
        });

        var linearScale = d3.scale.sqrt().domain([1,d3.max(maxEdges)]).range([10,25]);

        function isConnected(a, b) {
          return linkedByIndex[a.index + "," + b.index] || linkedByIndex[b.index + "," + a.index] || a.index == b.index;
        }

        function set_highlight(d) {
          vis.style("cursor","pointer");
          labels.style("font-weight", function(o) {
            return (isConnected(d, o)) ? "bold" : "normal";
          });
          edge.style("stroke-opacity", function(o) {
            return (o.source.index == d.index || o.target.index == d.index) ? 1 : 0;
          });
          edgelabels.style("fill-opacity", function(o) {
            return (o.source.index == d.index || o.target.index == d.index) ? 1 : 0;
          });
        }

        function exit_highlight() {
          vis.style("cursor", "move");
          edge.style("stroke-opacity", 0);
          labels.style("font-weight", "normal");
          edgelabels.style("fill-opacity", 0);
        }

        force
            .nodes(graph.nodes)
            .links(graph.edges)
            .charge(function(d) {
              var charge = -500;
              if (d.index === 0) { charge = -1500; }
              return charge;
            })
            .start();

        var edge = vis.selectAll("line.link")
            .data(graph.edges)
            .enter().append("line")
            .attr("class", "edge")
            .style("stroke-width", function(d) { return Math.sqrt(Math.sqrt(d.value)); });

        var edgepaths = vis.selectAll(".edgepath")
            .data(graph.edges)
            .enter().append('path')
            .attr({'d': function(d) {return 'M '+d.source.x+' '+d.source.y+' L '+ d.target.x +' '+d.target.y},
                           'class':'edgepath',
                           'id':function(d,i) {return 'edgepath'+i}})
            .style("pointer-events", "none");

        var edgelabels = vis.selectAll(".edgelabel")
            .data(graph.edges)
            .enter().append('text')
            .style("pointer-events", "none")
            .attr({'class':'edgelabel',
                       'id':function(d,i){return 'edgelabel'+i},
                       'dx':80,
                       'dy':0,
                       'font-size':12});

        edgelabels.append('textPath')
            .attr('xlink:href',function(d,i) { return '#edgepath'+i })
            .style("pointer-events", "none")
            .text(function(d) { return d.value; });

        var gnodes = vis.selectAll("g.gnode")
            .data(graph.nodes)
            .enter().append('g')
            .classed('gnode', true);

        var node = gnodes.append("circle")
            .attr("class", "node")
            .attr("r", function(d) {
              return (d.id === self.id) ? 14 : linkedByIndex["0,"+d.index] ? linearScale(linkedByIndex["0,"+d.index]) : 10;
            })
            .style("fill", function(d) {
              return (d.id === self.id) ? highlight_color : (d.gender === "male") 
                                        ? "lightskyblue" : (d.gender === "female") 
                                        ? "lightpink" : "lightgrey";
            })
            .on("mouseover", function(d) {
              set_highlight(d);
            })
            .on("mouseout", function() {
              exit_highlight();
            })
            .call(force.drag);

        var labels = gnodes.append("text")
            .text(function(d) { return d.name; })
            .attr("font-size", function(d) { return (d.id === self.id) ? max_text_size + "px" : nominal_text_size + "px"; });

        node.append("title")
            .text(function(d) { return d.name; });

        zoom.on("zoom", function() {
          var text_size = nominal_text_size;
          if (nominal_text_size * zoom.scale() > max_text_size) {
            text_size = max_text_size/zoom.scale();
          }
          labels.attr("font-size", function(d) { return (d.id === self.id) ? max_text_size/zoom.scale() + "px" : text_size + "px"; });
          vis.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");
        });

        vis.style("opacity", 1e-6)
          .transition()
          .duration(1000)
          .style("opacity", 1);

        force.on("tick", function() {
          edge.attr("x1", function(d) { return d.source.x; })
              .attr("y1", function(d) { return d.source.y; })
              .attr("x2", function(d) { return d.target.x; })
              .attr("y2", function(d) { return d.target.y; });
          edgepaths.attr('d', function(d) { var path='M '+d.source.x+' '+d.source.y+' L '+ d.target.x +' '+d.target.y;
              return path;
          });
          edgelabels.attr('transform',function(d,i) {
              if (d.target.x < d.source.x) {
                var bbox = this.getBBox(),
                    rx = bbox.x+bbox.width/2,
                    ry = bbox.y+bbox.height/2;
                return 'rotate(180 '+rx+' '+ry+')';
              }
              else {
                return 'rotate(0)';
              }
          });
          gnodes.attr("transform", function(d) { 
            return 'translate(' + [d.x, d.y] + ')';
          });
        });

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
    init: function(id) {
      _private.init(id);
    }
  };

}(jQuery, window));
