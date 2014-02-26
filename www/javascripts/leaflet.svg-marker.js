L.SVGMarker = L.Path.extend({
  initialize: function(latlng, options) {
    L.Path.prototype.initialize.call(this, options);
    this._svg = options.svg;
    this._afterwards = options.afterwards;
    if (this._svg.indexOf("<") === 0) {
        this._data = this._svg;
    }
    this._latlng = latlng;
  },
  projectLatlngs: function() {
    this._point = this._map.latLngToLayerPoint(this._latlng);
  },
  setLatLng: function(latlng) {
    this._latlng = latlng;
    this.redraw();
  },
  getLatLng: function() {
    return this._latlng;
  },
  getPathString: function() {
    var me = this;
    var addSVG = function() {
      var g = me._path.parentNode;
      while (g.nodeName.toLowerCase() !== "g") {
          g = g.parentNode;
      }
      if (me.options.clickable) {
          g.setAttribute("class", "leaflet-clickable");
      }
      var data = me._data;
      var svg = data.nodeName.toLowerCase() === "svg" ? data.cloneNode(true) : data.querySelector("svg").cloneNode(true);
      if (me.options.setStyle) {
        me.options.setStyle.call(me, svg);
      }
      var elementWidth = svg.getAttribute("width");
      var elementHeight = svg.getAttribute("height");
      var width = elementWidth ? elementWidth.replace("px", "") : "100%";
      var height = elementHeight ? elementHeight.replace("px", "") : "100%";
      if (width === "100%") {
        width = me.options.size.x;
        height = me.options.size.y;
        svg.setAttribute("width", width);
        svg.setAttribute("height", height + ((height+"").indexOf("%") !== -1 ? "" : "px"));
      }
      var size = me.options.size || new L.Point(width, height);
      var scaleSize = new L.Point(size.x / width, size.y / height);
      var old = g.getElementsByTagName("svg");
      if (old.length > 0) {
        old[0].parentNode.removeChild(old[0]);
      }
      g.appendChild(svg);
      var transforms = [];
      var anchor = me.options.anchor || new L.Point(-size.x / 2, -size.y / 2);
      var x = me._point.x + anchor.x;
      var y = me._point.y + anchor.y;
      transforms.push("translate(" + x + " " + y + ")");
      transforms.push("scale(" + scaleSize.x + " " + scaleSize.y + ")");
      if (me.options.rotation) {
        transforms.push("rotate(" + me.options.rotation + " " + width / 2 + " " + height / 2 + ")");
      }
      g.setAttribute("transform", transforms.join(" "));

      // Execute custom code
      if (me._afterwards !== undefined && me._afterwards !== null) {
        me._afterwards(g);
      }
    };
    if (!this._data) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
                me._data = this.responseXML;
                addSVG();
            }
        };
        xhr.open("GET", this._svg, true);
        xhr.send(null);
    } else {
        addSVG();
    }
  }
});