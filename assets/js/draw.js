(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(function() {
    var Berry, CanvasDrawer, Plant, PointCluster, PointPlant, Stem, drawSimpleBerry, exports;
    CanvasDrawer = (function() {
      function CanvasDrawer() {}

      CanvasDrawer.prototype.referenceLength = 4500;

      CanvasDrawer.prototype.strokePath = function(c, callback) {
        c.beginPath();
        callback(c);
        c.stroke();
        return c.closePath();
      };

      CanvasDrawer.prototype.dim = function(part) {
        return this.ratio * this.defaults[part];
      };

      return CanvasDrawer;

    })();
    Stem = (function(_super) {
      __extends(Stem, _super);

      function Stem(size, rotation) {
        this.size = size;
        this.rotation = rotation;
        this.ratio = this.size / this.referenceLength;
      }

      Stem.prototype.defaults = {
        width: 250,
        base: 370,
        top: 2670,
        control: 1030
      };

      Stem.prototype.startingPoint = function() {
        return [this.size / 2, this.size];
      };

      Stem.prototype.berryCenter = function(rotation) {
        var x, y;
        rotation = Math.PI * rotation / 180;
        x = 0.8 * Math.cos(rotation) * this.dim('top') + (this.size / 2);
        y = -Math.sin(rotation) * this.dim('top') + this.size - this.dim('base');
        return [x, y];
      };

      Stem.prototype.setup = function(c) {
        c.lineJoin = 'round';
        c.strokeStyle = '#333';
        c.lineCap = 'round';
        return c.lineWidth = this.dim('width');
      };

      Stem.prototype.draw = function(c) {
        var point;
        this.setup(c);
        c.fillStyle = '#000';
        point = this.startingPoint();
        this.strokePath(c, (function(_this) {
          return function(c) {
            var controlPoint;
            c.moveTo.apply(c, point);
            point[1] -= _this.dim('base');
            c.lineTo.apply(c, point);
            controlPoint = point;
            controlPoint[1] -= _this.dim('control');
            point = _this.berryCenter(_this.rotation);
            return c.quadraticCurveTo.apply(c, __slice.call(controlPoint).concat(__slice.call(point)));
          };
        })(this));
        return point;
      };

      return Stem;

    })(CanvasDrawer);
    Berry = (function(_super) {
      __extends(Berry, _super);

      function Berry(size, point, color) {
        this.size = size;
        this.point = point;
        this.color = color;
        this.ratio = this.size / this.referenceLength;
      }

      Berry.prototype.draw = function(c) {
        var oldComposite;
        c.beginPath();
        c.fillStyle = this.color;
        c.arc.apply(c, __slice.call(this.point).concat([this.defaults.radius * this.ratio], [0], [2 * Math.PI]));
        c.fill();
        if (!(getIeVersion() && getIeVersion() < 9)) {
          c.strokeStyle = 'rgba(0,0,0,1.0)';
          oldComposite = c.globalCompositeOperation;
          c.globalCompositeOperation = "destination-out";
          c.lineWidth = 1.5;
          c.stroke();
          c.globalCompositeOperation = oldComposite;
        }
        c.closePath();
        c.beginPath();
        c.arc.apply(c, __slice.call(this.point).concat([this.defaults.radius * this.ratio - 1], [0], [2 * Math.PI]));
        c.strokeStyle = '#fcf7f5';
        c.lineWidth = 1;
        c.stroke();
        return c.closePath();
      };

      Berry.prototype.defaults = {
        radius: 1000,
        stroke: 125
      };

      return Berry;

    })(CanvasDrawer);
    Plant = (function(_super) {
      __extends(Plant, _super);

      function Plant(size, color, id, rotation, translation) {
        this.size = size;
        this.color = color;
        this.rotation = rotation != null ? rotation : 70 + (id % 40);
        this.translation = translation != null ? translation : [0, -3];
        this.stem = new Stem(this.size, this.rotation);
      }

      Plant.prototype.draw = function(context) {
        var berryPoint, _ref;
        this.context = context;
        this.context.save();
        (_ref = this.context).translate.apply(_ref, this.translation);
        berryPoint = this.stem.draw(this.context);
        this.berry = new Berry(this.size, berryPoint, this.color);
        this.berry.draw(this.context);
        return this.context.restore();
      };

      return Plant;

    })(CanvasDrawer);
    drawSimpleBerry = function(c, x, y, radius, color) {
      c.fillStyle = color;
      c.beginPath();
      c.arc(x, y, radius, 0, 2 * Math.PI);
      return c.fill();
    };
    PointCluster = (function(_super) {
      __extends(PointCluster, _super);

      function PointCluster(size, colors, positions, radius) {
        this.size = size;
        this.colors = colors;
        this.positions = positions;
        this.radius = radius;
        this.draw = __bind(this.draw, this);
      }

      PointCluster.prototype.draw = function(c) {
        return _.each(this.positions, (function(_this) {
          return function(pos) {
            return drawSimpleBerry.apply(null, [c].concat(__slice.call(pos), [_this.radius], ["#000"]));
          };
        })(this));
      };

      return PointCluster;

    })(CanvasDrawer);
    PointPlant = (function(_super) {
      __extends(PointPlant, _super);

      function PointPlant(size, color, radius) {
        this.size = size;
        this.color = color;
        this.radius = radius;
        this.draw = __bind(this.draw, this);
        true;
      }

      PointPlant.prototype.draw = function(c) {
        return drawSimpleBerry(c, 10, 10, this.radius, "#f00");
      };

      return PointPlant;

    })(CanvasDrawer);
    exports = {
      Plant: Plant,
      PointCluster: PointCluster,
      PointPlant: PointPlant
    };
    return exports;
  });

}).call(this);

//# sourceMappingURL=draw.js.map
