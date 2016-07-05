define ->
    FINNISH_ALPHABET = 'abcdefghijklmnopqrstuvwxyzåäö'

    # Thank you
    # http://stackoverflow.com/questions/3630645/how-to-compare-utf-8-strings-in-javascript/3633725#3633725
    alpha = (direction, caseSensitive, alphabetOrder = FINNISH_ALPHABET) ->
        compareLetters = (a, b) ->
            [ia, ib] = [alphabetOrder.indexOf(a), alphabetOrder.indexOf(b)]
            if ia == -1 or ib == -1
                if ib != -1
                    return a > 'a'
                if ia != -1
                    return 'a' > b
                return a > b
            ia > ib
        direction = direction or 1
        (a, b) ->
            length = Math.min a.length, b.length
            caseSensitive = caseSensitive or false
            if !caseSensitive
                a = a.toLowerCase()
                b = b.toLowerCase()
            pos = 0
            while a.charAt(pos) == b.charAt(pos) and pos < length
                pos++

            if compareLetters a.charAt(pos), b.charAt(pos)
                direction
            else
                -direction

    #a.sort alpha('ABCDEFGHIJKLMNOPQRSTUVWXYZaàâäbcçdeéèêëfghiïîjklmnñoôöpqrstuûüvwxyÿz')
    makeComparator: alpha
