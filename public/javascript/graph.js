/*global window, document, jQuery, google, L */
var Graph = (function($, window) {

  "use strict";

  var _private = {

    init: function(id) {
      this.createGraph();
    },
    createGraph: function() {
      var self = this,
          container = $('#social-graph-large')[0],
          width = container.offsetWidth,
          height = container.offsetHeight,
          nominal_text_size = 4,
          max_text_size = 24;

      var zoom = d3.behavior.zoom().scaleExtent([0.1, 10]);

      var vis = d3.select("#social-graph-large")
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
          .linkDistance(5)
          .size([width, height]);

      d3.json("/images/graphs/graph.json", function(error, graph) {
        if (error) { throw error; }

        var linearScale = d3.scale.linear().domain([1,5000]).range([1,3]);

        force
            .nodes(graph.nodes)
            .links(graph.edges)
            .charge(-500)
            .start();

        var edge = vis.selectAll("line.link")
            .data(graph.edges)
            .enter().append("line")
            .attr("class", "edges")
            .style("stroke-width", function(d) { return linearScale(d.value); });

        var gnodes = vis.selectAll("g.gnode")
            .data(graph.nodes)
            .enter().append('g')
            .classed('gnode', true);

        var node = gnodes.append("circle")
            .attr("class", "node")
            .attr("r", 10)
            .style("fill", function(d) {
              return (d.gender === "male") ? "lightskyblue" : (d.gender === "female") 
                                        ? "lightpink" : "lightgrey";
            })
            .call(force.drag);

        var labels = gnodes.append("text")
            .text(function(d) { return d.name; })
            .attr("font-size", nominal_text_size + "px");

        node.append("title")
            .text(function(d) { return d.name; });

        zoom.on("zoom", function() {
          var text_size = nominal_text_size;
          if (nominal_text_size * zoom.scale() > max_text_size) {
            text_size = max_text_size/zoom.scale();
          }
          labels.attr("font-size", text_size + "px");
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
          gnodes.attr("transform", function(d) { 
            return 'translate(' + [d.x, d.y] + ')';
          });
        });

      });
    }
  };

  return {
    init: function(id) {
      _private.init(id);
    }
  };

}(jQuery, window));