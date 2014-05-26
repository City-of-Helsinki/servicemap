define ->
    # Include the UserVoice JavaScript SDK (only needed once on a page)
    init = (locale) ->
        if locale == 'sv'
            locale = 'sv-SE'
        UserVoice = window.UserVoice or []
        window.UserVoice = UserVoice
        (->
          uv = document.createElement("script")
          uv.type = "text/javascript"
          uv.async = true
          uv.src = "//widget.uservoice.com/f5qbSk7oBie0rWE0W4ig.js"
          s = document.getElementsByTagName("script")[0]
          s.parentNode.insertBefore uv, s
          return
        )()

        # Set colors
        UserVoice.push [
          "set"
          {
            locale: locale
            accent_color: "#33a8ff"
            trigger_color: "white"
            post_idea_enabled: false
            smartvote_enabled: false
            screenshot_enabled: false
            trigger_background_color: "rgba(46, 49, 51, 0.6)"
          }
        ]

    # Or, use your own custom trigger:
    #UserVoice.push(['addTrigger', '#id', { mode: 'contact' }]);
    return init: init
