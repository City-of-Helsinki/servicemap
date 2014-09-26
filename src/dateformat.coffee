
moment = require 'moment'

# Test moments
a = moment('2014-07-15T12:00:00')
b = moment('2014-07-15T14:00:00')
c = moment('2014-07-16T10:00:00')
d = moment('2014-07-15T23:59:59')
e = moment('2014-07-16T00:00:00')
f = moment('2015-07-16T00:00:00')
g = moment('2014-08-15T00:00:00')
h = moment()
i = moment().add 2, 'hours'
j = moment().add 2, 'days'
k = moment().add 1, 'year'

is_multi_day_event = ([start, end]) ->
    end? and not start.isSame end, 'day'
is_multi_year_event = ([start, end]) ->
    end? and not start.isSame end, 'year'
is_multi_month_event = ([start, end]) ->
    end? and not start.isSame end, 'month'

locale = 'fi'
get_language = ->
    locale

clock_word =
    'fi': 'klo',
    'sv': 'kl.',
    'en-gb': 'at'

date_format = (specs, include_month=true) ->
    format = []
    add = (x) -> format.push x
    if specs.include_weekday
        add specs.format.weekday
    if true
        add specs.format.day_of_month
    if include_month
        add specs.format.month
    if specs.include_year
        add specs.format.year
    format

humanize = (m) ->
    day = m.calendar()
    # todo: Swedish
    day = day.replace /( (klo|at))* \d{1,2}[:.]\d{1,2}$/, ''
    day

format_event_datetime = (start, end, specs) ->
    results = {}
    start.locale locale
    end.locale locale
    format = date_format specs,
        include_month = specs.include_start_time or specs.include_first_month
    if specs.humanize
        date = humanize start
    else
        date = start.format format.join(' ')

    start_time = start.format specs.format.time
    end_time = end.format specs.format.time
    if is_multi_day_event [start, end]
        format = date_format specs
        if not specs.include_year and specs.include_start_time
            date += ' ' + start_time
        date += '&mdash;' + end.format format.join(' ')
        if not specs.include_year and specs.include_end_time
            date += ' ' + end_time
    else
        if specs.include_start_time
            results.start_time = start_time
        if specs.include_end_time
            results.end_time = end_time
    if specs.humanize_notice
        results.notice = humanize start

    if results.start_time
        results.time = "#{clock_word[get_language()]} #{results.start_time}"
        delete results.start_time
    if results.end_time
        results.time += "&nbsp;#{results.end_time}"
        delete results.end_time
    results.date = date
    results

format_specs = (language, space) ->
    weekday =
        if space == 'large'
            'dddd'
        else
            'dd'
    month =
        if space == 'large'
            if get_language() == 'fi' then 'MMMM[ta]'
            else 'MMMM'
        else
            if get_language() == 'fi' then 'Mo'
            else 'M'
    day_of_month =
        if get_language() == 'fi' then 'Do'
        else 'D'
    
    time: 'LT'
    year: 'YYYY'
    weekday: weekday
    month: month
    day_of_month: day_of_month

humanize_event_datetime = (start, end, space, has_end_time=false) ->
    ev = [start, end]
    now = moment()
    specs = {}
    specs.include_year =
        is_multi_year_event ev
    specs.include_first_month =
        is_multi_month_event ev
    if space == 'large' and is_multi_day_event ev
        specs.include_weekday = true

    specs.include_start_time =
        space == 'large' or not is_multi_day_event ev
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
        if specs.humanize
            if space == 'small'
                specs.include_start_time = false
            else
                specs.include_start_time = true
        else
            specs.include_weekday = true

    specs.format = format_specs get_language(), space
    result = format_event_datetime start, end, specs
    result
