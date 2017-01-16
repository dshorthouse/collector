jQuery.expr[":"].icontains = jQuery.expr.createPseudo(function (arg) {
    return function (elem) {
        return jQuery(elem).text().toUpperCase().indexOf(arg.toUpperCase()) >= 0;
    };
});

$(function() {
  var obj = document.createElement('object'), panZoom, search, lastEventListener, nodes, node_arr, node, ellipse, search_cache = [];
  obj.setAttribute('style', 'width: 95%; height: 100%; border:1px solid black;');
  obj.setAttribute('type', 'image/svg+xml');
  obj.setAttribute('data', '/images/collector-network.svg');

  document.getElementById('container').appendChild(obj);

  lastEventListener = function(){
    panZoom = svgPanZoom(obj, {
      zoomEnabled: true,
      controlIconsEnabled: true,
      fit: true,
      center: true
    });
    nodes = $("g.node", obj.contentDocument.documentElement).toArray();

    $('#search-box').bind('blur keyup', function(e) {
      if (e.type == 'blur' || e.keyCode == '13') {
        search = $(this).val();
        if (search_cache.length > 0) {
          $.each(search_cache, function() {
            this.ellipse.setAttribute("fill", this.fill);
            this.ellipse.setAttribute("stroke", this.stroke);
            this.ellipse.setAttribute("stroke-width", 1);
          });
          search_cache = [];
        }
        $.each(nodes, function() {
          if (search != "" && $(this).find("title:icontains('"+search+"')").length) {
            ellipse = $(this).find("ellipse")[0];
            search_cache.push({ ellipse: ellipse, fill: ellipse.getAttribute("fill"), stroke: ellipse.getAttribute("stroke") });
            ellipse.setAttribute("fill", '#ffff00');
            ellipse.setAttribute("stroke", '#ff0000');
            ellipse.setAttribute("stroke-width", 5);
          }
        });
      }
    });
  };
  obj.addEventListener('load', lastEventListener);

  $(window).resize(function() {
    panZoom.resize();
    panZoom.fit();
    panZoom.center();
  });

});