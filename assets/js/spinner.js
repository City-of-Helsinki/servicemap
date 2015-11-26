(function() {
  define(['underscore', 'spin'], function(_, Spinner) {
    var SMSpinner;
    SMSpinner = (function() {
      var DEFAULTS;

      DEFAULTS = {
        lines: 12,
        length: 7,
        width: 5,
        radius: 10,
        rotate: 0,
        corners: 1,
        color: '#000',
        direction: 1,
        speed: 1,
        trail: 100,
        opacity: 1 / 4,
        fps: 20,
        zIndex: 2e9,
        className: 'spinner',
        top: '50%',
        left: '50%',
        position: 'absolute',
        hideContainerContent: false
      };

      function SMSpinner(options) {
        this.options = _.extend(DEFAULTS, options);
        this.container = this.options.container;
        this.finished = false;
      }

      SMSpinner.prototype.start = function() {
        if (this.finished) {
          return;
        }
        if (this.container) {
          if (this.options.hideContainerContent) {
            $(this.container).children().css('visibility', 'hidden');
          }
          return this.spinner = new Spinner(this.options).spin(this.container);
        }
      };

      SMSpinner.prototype.stop = function() {
        this.finished = true;
        if (this.container && this.spinner) {
          this.spinner.stop();
          if (this.options.hideContainerContent) {
            return $(this.container).children().css('visibility', 'visible');
          }
        }
      };

      return SMSpinner;

    })();
    return SMSpinner;
  });

}).call(this);

//# sourceMappingURL=spinner.js.map
