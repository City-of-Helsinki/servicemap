(function() {
  define(function() {
    var FINNISH_ALPHABET, alpha;
    FINNISH_ALPHABET = 'abcdefghijklmnopqrstuvwxyzåäö';
    alpha = function(direction, caseSensitive, alphabetOrder) {
      var compareLetters;
      if (alphabetOrder == null) {
        alphabetOrder = FINNISH_ALPHABET;
      }
      compareLetters = function(a, b) {
        var ia, ib, _ref;
        _ref = [alphabetOrder.indexOf(a), alphabetOrder.indexOf(b)], ia = _ref[0], ib = _ref[1];
        if (ia === -1 || ib === -1) {
          if (ib !== -1) {
            return a > 'a';
          }
          if (ia !== -1) {
            return 'a' > b;
          }
          return a > b;
        }
        return ia > ib;
      };
      direction = direction || 1;
      return function(a, b) {
        var length, pos;
        length = Math.min(a.length, b.length);
        caseSensitive = caseSensitive || false;
        if (!caseSensitive) {
          a = a.toLowerCase();
          b = b.toLowerCase();
        }
        pos = 0;
        while (a.charAt(pos) === b.charAt(pos) && pos < length) {
          pos++;
        }
        if (compareLetters(a.charAt(pos), b.charAt(pos))) {
          return direction;
        } else {
          return -direction;
        }
      };
    };
    return {
      makeComparator: alpha
    };
  });

}).call(this);

//# sourceMappingURL=alphabet.js.map
