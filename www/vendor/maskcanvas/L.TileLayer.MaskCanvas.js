L.TileLayer.MaskCanvas = L.TileLayer.Canvas.extend({
    options: {
        radius: 5,
        color: '#000',
        opacity: 0.5,
        noMask: false,  // true results in normal (filled) circled, instead masked circles
        lineColor: undefined,  // color of the circle outline if noMask is true
        debug: false
    },

    initialize: function (options, data) {
        var self = this;
        L.Util.setOptions(this, options);

        this.drawTile = function (tile, tilePoint, zoom) {
            var ctx = {
                canvas: tile,
                tilePoint: tilePoint,
                zoom: zoom
            };

            if (self.options.debug) {
                self._drawDebugInfo(ctx);
            }
            this._draw(ctx);
        };
    },

    _drawDebugInfo: function (ctx) {
        var max = this.tileSize;
        var g = ctx.canvas.getContext('2d');
        g.globalCompositeOperation = 'destination-over';
        g.strokeStyle = '#000000';
        g.fillStyle = '#FFFF00';
        g.strokeRect(0, 0, max, max);
        g.font = "12px Arial";
        g.fillRect(0, 0, 5, 5);
        g.fillRect(0, max - 5, 5, 5);
        g.fillRect(max - 5, 0, 5, 5);
        g.fillRect(max - 5, max - 5, 5, 5);
        g.fillRect(max / 2 - 5, max / 2 - 5, 10, 10);
        g.strokeText(ctx.tilePoint.x + ' ' + ctx.tilePoint.y + ' ' + ctx.zoom, max / 2 - 30, max / 2 - 10);
    },


    _oldCreateTile: function () {
        var tile = this._canvasProto.cloneNode(false);
        tile.onselectstart = tile.onmousemove = L.Util.falseFn;
        return tile;
    },

    // dataset <GeoJSON>
    setData: function(dataset) {
        var self = this;

        self._maxRadius = Number.MIN_VALUE;

        latlngs = [];
        dataset.features.forEach(function(d) {
            latlngs.push([d.geometry.coordinates[1], d.geometry.coordinates[0]]);
        });

        this.bounds = new L.LatLngBounds(latlngs);
        this._quad = new QuadTree(this._boundsToQuery(this.bounds), false, 6, 6);

        dataset.features.forEach(function(d) {
            self._maxRadius = Math.max(self._maxRadius, d.properties.radius);
            self._quad.insert({
                x: d.geometry.coordinates[0], //lng
                y: d.geometry.coordinates[1], //lat
                r: d.properties.radius
            });
        });

        if (this._map) {
            this.redraw();
        }
    },

    setRadius: function(radius) {
        this.options.radius = radius;
        this.redraw();
    },

    _tilePoint: function (ctx, coords) {
        // start coords to tile 'space'
        var s = ctx.tilePoint.multiplyBy(this.options.tileSize);

        // actual coords to tile 'space'
        var p = this._map.project(new L.LatLng(coords.y, coords.x));

        // point to draw
        var x = Math.round(p.x - s.x);
        var y = Math.round(p.y - s.y);
        return [x, y];
    },

    _drawPoints: function (ctx, coordinates) {
        var c = ctx.canvas,
            g = c.getContext('2d'),
            self = this,
            p,
            tileSize = this.options.tileSize;
        g.fillStyle = this.options.color;

        if (this.options.lineColor) {
          g.strokeStyle = this.options.lineColor;
          g.lineWidth = this.options.lineWidth || 1;
        }
        g.globalCompositeOperation = 'source-over';
        if (!this.options.noMask) {
            g.fillRect(0, 0, tileSize, tileSize);
            g.globalCompositeOperation = 'destination-out';
        }
        coordinates.forEach(function(coords) {
            p = self._tilePoint(ctx, coords);
            g.beginPath();
            g.arc(p[0], p[1], self.projectRadius(coords.r), 0, Math.PI * 2);
            g.fill();
            if (self.options.lineColor) {
                g.stroke();
            }
        });
    },

    _boundsToQuery: function(bounds) {
        if (bounds.getSouthWest() == undefined) { return {x: 0, y: 0, width: 0.1, height: 0.1}; }  // for empty data sets
        return {
            x: bounds.getSouthWest().lng,
            y: bounds.getSouthWest().lat,
            width: bounds.getNorthEast().lng-bounds.getSouthWest().lng,
            height: bounds.getNorthEast().lat-bounds.getSouthWest().lat
        };
    },

    projectRadius: function(r) {
        var ll, ll2, lr, point, radius;
        ll = this._latlng;
        lr = (r / 40075017) * 360 / Math.cos(L.LatLng.DEG_TO_RAD * ll.lat);
        ll2 = new L.LatLng(ll.lat, ll.lng - lr);
        return this._map.latLngToLayerPoint(ll).x - this._map.latLngToLayerPoint(ll2).x;
    },

    _draw: function (ctx) {
        if (!this._quad || !this._map) {
            return;
        }

        var tileSize = this.options.tileSize;

        var nwPoint = ctx.tilePoint.multiplyBy(tileSize);
        var sePoint = nwPoint.add(new L.Point(tileSize, tileSize));
        var centerPoint = nwPoint.add(new L.Point(tileSize/2, tileSize/2));
        
        this._latlng = this._map.unproject(centerPoint);

        // padding
        var pad = new L.Point(this.projectRadius(this._maxRadius), this.projectRadius(this._maxRadius));
        nwPoint = nwPoint.subtract(pad);
        sePoint = sePoint.add(pad);

        var bounds = new L.LatLngBounds(this._map.unproject(sePoint), this._map.unproject(nwPoint));

        var coordinates = this._quad.retrieveInBounds(this._boundsToQuery(bounds));

        this._drawPoints(ctx, coordinates);
    }
});

L.TileLayer.maskCanvas = function(options) {
    var mc = new L.TileLayer.MaskCanvas(options);
    leafletVersion = parseInt(L.version.match(/\d{1,}\.(\d{1,})\.\d{1,}/)[1], 10);
    if (leafletVersion < 7) mc._createTile = mc._oldCreateTile;
    return mc;
};