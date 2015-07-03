/*global jQuery, window, document, self, encodeURIComponent, google, Bloodhound */
var Collector = (function($, window) {

  "use strict";

  var _private = {

    data_sources: { agent : {}, taxon : {} },
    map: {},
    layer: {},

    init: function() {
      this.bloodhound();
      this.typeahead();
      this.createMap();
      this.addMapEvents();
      this.loadOverlay();
      this.activateReset();
    },
    bloodhound: function() {
      this.data_sources.agent = this.create_bloodhound('agent');
      this.data_sources.agent.initialize();
      this.data_sources.taxon = this.create_bloodhound('taxon');
      this.data_sources.taxon.initialize();
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
      $('#typeahead-agent').typeahead({
          minLength: 3,
          highlight: true
        },
        {
          name: 'agent',
          source : this.data_sources.agent.ttAdapter(),
          display : 'name'
        }
        ).on('typeahead:select', function(obj, datum) {
          var id = datum.id;
          if(datum.orcid) {
            id = datum.orcid;
          }
          window.location.href = '/agent/' + id;
        });
        $('#typeahead-taxon').typeahead({
            minLength: 3,
            highlight: true
          },
          {
            name: 'taxon',
            source : this.data_sources.taxon.ttAdapter(),
            display : 'name'
          }
        );
    },
    getParameterByName: function(name) {
        name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");
        var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
            results = regex.exec(window.location.search);
        return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
    },
    dropdown_selected: function(){
      window.location.href = '/?q='+encodeURIComponent($(this).val());
    },
    createMap: function() {
      var self = this, baseLayer, drawControl;

      this.map = L.map('map').setView([55.0, -100.0], 3);
      baseLayer = new L.StamenTileLayer('toner-lite', {
        detectRetina: true
      });
      baseLayer.addTo(this.map);

      drawControl = new L.Control.Draw({
          draw: {
              polyline: false,
              marker: false,
              polygon: {
                shapeOptions: {
                  color: '#246d80'
                }
              },
              rectangle: {
                shapeOptions: {
                  color: '#246d80'
                }
              },
              circle: {
                shapeOptions: {
                  color: '#246d80'
                }
              }
          }
      });
      this.map.addControl(drawControl);
    },
    addMapEvents: function() {
      var self = this;

      this.map.on('draw:drawstart', function (e) {
        self.clearOverlays();
      });

      this.map.on('draw:created', function (e) {
        var type = e.layerType, layer = e.layer, center, radius, bounds, polygon;

        self.layer = layer;
        $('#geo_type').val(type);

        switch(type) {
          case 'circle':
            center = layer.getLatLng().lat + "," + layer.getLatLng().lng;
            radius = layer.getRadius()/1000;
            $('#geo_center').val(center);
            $('#geo_radius').val(radius);
          break;

          case 'rectangle':
            bounds = layer.getLatLngs();
            $('#geo_bounds').val(bounds[0].lat + "," + bounds[0].lng + "," + bounds[2].lat + "," + bounds[2].lng);
          break;

          case 'polygon':
            polygon = $.map(layer.getLatLngs(), function(a) {
              return '['+[a.lat, a.lng].toString()+']';
            });
            $('#geo_polygon').val('['+polygon.toString()+']');
          break;
        }

        self.map.addLayer(layer);
      });
    },
    loadOverlay: function() {
      var geo = this.getParameterByName('geo'),
        coord, radius, bbox, bounds, vertices;

        switch(geo) {
          case 'circle':
            coord = this.getParameterByName("c").split(",");
            radius = this.getParameterByName("r")*1000
            this.layer = L.circle(coord, radius, { color: "#246d80" });
            this.map.addLayer(this.layer);
            this.map.setView(coord, 3)
          break;

          case 'rectangle':
            bbox = this.getParameterByName("b").split(",");
            bounds = [[bbox[0],bbox[1]],[bbox[2],bbox[3]]];
            this.layer = L.rectangle(bounds, { color: "#246d80" });
            this.map.addLayer(this.layer);
            this.map.setView(this.layer.getBounds().getCenter(), 3);
          break;

          case 'polygon':
            vertices = JSON.parse(this.getParameterByName("p"));
            this.layer = L.polygon(vertices, { color: "#246d80" });
            this.map.addLayer(this.layer);
            this.map.setView(this.layer.getBounds().getCenter(), 3);
          break;
        }
      },
      clearOverlays: function() {
        var self = this;

        $.each(['type', 'center', 'radius', 'bounds', 'polygon'], function() {
          $('#geo_' + this).val('');
          self.map.removeLayer(self.layer);
        });
      },
      activateReset: function() {
        var self = this;
        $('#reset_form').on('click', function() {
          self.clearOverlays();
          $(':input').not(':button, :submit, :reset, :hidden').val('');
          $('#typeahead-agent').typeahead('val', '');
          $('#typeahead-taxon').typeahead('val', '');
        });
      }
  };

  return {
    init: function() {
      _private.init();
    }
  };

}(jQuery, window));
