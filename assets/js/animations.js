(function() {
  define(['TweenLite'], function(TweenLite) {
    var DURATION_IN_SECONDS, HORIZONTAL_MARGIN, getMoveDistanceInPx, getStartingLeft, getStartingTop, render;
    HORIZONTAL_MARGIN = 4;
    DURATION_IN_SECONDS = 0.3;
    getStartingLeft = function(contentWidth, animation) {
      switch (animation) {
        case 'left':
          return contentWidth + HORIZONTAL_MARGIN;
        case 'right':
          return -contentWidth - HORIZONTAL_MARGIN;
        default:
          return 0;
      }
    };
    getStartingTop = function(contentHeight, animation) {
      switch (animation) {
        case 'left':
          return -contentHeight;
        case 'right':
          return -contentHeight;
        default:
          return 0;
      }
    };
    getMoveDistanceInPx = function(distance, animation) {
      switch (animation) {
        case 'left':
          return "-=" + distance + "px";
        case 'right':
          return "+=" + distance + "px";
        default:
          return 0;
      }
    };
    render = function($container, $oldContent, $newContent, animation, callback) {
      var contentHeight, contentWidth, moveDistance;
      $container.append($newContent);
      contentHeight = $oldContent.height();
      contentWidth = $oldContent.width();
      moveDistance = getMoveDistanceInPx(contentWidth + HORIZONTAL_MARGIN, animation);
      $newContent.css({
        'position': 'relative',
        'left': getStartingLeft(contentWidth, animation),
        'top': getStartingTop(contentHeight, animation)
      });
      $oldContent.css({
        'position': 'relative'
      });
      return TweenLite.to([$oldContent, $newContent], DURATION_IN_SECONDS, {
        left: moveDistance,
        ease: Power2.easeOut,
        onComplete: function() {
          $oldContent.remove();
          $newContent.css({
            'left': 0,
            'top': 0
          });
          return typeof callback === "function" ? callback() : void 0;
        }
      });
    };
    return {
      render: render
    };
  });

}).call(this);

//# sourceMappingURL=animations.js.map
