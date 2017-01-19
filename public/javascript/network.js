jQuery.expr[":"].icontains = jQuery.expr.createPseudo(function (arg) {
    return function (elem) {
        return jQuery(elem).text().toUpperCase().indexOf(arg.toUpperCase()) >= 0;
    };
});

/*global jQuery, window, document, self, encodeURIComponent, google, Bloodhound */
var Network = (function($, window) {

  "use strict";

  var _private = {

    svg: { obj: {}, size: {}, nodes: []},
    data_sources: { agent : {} },
    panZoom: {},
    search_cache: [],

    init: function() {
      this.bloodhound();
      this.typeahead();
      this.appendSVG();
    },
    bloodhound: function() {
      this.data_sources.agent = this.create_bloodhound('agent');
      this.data_sources.agent.initialize();
    },
    create_bloodhound: function(type) {
      return new Bloodhound({
        datumTokenizer : Bloodhound.tokenizers.whitespace,
        queryTokenizer : Bloodhound.tokenizers.whitespace,
        sufficient : 10,
        remote : {
          url : '/'+type+'.json?q=%QUERY',
          wildcard : '%QUERY',
          transform : function(r) { return $.map(r, function(v) { v['type'] = type; return v; });  }
        }
      });
    },
    typeahead: function(){
      var self = this;
      $('#typeahead-agent').typeahead({
          minLength: 3,
          highlight: true
        },
        {
          name: 'agent',
          source : this.data_sources.agent.ttAdapter(),
          display : 'fullname'
        }
        ).on('typeahead:select', function(obj, datum) {
          self.executeSearch(datum.fullname);
        }).bind('blur keyup', function(e) {
          if (e.type == 'blur' || e.keyCode == '13') {
            self.executeSearch(e.target.value);
          }
        });
    },
    appendSVG: function(){
      var self = this;
      this.svg.obj = document.createElement('object');
      this.svg.obj.setAttribute('style', 'width: 95%; height: 100%; border:1px solid black;');
      this.svg.obj.setAttribute('type', 'image/svg+xml');
      this.svg.obj.setAttribute('data', '/images/collector-network.svg');
      $('#svg-container').append(this.svg.obj);
      this.svg.obj.addEventListener('load', function() { self.svgEventListener(); });
    },
    svgEventListener: function(){
      var self = this;
      this.panZoom = svgPanZoom(this.svg.obj, {
        zoomEnabled: true,
        controlIconsEnabled: true,
        fit: true,
        center: true
      });
      this.svg.size = this.panZoom.getSizes();
      this.svg.nodes = $("g.node", this.svg.obj.contentDocument.documentElement).toArray();
      $(window).resize(function() {
        self.panZoom.resize();
        self.panZoom.fit();
        self.panZoom.center();
        self.svg.size = self.panZoom.getSizes();
      });
    },
    executeSearch: function(search) {
      var self = this, ellipse, mean_pt_width, mean_pt_height, center, pixel_ratio, white_space, x_arr, max, min;
      if (this.search_cache.length > 0) {
        $.each(this.search_cache, function() {
          this.ellipse.setAttribute("fill", this.fill);
          this.ellipse.setAttribute("stroke", this.stroke);
          this.ellipse.setAttribute("stroke-width", 1);
        });
        this.search_cache = [];
      }
      $.each(this.svg.nodes, function() {
        if (search != "" && $(this).find("title:icontains('"+search+"')").length) {
          ellipse = $(this).find("ellipse")[0];
          self.search_cache.push(
            { 
              ellipse: ellipse, 
              fill: ellipse.getAttribute("fill"), 
              stroke: ellipse.getAttribute("stroke"),
              cx: parseInt(ellipse.getAttribute("cx"), 10),
              cy: parseInt(ellipse.getAttribute("cy"),10)
            }
          );
          ellipse.setAttribute("fill", '#ffff00');
          ellipse.setAttribute("stroke", '#ff0000');
          ellipse.setAttribute("stroke-width", 5);
        }
      });
      if(search != "" && this.search_cache.length > 0) {
        this.panZoom.resize();
        this.panZoom.fit();
        this.panZoom.center();
        mean_pt_width = this.search_cache.reduce(function(a, b) { return a + b.cx; }, 0)/this.search_cache.length;
        mean_pt_height = Math.abs(this.search_cache.reduce(function(a, b) { return a + b.cy; }, 0)/this.search_cache.length);
        center = { x: this.svg.size.viewBox.width/2, y: this.svg.size.viewBox.height/2 };
        pixel_ratio = this.svg.size.height/this.svg.size.viewBox.height;
        white_space = (this.svg.size.width - this.svg.size.viewBox.width*pixel_ratio)/2;
        this.panZoom.pan({x: (center.x - mean_pt_width)*pixel_ratio + white_space, y: (mean_pt_height - center.y)*pixel_ratio});
        if (this.search_cache.length > 1) {
          x_arr = this.search_cache.map(function(a) { return a.cx; });
          max = Math.max.apply(Math,x_arr);
          min = Math.min.apply(Math,x_arr);
          this.panZoom.zoom(parseInt(this.svg.size.viewBox.width/(max-min),10));
        } else {
          this.panZoom.zoom(7);
        }
      }
    }
  };

  return {
    init: function() {
      _private.init();
    }
  };

}(jQuery, window));
