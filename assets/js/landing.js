(function() {
  define(function() {
    var clearLandingPage;
    clearLandingPage = function() {
      if ($('body').hasClass('landing')) {
        $('body').removeClass('landing');
        return $('#navigation-region').one('transitionend webkitTransitionEnd otransitionend oTransitionEnd MSTransitionEnd', function(event) {
          app.vent.trigger('landing-page-cleared');
          return $(this).off('transitionend webkitTransitionEnd oTransitionEnd MSTransitnd');
        });
      }
    };
    return {
      clear: clearLandingPage
    };
  });

}).call(this);

//# sourceMappingURL=landing.js.map
