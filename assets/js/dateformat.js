(function() {
  define(['moment'], function(moment) {
    var clockWord, dateFormat, formatEventDatetime, formatSpecs, getLanguage, humanize, humanizeEventDatetime, humanizeSingleDatetime, isMultiDayEvent, isMultiMonthEvent, isMultiYearEvent;
    isMultiDayEvent = function(_arg) {
      var end, start;
      start = _arg[0], end = _arg[1];
      return (end != null) && !start.isSame(end, 'day');
    };
    isMultiYearEvent = function(_arg) {
      var end, start;
      start = _arg[0], end = _arg[1];
      return (end != null) && !start.isSame(end, 'year');
    };
    isMultiMonthEvent = function(_arg) {
      var end, start;
      start = _arg[0], end = _arg[1];
      return (end != null) && !start.isSame(end, 'month');
    };
    getLanguage = function() {
      return moment.locale();
    };
    clockWord = {
      'fi': 'klo',
      'sv': 'kl.',
      'en-gb': 'at'
    };
    dateFormat = function(specs, includeMonth, includeYear) {
      var add, format;
      if (includeMonth == null) {
        includeMonth = true;
      }
      if (includeYear == null) {
        includeYear = false;
      }
      format = [];
      add = function(x) {
        return format.push(x);
      };
      if (specs.includeWeekday) {
        add(specs.format.weekday);
      }
      if (true) {
        add(specs.format.dayOfMonth);
      }
      if (includeMonth) {
        add(specs.format.month);
      }
      if (includeYear) {
        add(specs.format.year);
      }
      return format;
    };
    humanize = function(m) {
      var day;
      day = m.calendar();
      day = day.replace(/( (klo|at))* \d{1,2}[:.]\d{1,2}$/, '');
      return day;
    };
    formatEventDatetime = function(start, end, specs) {
      var diff, endDate, format, includeMonth, includeYear, results, sod, startDate, startTime;
      results = {};
      format = dateFormat(specs, includeMonth = specs.includeStartTime || specs.includeFirstMonth, includeYear = specs.includeFirstYear);
      if (specs.humanize) {
        startDate = humanize(start);
      } else {
        startDate = start.format(format.join(' '));
      }
      startTime = start.format(specs.format.time);
      if (isMultiDayEvent([start, end])) {
        format = dateFormat(specs, includeMonth = true, includeYear = specs.includeLastYear);
        if (!specs.includeLastYear && specs.includeStartTime) {
          startDate += ' ' + startTime;
        }
        endDate = end.format(format.join(' '));
        if (!specs.includeLastYear && specs.includeEndTime) {
          endDate += ' ' + end.format(specs.format.time);
        }
      } else {
        if (specs.includeStartTime) {
          results.startTime = startTime;
        }
        if (specs.includeEndTime) {
          results.endTime = end.format(specs.format.time);
        }
      }
      sod = moment().startOf('day');
      diff = start.diff(sod, 'days', true);
      if (specs.humanizeNotice && (diff < 2) && (diff > -1)) {
        results.notice = humanize(start);
      }
      if (results.startTime) {
        results.time = "" + clockWord[getLanguage()] + " " + results.startTime;
        delete results.startTime;
      }
      if (results.endTime) {
        results.time += "&nbsp;" + results.endTime;
        delete results.endTime;
      }
      results.date = [startDate, endDate];
      return results;
    };
    formatSpecs = function(language, space) {
      var dayOfMonth, month, weekday;
      weekday = space === 'large' ? 'dddd' : getLanguage() === 'en-gb' ? 'ddd' : 'dd';
      month = space === 'large' ? getLanguage() === 'fi' ? 'MMMM[ta]' : 'MMMM' : getLanguage() === 'fi' ? 'Mo' : getLanguage() === 'sv' ? 'M[.]' : getLanguage() === 'en-gb' ? 'MMM' : 'M';
      dayOfMonth = getLanguage() === 'sv' ? 'D[.]' : getLanguage() === 'en-gb' ? 'D' : 'Do';
      return {
        time: 'LT',
        year: 'YYYY',
        weekday: weekday,
        month: month,
        dayOfMonth: dayOfMonth
      };
    };
    humanizeSingleDatetime = function(datetime) {
      return humanizeEventDatetime(datetime, null, 'small');
    };
    humanizeEventDatetime = function(start, end, space) {
      var diff, ev, hasEndTime, hasStartTime, now, result, sod, specs, _humanize;
      hasStartTime = start.length > 11;
      hasEndTime = hasStartTime && ((end != null ? end.length : void 0) > 11);
      start = moment(start);
      if (end != null) {
        end = moment(end);
      }
      now = moment();
      ev = [start, end];
      if (isMultiDayEvent(ev && !hasStartTime)) {
        hasEndTime = false;
      }
      specs = {};
      specs.includeFirstYear = isMultiYearEvent(ev);
      specs.includeLastYear = (!now.isSame(end, 'year')) || isMultiYearEvent(ev);
      specs.includeFirstMonth = isMultiMonthEvent(ev);
      if (space === 'large' && isMultiDayEvent(ev)) {
        specs.includeWeekday = true;
      }
      specs.includeStartTime = hasStartTime && ((space === 'large' && hasEndTime) || !isMultiDayEvent(ev));
      specs.includeEndTime = hasEndTime && space === 'large';
      if (!isMultiDayEvent(ev)) {
        specs.includeFirstMonth = true;
        sod = now.startOf('day');
        diff = start.diff(sod, 'days', true);
        _humanize = diff > -7 && diff <= 7;
        if (space === 'large') {
          specs.humanizeNotice = _humanize;
        } else {
          specs.humanize = _humanize;
        }
        if (!specs.humanize) {
          specs.includeWeekday = true;
        }
      }
      specs.format = formatSpecs(getLanguage(), space);
      result = formatEventDatetime(start, end, specs);
      return result;
    };
    return {
      humanizeEventDatetime: humanizeEventDatetime,
      humanizeSingleDatetime: humanizeSingleDatetime
    };
  });

}).call(this);

//# sourceMappingURL=dateformat.js.map
