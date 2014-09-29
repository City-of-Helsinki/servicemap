define 'app/dateformat', ['moment'], (moment) ->

    is_multi_day_event = ([start, end]) ->
        end? and not start.isSame end, 'day'
    is_multi_year_event = ([start, end]) ->
        end? and not start.isSame end, 'year'
    is_multi_month_event = ([start, end]) ->
        end? and not start.isSame end, 'month'

    get_language = ->
        moment.locale()

    # TODO move to locale
    clock_word =
        'fi': 'klo',
        'sv': 'kl.',
        'en-gb': 'at'

    date_format = (specs, include_month=true, include_year=false) ->
        format = []
        add = (x) -> format.push x
        if specs.include_weekday
            add specs.format.weekday
        if true
            add specs.format.day_of_month
        if include_month
            add specs.format.month
        if include_year
            add specs.format.year
        format

    humanize = (m) ->
        day = m.calendar()
        # todo: Swedish?
        day = day.replace /( (klo|at))* \d{1,2}[:.]\d{1,2}$/, ''
        day

    format_event_datetime = (start, end, specs) ->
        results = {}
        format = date_format specs,
            include_month = specs.include_start_time or specs.include_first_month,
            include_year = specs.include_first_year

        if specs.humanize
            start_date = humanize start
        else
            start_date = start.format format.join(' ')

        start_time = start.format specs.format.time
        if is_multi_day_event [start, end]
            format = date_format(specs, include_month=true, include_year=specs.include_last_year)
            if not specs.include_last_year and specs.include_start_time
                start_date += ' ' + start_time
            end_date = end.format format.join(' ')
            if not specs.include_last_year and specs.include_end_time
                end_date += ' ' + end.format specs.format.time
        else
            if specs.include_start_time
                results.start_time = start_time
            if specs.include_end_time
                results.end_time = end.format specs.format.time
        sod = moment().startOf 'day'
        diff = start.diff sod, 'days', true
        if specs.humanize_notice and (diff < 2) and (diff > -1)
            # Add an extra notice for "yesterday" and "tomorrow"
            # in addition to the explicit datetime
            results.notice = humanize start
        if results.start_time
            results.time = "#{clock_word[get_language()]} #{results.start_time}"
            delete results.start_time
        if results.end_time
            results.time += "&nbsp;#{results.end_time}"
            delete results.end_time
        results.date = [start_date, end_date]
        results

    format_specs = (language, space) ->
        weekday =
            if space == 'large'
                'dddd'
            else
                if get_language() == 'en-gb' then 'ddd'
                else 'dd'
        month =
            if space == 'large'
                if get_language() == 'fi' then 'MMMM[ta]'
                else 'MMMM'
            else
                if get_language() == 'fi' then 'Mo'
                else if get_language() == 'sv' then 'M[.]'
                else if get_language() == 'en-gb' then 'MMM'
                else 'M'
        day_of_month =
            if get_language() == 'sv' then 'D[.]'
            else if  get_language() == 'en-gb' then 'D'
            else 'Do'
        
        time: 'LT'
        year: 'YYYY'
        weekday: weekday
        month: month
        day_of_month: day_of_month
    
    humanize_event_datetime = (start, end, space) ->
        # space is 'large' or 'small'
        has_start_time = start.length > 11
        has_end_time = has_start_time and (end?.length > 11)
        
        start = moment start
        if end?
            end = moment end
        now = moment()

        ev = [start, end]
        if is_multi_day_event ev and not has_start_time
            has_end_time = false

        specs = {}
        specs.include_first_year =
            is_multi_year_event ev
        specs.include_last_year =
            (not now.isSame(end, 'year')) or is_multi_year_event ev
        specs.include_first_month =
            is_multi_month_event ev
        if space == 'large' and is_multi_day_event ev
            specs.include_weekday = true
        specs.include_start_time =
            has_start_time and ((space == 'large' and has_end_time) or not is_multi_day_event ev)
        specs.include_end_time =
            has_end_time and space == 'large'

        unless is_multi_day_event ev
            specs.include_first_month = true
            sod = now.startOf 'day'
            diff = start.diff sod, 'days', true
            _humanize = diff > -7 and diff <= 7
            if space == 'large'
                specs.humanize_notice = _humanize
            else
                specs.humanize = _humanize
            unless specs.humanize
                specs.include_weekday = true

        specs.format = format_specs get_language(), space
        result = format_event_datetime start, end, specs
        result

    return humanize_event_datetime: humanize_event_datetime

    # Test moments
    # a = moment('2014-07-15T12:00:00')
    # b = moment('2014-07-15T14:00:00')
    # c = moment('2014-07-16T10:00:00')
    # d = moment('2014-07-15T23:59:59')
    # e = moment('2014-07-16T00:00:00')
    # f = moment('2015-07-16T00:00:00')
    # g = moment('2014-08-15T00:00:00')
    # h = moment()
    # i = moment().add 2, 'hours'
    # j = moment().add 2, 'days'
    # k = moment().add 1, 'year'
