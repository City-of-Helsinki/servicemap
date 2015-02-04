define [
    'moment'
], (
    moment
) ->

    isMultiDayEvent = ([start, end]) ->
        end? and not start.isSame end, 'day'
    isMultiYearEvent = ([start, end]) ->
        end? and not start.isSame end, 'year'
    isMultiMonthEvent = ([start, end]) ->
        end? and not start.isSame end, 'month'

    getLanguage = ->
        moment.locale()

    # TODO move to locale
    clockWord =
        'fi': 'klo',
        'sv': 'kl.',
        'en-gb': 'at'

    dateFormat = (specs, includeMonth=true, includeYear=false) ->
        format = []
        add = (x) -> format.push x
        if specs.includeWeekday
            add specs.format.weekday
        if true
            add specs.format.dayOfMonth
        if includeMonth
            add specs.format.month
        if includeYear
            add specs.format.year
        format

    humanize = (m) ->
        day = m.calendar()
        # todo: Swedish?
        day = day.replace /( (klo|at))* \d{1,2}[:.]\d{1,2}$/, ''
        day

    formatEventDatetime = (start, end, specs) ->
        results = {}
        format = dateFormat specs,
            includeMonth = specs.includeStartTime or specs.includeFirstMonth,
            includeYear = specs.includeFirstYear

        if specs.humanize
            startDate = humanize start
        else
            startDate = start.format format.join(' ')

        startTime = start.format specs.format.time
        if isMultiDayEvent [start, end]
            format = dateFormat(specs, includeMonth=true, includeYear=specs.includeLastYear)
            if not specs.includeLastYear and specs.includeStartTime
                startDate += ' ' + startTime
            endDate = end.format format.join(' ')
            if not specs.includeLastYear and specs.includeEndTime
                endDate += ' ' + end.format specs.format.time
        else
            if specs.includeStartTime
                results.startTime = startTime
            if specs.includeEndTime
                results.endTime = end.format specs.format.time
        sod = moment().startOf 'day'
        diff = start.diff sod, 'days', true
        if specs.humanizeNotice and (diff < 2) and (diff > -1)
            # Add an extra notice for "yesterday" and "tomorrow"
            # in addition to the explicit datetime
            results.notice = humanize start
        if results.startTime
            results.time = "#{clockWord[getLanguage()]} #{results.startTime}"
            delete results.startTime
        if results.endTime
            results.time += "&nbsp;#{results.endTime}"
            delete results.endTime
        results.date = [startDate, endDate]
        results

    formatSpecs = (language, space) ->
        weekday =
            if space == 'large'
                'dddd'
            else
                if getLanguage() == 'en-gb' then 'ddd'
                else 'dd'
        month =
            if space == 'large'
                if getLanguage() == 'fi' then 'MMMM[ta]'
                else 'MMMM'
            else
                if getLanguage() == 'fi' then 'Mo'
                else if getLanguage() == 'sv' then 'M[.]'
                else if getLanguage() == 'en-gb' then 'MMM'
                else 'M'
        dayOfMonth =
            if getLanguage() == 'sv' then 'D[.]'
            else if  getLanguage() == 'en-gb' then 'D'
            else 'Do'

        time: 'LT'
        year: 'YYYY'
        weekday: weekday
        month: month
        dayOfMonth: dayOfMonth

    humanizeEventDatetime = (start, end, space) ->
        # space is 'large' or 'small'
        hasStartTime = start.length > 11
        hasEndTime = hasStartTime and (end?.length > 11)

        start = moment start
        if end?
            end = moment end
        now = moment()

        ev = [start, end]
        if isMultiDayEvent ev and not hasStartTime
            hasEndTime = false

        specs = {}
        specs.includeFirstYear =
            isMultiYearEvent ev
        specs.includeLastYear =
            (not now.isSame(end, 'year')) or isMultiYearEvent ev
        specs.includeFirstMonth =
            isMultiMonthEvent ev
        if space == 'large' and isMultiDayEvent ev
            specs.includeWeekday = true
        specs.includeStartTime =
            hasStartTime and ((space == 'large' and hasEndTime) or not isMultiDayEvent ev)
        specs.includeEndTime =
            hasEndTime and space == 'large'

        unless isMultiDayEvent ev
            specs.includeFirstMonth = true
            sod = now.startOf 'day'
            diff = start.diff sod, 'days', true
            _humanize = diff > -7 and diff <= 7
            if space == 'large'
                specs.humanizeNotice = _humanize
            else
                specs.humanize = _humanize
            unless specs.humanize
                specs.includeWeekday = true

        specs.format = formatSpecs getLanguage(), space
        result = formatEventDatetime start, end, specs
        result

    return humanizeEventDatetime: humanizeEventDatetime

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
