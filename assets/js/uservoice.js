(function() {
  define(function() {
    var init;
    init = function(locale) {
      var UserVoice;
      if (locale === 'sv') {
        locale = 'sv-SE';
      }
      UserVoice = window.UserVoice || [];
      window.UserVoice = UserVoice;
      (function() {
        var s, uv;
        uv = document.createElement("script");
        uv.type = "text/javascript";
        uv.async = true;
        uv.src = "//widget.uservoice.com/f5qbSk7oBie0rWE0W4ig.js";
        s = document.getElementsByTagName("script")[0];
        s.parentNode.insertBefore(uv, s);
      })();
      return UserVoice.push([
        "set", {
          locale: locale,
          accent_color: "#1964e6",
          trigger_color: "white",
          post_idea_enabled: false,
          smartvote_enabled: false,
          screenshot_enabled: false,
          trigger_background_color: "rgba(46, 49, 51, 0.6)"
        }
      ]);
    };
    return {
      init: init
    };
  });

}).call(this);

//# sourceMappingURL=uservoice.js.map
