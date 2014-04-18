# Personalization support code

define ->
    class ServiceMapPersonalization
        get_language: ->
            return 'en'

        get_translated_attr: (val) ->
            if not val
                return val

            if not val instanceof Object
                console.log "translated attribute didn't get a translation object", val
                return val

            # Try primary choice first, fallback to whatever's available.
            languages = [@get_language(), 'fi', 'en', 'sv']
            for lang in languages
                if lang of val
                    return val[lang]

            console.log "no supported languages found", val
            return null

    # Make it a globally accessible variable for convenience
    window.p18n = new ServiceMapPersonalization
    return window.p18n
