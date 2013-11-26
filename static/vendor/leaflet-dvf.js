/*
 @preserve Leaflet Data Visualization Framework, a JavaScript library for creating thematic maps using Leaflet
 (c) 2013, Scott Fairgrieve, HumanGeo
*/
L.LinearFunction = L.Class.extend({
    initialize: function(minPoint, maxPoint, options) {
        this.setOptions(options);
        this.setRange(minPoint, maxPoint);
    },
    _calculateParameters: function(minPoint, maxPoint) {
        if (this._xRange === 0) {
            this._slope = 0;
            this._b = minPoint.y;
        } else {
            this._slope = (maxPoint.y - minPoint.y) / this._xRange;
            this._b = minPoint.y - this._slope * minPoint.x;
        }
    },
    _arrayToPoint: function(array) {
        return {
            x: array[0],
            y: array[1]
        };
    },
    setOptions: function(options) {
        L.Util.setOptions(this, options);
        this._preProcess = this.options.preProcess;
        this._postProcess = this.options.postProcess;
    },
    getBounds: function() {
        var minX = Math.min(this._minPoint.x, this._maxPoint.x);
        var maxX = Math.max(this._minPoint.x, this._maxPoint.x);
        var minY = Math.min(this._minPoint.y, this._maxPoint.y);
        var maxY = Math.max(this._minPoint.y, this._maxPoint.y);
        return [ new L.Point(minX, minY), new L.Point(maxX, maxY) ];
    },
    setRange: function(minPoint, maxPoint) {
        minPoint = minPoint instanceof Array ? this._arrayToPoint(minPoint) : minPoint;
        maxPoint = maxPoint instanceof Array ? this._arrayToPoint(maxPoint) : maxPoint;
        this._minPoint = minPoint;
        this._maxPoint = maxPoint;
        this._xRange = maxPoint.x - minPoint.x;
        this._calculateParameters(minPoint, maxPoint);
        return this;
    },
    setMin: function(point) {
        this.setRange(point, this._maxPoint);
        return this;
    },
    setMax: function(point) {
        this.setRange(this._minPoint, point);
        return this;
    },
    setPreProcess: function(preProcess) {
        this._preProcess = preProcess;
        return this;
    },
    setPostProcess: function(postProcess) {
        this._postProcess = postProcess;
        return this;
    },
    evaluate: function(x) {
        var y;
        if (this._preProcess) {
            x = this._preProcess(x);
        }
        y = Number((this._slope * x).toFixed(6)) + Number(this._b.toFixed(6));
        if (this._postProcess) {
            y = this._postProcess(y);
        }
        return y;
    },
    random: function() {
        var randomX = Math.random() * this._xRange + this._minPoint.x;
        return this.evaluate(randomX);
    },
    sample: function(count) {
        count = Math.max(count, 2);
        var segmentCount = count - 1;
        var segmentSize = this._xRange / segmentCount;
        var x = this._minPoint.x;
        var yValues = [];
        while (x <= this._maxPoint.x) {
            yValues.push(this.evaluate(x));
            x += segmentSize;
        }
        return yValues;
    },
    samplePoints: function(count) {
        count = Math.max(count, 2);
        var segmentCount = count - 1;
        var segmentSize = this._xRange / segmentCount;
        var x = this._minPoint.x;
        var points = [];
        while (x <= this._maxPoint.x) {
            points.push(new L.Point(x, this.evaluate(x)));
            x += segmentSize;
        }
        return points;
    }
});

L.ColorFunction = L.LinearFunction.extend({
    options: {
        alpha: 1,
        includeAlpha: false
    },
    initialize: function(minPoint, maxPoint, options) {
        L.Util.setOptions(this, options);
        this._parts = [];
        this._dynamicPart = null;
        this._outputPrecision = 0;
        this._prefix = null;
        this._formatOutput = function(y) {
            return y.toFixed(this._outputPrecision);
        }, this._mapOutput = function(parts) {
            var outputParts = [];
            for (var i = 0; i < this._parts.length; ++i) {
                var part = this._parts[i];
                outputParts.push(parts[part]);
            }
            if (this.options.includeAlpha) {
                outputParts.push(this.options.alpha);
            }
            return outputParts;
        };
        this._getColorString = function(y) {
            y = this._formatOutput(y);
            this.options[this._dynamicPart] = y;
            var parts = this._mapOutput(this.options);
            return this._writeColor(this._prefix, parts);
        };
        this._writeColor = function(prefix, parts) {
            if (this.options.includeAlpha) {
                prefix += "a";
            }
            return prefix + "(" + parts.join(",") + ")";
        };
        var postProcess = function(y) {
            if (options && options.postProcess) {
                y = options.postProcess.call(this, y);
            }
            var colorString = this._getColorString(y);
            if ((L.Browser.ie6 || L.Browser.ie7) && colorString.indexOf("hsl") > -1) {
                colorString = L.ColorUtils.hslStringToRgbString(colorString);
            }
            return colorString;
        };
        L.LinearFunction.prototype.initialize.call(this, minPoint, maxPoint, {
            preProcess: this.options.preProcess,
            postProcess: postProcess
        });
    }
});

L.HSLColorFunction = L.ColorFunction.extend({
    initialize: function(minPoint, maxPoint, options) {
        L.ColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._parts = [ "outputHue", "outputSaturation", "outputLuminosity" ];
        this._prefix = "hsl";
        this._outputPrecision = 2;
    }
});

L.RGBColorFunction = L.ColorFunction.extend({
    initialize: function(minPoint, maxPoint, options) {
        L.ColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._parts = [ "outputRed", "outputBlue", "outputGreen" ];
        this._prefix = "rgb";
        this._outputPrecision = 0;
    }
});

L.RGBRedFunction = L.LinearFunction.extend({
    options: {
        outputGreen: 0,
        outputBlue: 0
    },
    initialize: function(minPoint, maxPoint, options) {
        L.RGBColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._dynamicPart = "outputRed";
    }
});

L.RGBBlueFunction = L.LinearFunction.extend({
    options: {
        outputRed: 0,
        outputGreen: 0
    },
    initialize: function(minPoint, maxPoint, options) {
        L.RGBColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._dynamicPart = "outputBlue";
    }
});

L.RGBGreenFunction = L.LinearFunction.extend({
    options: {
        outputRed: 0,
        outputBlue: 0
    },
    initialize: function(minPoint, maxPoint, options) {
        L.RGBColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._dynamicPart = "outputGreen";
    }
});

L.RGBColorBlendFunction = L.LinearFunction.extend({
    initialize: function(minX, maxX, rgbMinColor, rgbMaxColor) {
        var red1 = rgbMinColor[0];
        var red2 = rgbMaxColor[0];
        var green1 = rgbMinColor[1];
        var green2 = rgbMaxColor[1];
        var blue1 = rgbMinColor[2];
        var blue2 = rgbMaxColor[2];
        var postProcess = function(y) {
            return y.toFixed(0);
        };
        this._minX = minX;
        this._maxX = maxX;
        this._redFunction = new L.LinearFunction(new L.Point(minX, red1), new L.Point(maxX, red2), {
            postProcess: postProcess
        });
        this._greenFunction = new L.LinearFunction(new L.Point(minX, green1), new L.Point(maxX, green2), {
            postProcess: postProcess
        });
        this._blueFunction = new L.LinearFunction(new L.Point(minX, blue1), new L.Point(maxX, blue2), {
            postProcess: postProcess
        });
    },
    getBounds: function() {
        var redBounds = this._redFunction.getBounds();
        var greenBounds = this._greenFunction.getBounds();
        var blueBounds = this._blueFunction.getBounds();
        var minY = Math.min(redBounds[0].y, greenBounds[0].y, blueBounds[0].y);
        var maxY = Math.max(redBounds[0].y, greenBounds[0].y, blueBounds[0].y);
        return [ new L.Point(redBounds[0].x, minY), new L.Point(redBounds[1].x, maxY) ];
    },
    evaluate: function(x) {
        return "rgb(" + [ this._redFunction.evaluate(x), this._greenFunction.evaluate(x), this._blueFunction.evaluate(x) ].join(",") + ")";
    }
});

L.HSLHueFunction = L.HSLColorFunction.extend({
    options: {
        outputSaturation: "100%",
        outputLuminosity: "50%"
    },
    initialize: function(minPoint, maxPoint, options) {
        L.HSLColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._dynamicPart = "outputHue";
    }
});

L.HSLSaturationFunction = L.LinearFunction.extend({
    options: {
        outputHue: 0,
        outputLuminosity: "50%"
    },
    initialize: function(minPoint, maxPoint, options) {
        L.HSLColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._formatOutput = function(y) {
            return (y * 100).toFixed(this._outputPrecision) + "%";
        };
        this._dynamicPart = "outputSaturation";
    }
});

L.HSLLuminosityFunction = L.LinearFunction.extend({
    options: {
        outputHue: 0,
        outputSaturation: "100%"
    },
    initialize: function(minPoint, maxPoint, options) {
        L.HSLColorFunction.prototype.initialize.call(this, minPoint, maxPoint, options);
        this._formatOutput = function(y) {
            return (y * 100).toFixed(this._outputPrecision) + "%";
        };
        this._dynamicPart = "outputLuminosity";
    }
});

L.PiecewiseFunction = L.LinearFunction.extend({
    initialize: function(functions, options) {
        L.Util.setOptions(this, options);
        this._functions = functions;
        var startPoint;
        var endPoint;
        startPoint = functions[0].getBounds()[0];
        endPoint = functions[functions.length - 1].getBounds()[1];
        L.LinearFunction.prototype.initialize.call(this, startPoint, endPoint, {
            preProcess: this.options.preProcess,
            postProcess: this.options.postProcess
        });
    },
    _getFunction: function(x) {
        var bounds;
        var startPoint;
        var endPoint;
        var found = false;
        var currentFunction;
        for (var index = 0; index < this._functions.length; ++index) {
            currentFunction = this._functions[index];
            bounds = currentFunction.getBounds();
            startPoint = bounds[0];
            endPoint = bounds[1];
            if (x >= startPoint.x && x < endPoint.x) {
                found = true;
                break;
            }
        }
        return found ? currentFunction : this._functions[this._functions.length - 1];
    },
    evaluate: function(x) {
        var currentFunction;
        var y = null;
        if (this._preProcess) {
            x = this._preProcess(x);
        }
        currentFunction = this._getFunction(x);
        if (currentFunction) {
            y = currentFunction.evaluate(x);
            if (this._postProcess) {
                y = this._postProcess(y);
            }
        }
        return y;
    }
});

L.CategoryFunction = L.Class.extend({
    initialize: function(categoryMap, options) {
        L.Util.setOptions(this, options);
        this._categoryKeys = Object.keys(categoryMap);
        this._categoryMap = categoryMap;
        this._preProcess = this.options.preProcess;
        this._postProcess = this.options.postProcess;
    },
    evaluate: function(x) {
        var y;
        if (this._preProcess) {
            x = this._preProcess(x);
        }
        y = this._categoryMap[x];
        if (this._postProcess) {
            y = this._postProcess(y);
        }
        return y;
    },
    getCategories: function() {
        return this._categoryKeys;
    }
});

if (!Object.keys) {
    Object.keys = function() {
        var hasOwnProperty = Object.prototype.hasOwnProperty, hasDontEnumBug = !{
            toString: null
        }.propertyIsEnumerable("toString"), dontEnums = [ "toString", "toLocaleString", "valueOf", "hasOwnProperty", "isPrototypeOf", "propertyIsEnumerable", "constructor" ], dontEnumsLength = dontEnums.length;
        return function(obj) {
            var result, prop, i;
            if (typeof obj !== "object" && typeof obj !== "function" || obj === null) {
                throw new TypeError("Object.keys called on non-object");
            }
            result = [];
            for (prop in obj) {
                if (hasOwnProperty.call(obj, prop)) {
                    result.push(prop);
                }
            }
            if (hasDontEnumBug) {
                for (i = 0; i < dontEnumsLength; i++) {
                    if (hasOwnProperty.call(obj, dontEnums[i])) {
                        result.push(dontEnums[i]);
                    }
                }
            }
            return result;
        };
    }();
}

L.Util.guid = function() {
    var s4 = function() {
        return Math.floor((1 + Math.random()) * 65536).toString(16).substring(1);
    };
    return s4() + s4() + "-" + s4() + "-" + s4() + "-" + s4() + "-" + s4() + s4() + s4();
};

L.Util.getProperty = function(obj, property, defaultValue) {
    return property in obj ? obj[property] : defaultValue;
};

L.Util.setFieldValue = function(record, fieldName, value) {
    var keyParts = fieldName.split(".");
    var pointer = record;
    var part;
    for (var i = 0; i < keyParts.length - 1; ++i) {
        part = keyParts[i];
        pointer[part] = pointer[part] || {};
        pointer = pointer[part];
    }
    pointer[keyParts[keyParts.length - 1]] = value;
};

L.Util.getFieldValue = function(record, fieldName) {
    var value = null;
    if (fieldName) {
        var parts = fieldName.split(".");
        var valueField = record;
        var part;
        var searchParts;
        var searchKey;
        var searchValue;
        var testObject;
        var searchPart;
        var bracketIndex = -1;
        var testValue;
        for (var partIndex = 0; partIndex < parts.length; ++partIndex) {
            part = parts[partIndex];
            bracketIndex = part.indexOf("[");
            if (bracketIndex > -1) {
                searchPart = part.substring(bracketIndex);
                part = part.substring(0, bracketIndex);
                searchPart = searchPart.replace("[", "").replace("]", "");
                searchParts = searchPart.split("=");
                searchKey = searchParts[0];
                searchValue = searchParts[1];
                valueField = valueField[part];
                for (var valueIndex = 0; valueIndex < valueField.length; ++valueIndex) {
                    testObject = valueField[valueIndex];
                    testValue = testObject[searchKey];
                    if (testValue && testValue === searchValue) {
                        valueField = testObject;
                    }
                }
            } else if (valueField && valueField.hasOwnProperty(part)) {
                valueField = valueField[part];
            } else {
                valueField = null;
                break;
            }
        }
        value = valueField;
    } else {
        value = record;
    }
    return value;
};

L.CategoryLegend = L.Class.extend({
    initialize: function(options) {
        L.Util.setOptions(this, options);
    },
    generate: function(options) {
        options = options || {};
        var legend = '<div class="legend"></div>';
        var $legend = $(legend);
        var className = options.className;
        var legendOptions = this.options;
        if (className) {
            $legend.addClass(className);
        }
        if (options.title) {
            $legend.append('<div class="legend-title">' + options.title + "</div>");
        }
        for (var key in legendOptions) {
            categoryOptions = legendOptions[key];
            var displayName = categoryOptions.displayName || key;
            var $legendElement = $('<div class="data-layer-legend"><div class="legend-box"></div><div class="key">' + displayName + "</div></div>");
            var $legendBox = $legendElement.find(".legend-box");
            L.StyleConverter.applySVGStyle($legendBox, categoryOptions);
            $legend.append($legendElement);
        }
        return $legend.wrap("<div/>").parent().html();
    }
});

L.LegendIcon = L.DivIcon.extend({
    initialize: function(fields, layerOptions, options) {
        var html = '<div class="legend-content"><div class="title"></div><div class="legend-box"></div><div class="legend-values"></div></div>';
        var $html = $(html);
        var $legendBox = $html.find(".legend-box");
        var $legendValues = $html.find(".legend-values");
        var field;
        var title = layerOptions.title || layerOptions.name;
        if (title) {
            $html.find(".title").text(title);
        }
        for (var key in fields) {
            field = fields[key];
            var displayName = field.name || key;
            var displayText = field.value;
            $legendValues.append('<div class="key">' + displayName + '</div><div class="value">' + displayText + "</div>");
        }
        L.StyleConverter.applySVGStyle($legendBox, layerOptions);
        $legendBox.height(5);
        html = $html.wrap("<div>").parent().html();
        options.html = html;
        options.className = options.className || "legend-icon";
        L.DivIcon.prototype.initialize.call(this, options);
    }
});

L.legendIcon = function(fields, layerOptions, options) {
    return new L.LegendIcon(fields, layerOptions, options);
};

L.GeometryUtils = {
    getName: function(geoJSON) {
        var name = null;
        if (geoJSON && geoJSON.features) {
            for (var index = 0; index < geoJSON.features.length; ++index) {
                var feature = geoJSON.features[index];
                if (feature.properties && feature.properties.name) {
                    name = feature.properties.name;
                    break;
                }
            }
        }
        return name;
    },
    getGeoJSONLocation: function(geoJSON, record, locationTextField, recordToLayer) {
        var geoJSONLayer = new L.GeoJSON(geoJSON, {
            pointToLayer: function(feature, latlng) {
                var location = {
                    location: latlng,
                    text: locationTextField ? L.Util.getFieldValue(record, locationTextField) : [ latlng.lat.toFixed(3), latlng.lng.toFixed(3) ].join(", "),
                    center: latlng
                };
                return recordToLayer(location, record);
            }
        });
        var center = null;
        try {
            center = L.GeometryUtils.loadCentroid(geoJSON);
        } catch (ex) {
            console.log("Error loading centroid for " + JSON.stringify(geoJSON));
        }
        return {
            location: geoJSONLayer,
            text: locationTextField ? L.Util.getFieldValue(record, locationTextField) : null,
            center: center
        };
    },
    mergeProperties: function(properties, featureCollection, mergeKey) {
        var features = featureCollection["features"];
        var featureIndex = L.GeometryUtils.indexFeatureCollection(features, mergeKey);
        var property;
        var mergeValue;
        var newFeatureCollection = {
            type: "FeatureCollection",
            features: []
        };
        for (var key in properties) {
            if (properties.hasOwnProperty(key)) {
                property = properties[key];
                mergeValue = property[mergeKey];
                if (mergeValue) {
                    var feature = featureIndex[mergeValue];
                    for (var prop in property) {
                        feature.properties[prop] = property[prop];
                    }
                    newFeatureCollection.features.push(feature);
                }
            }
        }
        return newFeatureCollection;
    },
    indexFeatureCollection: function(featureCollection, indexKey) {
        var features = featureCollection.features;
        var feature;
        var properties;
        var featureIndex = {};
        var value;
        for (var index = 0; index < features.length; ++index) {
            feature = features[index];
            properties = feature.properties;
            value = properties[indexKey];
            featureIndex[value] = feature;
        }
        return featureIndex;
    },
    arrayToMap: function(array, fromKey, toKey) {
        var map = {};
        var item;
        var from;
        var to;
        for (var index = 0; index < array.length; ++index) {
            item = array[index];
            from = item[fromKey];
            to = toKey ? item[toKey] : item;
            map[from] = to;
        }
        return map;
    },
    arrayToMaps: function(array, mapLinks) {
        var map;
        var item;
        var from;
        var to;
        var maps = [];
        var mapLink;
        var fromKey;
        var toKey;
        for (var i = 0; i < mapLinks.length; ++i) {
            maps.push({});
        }
        for (var index = 0; index < array.length; ++index) {
            item = array[index];
            for (var keyIndex = 0; keyIndex < mapLinks.length; ++keyIndex) {
                map = maps[keyIndex];
                mapLink = mapLinks[keyIndex];
                fromKey = mapLink.from;
                toKey = mapLink.to;
                from = item[fromKey];
                to = toKey ? item[toKey] : item;
                map[from] = to;
            }
        }
        return maps;
    },
    loadCentroid: function(feature) {
        var centroidLatLng = null;
        var centroid;
        var x, y;
        if (feature.geometry && feature.geometry.type === "Point") {
            centroidLatLng = new L.LatLng(feature.geometry.coordinates[1], feature.geometry.coordinates[0]);
        } else if (typeof jsts !== "undefined") {
            var parser = new jsts.io.GeoJSONParser();
            var jstsFeature = parser.read(feature);
            if (jstsFeature.getCentroid) {
                centroid = jstsFeature.getCentroid();
                x = centroid.coordinate.x;
                y = centroid.coordinate.y;
            } else if (jstsFeature.features) {
                var totalCentroidX = 0;
                var totalCentroidY = 0;
                for (var i = 0; i < jstsFeature.features.length; ++i) {
                    centroid = jstsFeature.features[i].geometry.getCentroid();
                    totalCentroidX += centroid.coordinate.x;
                    totalCentroidY += centroid.coordinate.y;
                }
                x = totalCentroidX / jstsFeature.features.length;
                y = totalCentroidY / jstsFeature.features.length;
            } else {
                centroid = jstsFeature.geometry.getCentroid();
                x = centroid.coordinate.x;
                y = centroid.coordinate.y;
            }
            centroidLatLng = new L.LatLng(y, x);
        }
        return centroidLatLng;
    },
    loadCentroids: function(dictionary) {
        var centroids = {};
        var feature;
        for (var key in dictionary) {
            feature = dictionary[key];
            centroids[key] = L.GeometryUtils.loadCentroid(feature);
        }
        return centroids;
    }
};

L.SVGPathBuilder = L.Class.extend({
    initialize: function(points, innerPoints, options) {
        this._points = points || [];
        this._innerPoints = innerPoints || [];
        L.Util.setOptions(this, options);
    },
    options: {
        closePath: true
    },
    _getPathString: function(points, digits) {
        var pathString = "";
        if (points.length > 0) {
            var point = points[0];
            var digits = digits !== null ? digits : 2;
            var startChar = "M";
            var lineToChar = "L";
            var closePath = "Z";
            if (L.Browser.vml) {
                digits = 0;
                startChar = "m";
                lineToChar = "|";
                closePath = "xe";
            }
            pathString = startChar + point.x.toFixed(digits) + "," + point.y.toFixed(digits);
            for (var index = 1; index < points.length; index++) {
                point = points[index];
                pathString += lineToChar + point.x.toFixed(digits) + "," + point.y.toFixed(digits);
            }
            if (this.options.closePath) {
                pathString += closePath;
            }
        }
        return pathString;
    },
    addPoint: function(point, inner) {
        inner ? this._innerPoints.push(point) : this._points.push(point);
    },
    build: function(digits) {
        digits = digits || this.options.digits;
        var pathString = this._getPathString(this._points, digits);
        if (this._innerPoints) {
            pathString += this._getPathString(this._innerPoints, digits);
        }
        return pathString;
    }
});

L.StyleConverter = {
    keyMap: {
        fillColor: {
            property: [ "background-color" ],
            valueFunction: function(value) {
                return value;
            }
        },
        color: {
            property: [ "color", "border-top-color", "border-right-color", "border-bottom-color", "border-left-color" ],
            valueFunction: function(value) {
                return value;
            }
        },
        weight: {
            property: [ "border-width" ],
            valueFunction: function(value) {
                return Math.ceil(value) + "px";
            }
        },
        stroke: {
            property: [ "border-style" ],
            valueFunction: function(value) {
                return value === true ? "solid" : "none";
            }
        },
        dashArray: {
            property: [ "border-style" ],
            valueFunction: function(value) {
                var style = "solid";
                if (value) {
                    style = "dashed";
                }
                return style;
            }
        },
        barThickness: {
            property: [ "height" ],
            valueFunction: function(value) {
                return value + "px";
            }
        },
        radius: {
            property: [ "height" ],
            valueFunction: function(value) {
                return 2 * value + "px";
            }
        },
        fillOpacity: {
            property: [ "opacity" ],
            valueFunction: function(value) {
                return value;
            }
        }
    },
    applySVGStyle: function($element, svgStyle, additionalKeys) {
        var keyMap = L.StyleConverter.keyMap;
        if (additionalKeys) {
            keyMap = L.Util.extend(keyMap, additionalKeys);
        }
        $element.css("border-style", "solid");
        for (var property in svgStyle) {
            $element = L.StyleConverter.setCSSProperty($element, property, svgStyle[property], keyMap);
        }
        return $element;
    },
    setCSSProperty: function($element, key, value, keyMap) {
        var keyMap = keyMap || L.StyleConverter.keyMap;
        var cssProperty = keyMap[key];
        if (cssProperty) {
            var propertyKey = cssProperty.property;
            for (var propertyIndex = 0; propertyIndex < propertyKey.length; ++propertyIndex) {
                $element.css(propertyKey[propertyIndex], cssProperty.valueFunction(value));
            }
        }
        return $element;
    }
};

L.StylesBuilder = L.Class.extend({
    initialize: function(categories, styleFunctionMap) {
        this._categories = categories;
        this._styleFunctionMap = styleFunctionMap;
        this._buildStyles();
    },
    _buildStyles: function() {
        var map = {};
        var category;
        var styleFunction;
        var styleValue;
        for (var index = 0; index < this._categories.length; ++index) {
            category = this._categories[index];
            map[category] = {};
            for (var property in this._styleFunctionMap) {
                styleFunction = this._styleFunctionMap[property];
                styleValue = styleFunction.evaluate ? styleFunction.evaluate(index) : typeof styleFunction === "function" ? styleFunction(index) : styleFunction;
                map[category][property] = styleValue;
            }
        }
        this._styleMap = map;
    },
    getStyles: function() {
        return this._styleMap;
    }
});

L.PaletteBuilder = L.Class.extend({
    initialize: function(styleFunctionMap) {
        this._styleFunctionMap = styleFunctionMap;
    },
    generate: function(options) {
        options = options || {};
        var $paletteElement = $('<div class="palette"></div>');
        var count = options.count || 10;
        var categories = function(count) {
            var categoryArray = [];
            for (var i = 0; i < count; ++i) {
                categoryArray.push(i);
            }
            return categoryArray;
        }(count);
        var styleBuilder = new L.StylesBuilder(categories, this._styleFunctionMap);
        var styles = styleBuilder.getStyles();
        if (options.className) {
            $paletteElement.addClass(options.className);
        }
        for (var styleKey in styles) {
            var $i = $('<i class="palette-element"></i>');
            var style = styles[styleKey];
            L.StyleConverter.applySVGStyle($i, style);
            $paletteElement.append($i);
        }
        return $paletteElement.wrap("<div/>").parent().html();
    }
});

L.HTMLUtils = {
    buildTable: function(obj, className, ignoreFields) {
        className = className || "table table-condensed table-striped table-bordered";
        var html = '<table class="' + className + '"><thead><tr><th>Name</th><th>Value</th></tr></thead><tbody></tbody></table>';
        var $html = $(html);
        var $tbody = $html.find("tbody");
        ignoreFields = ignoreFields || [];
        for (var property in obj) {
            if (obj.hasOwnProperty(property) && $.inArray(ignoreFields, property) === -1) {
                if ($.isPlainObject(obj[property]) || obj[property] instanceof Array) {
                    $tbody.append("<tr><td>" + property + "</td><td>" + L.HTMLUtils.buildTable(obj[property], ignoreFields).wrap("<div/>").parent().html() + "</td></tr>");
                } else {
                    $tbody.append("<tr><td>" + property + "</td><td>" + obj[property] + "</td></tr>");
                }
            }
        }
        return $html;
    }
};

L.AnimationUtils = {
    animate: function(layer, from, to, options) {
        var delay = options.delay || 0;
        var frames = options.frames || 30;
        var duration = options.duration || 500;
        var linearFunctions = {};
        var easeFunction = options.easeFunction || function(step) {
            return step;
        };
        var complete = options.complete;
        var step = duration / frames;
        for (var key in from) {
            if (key != "color" && key != "fillColor" && to[key]) {
                linearFunctions[key] = new L.LinearFunction([ 0, from[key] ], [ frames - 1, to[key] ]);
            }
        }
        var layerOptions = {};
        var frame = 0;
        var updateLayer = function() {
            for (var key in linearFunctions) {
                layerOptions[key] = linearFunctions[key].evaluate(frame);
            }
            layer.options = $.extend(true, {}, layer.options, layerOptions);
            layer.redraw();
            frame++;
            step = easeFunction(step);
            if (frame < frames) {
                setTimeout(updateLayer, step);
            } else {
                complete();
            }
        };
        setTimeout(updateLayer, delay);
    }
};

L.ColorUtils = {
    rgbArrayToString: function(rgbArray) {
        var hexValues = [];
        for (var index = 0; index < rgbArray.length; ++index) {
            var hexValue = Math.round(rgbArray[index]).toString(16);
            if (hexValue.length === 1) {
                hexValue = "0" + hexValue;
            }
            hexValues.push(hexValue);
        }
        return "#" + hexValues.join("");
    },
    rgbToHsl: function(r, g, b) {
        r /= 255, g /= 255, b /= 255;
        var max = Math.max(r, g, b), min = Math.min(r, g, b);
        var h, s, l = (max + min) / 2;
        if (max == min) {
            h = s = 0;
        } else {
            var d = max - min;
            s = l > .5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
              case r:
                h = (g - b) / d + (g < b ? 6 : 0);
                break;

              case g:
                h = (b - r) / d + 2;
                break;

              case b:
                h = (r - g) / d + 4;
                break;
            }
            h /= 6;
        }
        return [ h, s, l ];
    },
    hslToRgb: function(h, s, l) {
        var r, g, b;
        if (s == 0) {
            r = g = b = l;
        } else {
            function hue2rgb(p, q, t) {
                if (t < 0) t += 1;
                if (t > 1) t -= 1;
                if (t < 1 / 6) return p + (q - p) * 6 * t;
                if (t < 1 / 2) return q;
                if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
                return p;
            }
            var q = l < .5 ? l * (1 + s) : l + s - l * s;
            var p = 2 * l - q;
            r = hue2rgb(p, q, h + 1 / 3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1 / 3);
        }
        return [ r * 255, g * 255, b * 255 ];
    },
    rgbToHsv: function(r, g, b) {
        r = r / 255, g = g / 255, b = b / 255;
        var max = Math.max(r, g, b), min = Math.min(r, g, b);
        var h, s, v = max;
        var d = max - min;
        s = max == 0 ? 0 : d / max;
        if (max == min) {
            h = 0;
        } else {
            switch (max) {
              case r:
                h = (g - b) / d + (g < b ? 6 : 0);
                break;

              case g:
                h = (b - r) / d + 2;
                break;

              case b:
                h = (r - g) / d + 4;
                break;
            }
            h /= 6;
        }
        return [ h, s, v ];
    },
    hsvToRgb: function(h, s, v) {
        var r, g, b;
        var i = Math.floor(h * 6);
        var f = h * 6 - i;
        var p = v * (1 - s);
        var q = v * (1 - f * s);
        var t = v * (1 - (1 - f) * s);
        switch (i % 6) {
          case 0:
            r = v, g = t, b = p;
            break;

          case 1:
            r = q, g = v, b = p;
            break;

          case 2:
            r = p, g = v, b = t;
            break;

          case 3:
            r = p, g = q, b = v;
            break;

          case 4:
            r = t, g = p, b = v;
            break;

          case 5:
            r = v, g = p, b = q;
            break;
        }
        return [ r * 255, g * 255, b * 255 ];
    }
};

L.ColorUtils.hslToRgbString = function(h, s, l) {
    return L.ColorUtils.rgbArrayToString(L.ColorUtils.hslToRgb(h, s, l));
};

L.ColorUtils.hslStringToRgbString = function(hslString) {
    var parts = hslString.replace("hsl(", "").replace(")", "").split(",");
    var h = Number(parts[0]) / 360;
    var s = Number(parts[1].replace("%", "")) / 100;
    var l = Number(parts[2].replace("%", "")) / 100;
    return L.ColorUtils.hslToRgbString(h, s, l);
};

L.RegularPolygon = L.Polygon.extend({
    statics: {
        R: 6378.137,
        M_PER_KM: 1e3
    },
    initialize: function(centerLatLng, options) {
        this._centerLatLng = centerLatLng;
        L.Util.setOptions(this, options);
        L.Polygon.prototype.initialize.call(this, this._getLatLngs(), options);
    },
    options: {
        fill: true,
        radius: 1e3,
        numberOfSides: 4,
        rotation: 0,
        maxDegrees: 360
    },
    getLatLng: function() {
        return this._centerLatLng;
    },
    setRadius: function(radius) {
        this.options.radius = radius;
        this._latlngs = this._getLatLngs();
        this.redraw();
    },
    _getLatLngs: function() {
        var maxDegrees = this.options.maxDegrees || 360;
        var angleSize = maxDegrees / Math.max(this.options.numberOfSides, 3);
        var degrees = maxDegrees + this.options.rotation;
        var angle = this.options.rotation;
        var latlngs = [];
        var newLatLng;
        var angleRadians;
        var layer;
        while (angle < degrees) {
            newLatLng = this._getPoint(angle);
            latlngs.push(newLatLng);
            angle += angleSize;
        }
        return latlngs;
    },
    _getPoint: function(angle) {
        var toRad = function(number) {
            return number * L.LatLng.DEG_TO_RAD;
        };
        var toDeg = function(number) {
            return number * L.LatLng.RAD_TO_DEG;
        };
        var angleRadians = toRad(angle);
        var angularDistance = this.options.radius / L.RegularPolygon.M_PER_KM / L.RegularPolygon.R;
        var lat1 = toRad(this._centerLatLng.lat);
        var lon1 = toRad(this._centerLatLng.lng);
        var lat2 = Math.asin(Math.sin(lat1) * Math.cos(angularDistance) + Math.cos(lat1) * Math.sin(angularDistance) * Math.cos(angleRadians));
        var lon2 = lon1 + Math.atan2(Math.sin(angleRadians) * Math.sin(angularDistance) * Math.cos(lat1), Math.cos(angularDistance) - Math.sin(lat1) * Math.sin(lat2));
        lat2 = toDeg(lat2);
        lon2 = toDeg(lon2);
        return new L.LatLng(lat2, lon2);
    }
});

L.regularPolygon = function(centerLatLng, options) {
    return new L.RegularPolygon(centerLatLng, options);
};

var PathFunctions = PathFunctions || {
    __updateStyle: L.Path.prototype._updateStyle,
    _createDefs: function() {
        this._defs = this._createElement("defs");
        this._container.appendChild(this._defs);
    },
    _createGradient: function(options) {
        if (!this._defs) {
            this._createDefs();
        }
        if (this._gradient) {
            this._defs.removeChild(this._gradient);
        }
        var gradient = this._createElement("linearGradient");
        var gradientGuid = L.Util.guid();
        options = options !== true ? $.extend(true, {}, options) : {};
        var vector = options.vector || [ [ "0%", "0%" ], [ "100%", "100%" ] ];
        var vectorOptions = {
            x1: vector[0][0],
            x2: vector[1][0],
            y1: vector[0][1],
            y2: vector[1][1]
        };
        vectorOptions.id = "grad" + gradientGuid;
        var stops = options.stops || [ {
            offset: "0%",
            style: {
                color: "rgb(255, 255, 255)",
                opacity: 1
            }
        }, {
            offset: "60%",
            style: {
                color: this.options.fillColor || this.options.color,
                opacity: 1
            }
        } ];
        for (var key in vectorOptions) {
            gradient.setAttribute(key, vectorOptions[key]);
        }
        for (var i = 0; i < stops.length; ++i) {
            var stop = stops[i];
            var stopElement = this._createElement("stop");
            stop.style = stop.style || {};
            for (var key in stop) {
                var stopProperty = stop[key];
                if (key === "style") {
                    var styleProperty = "";
                    stopProperty.color = stopProperty.color || this.options.fillColor || this.options.color;
                    stopProperty.opacity = typeof stopProperty.opacity === "undefined" ? 1 : stopProperty.opacity;
                    for (var propKey in stopProperty) {
                        styleProperty += "stop-" + propKey + ":" + stopProperty[propKey] + ";";
                    }
                    stopProperty = styleProperty;
                }
                stopElement.setAttribute(key, stopProperty);
            }
            gradient.appendChild(stopElement);
        }
        this._gradient = gradient;
        this._defs.appendChild(gradient);
    },
    _createDropShadow: function(options) {
        if (!this._defs) {
            this._createDefs();
        }
        if (this._dropShadow) {
            this._defs.removeChild(this._dropShadow);
        }
        var filterGuid = L.Util.guid();
        var filter = this._createElement("filter");
        var feOffset = this._createElement("feOffset");
        var feGaussianBlur = this._createElement("feGaussianBlur");
        var feBlend = this._createElement("feBlend");
        options = options || {
            width: "200%",
            height: "200%"
        };
        options.id = "filter" + filterGuid;
        for (var key in options) {
            filter.setAttribute(key, options[key]);
        }
        var offsetOptions = {
            result: "offOut",
            "in": "SourceAlpha",
            dx: "2",
            dy: "2"
        };
        var blurOptions = {
            result: "blurOut",
            "in": "offOut",
            stdDeviation: "2"
        };
        var blendOptions = {
            "in": "SourceGraphic",
            in2: "blurOut",
            mode: "lighten"
        };
        for (var key in offsetOptions) {
            feOffset.setAttribute(key, offsetOptions[key]);
        }
        for (var key in blurOptions) {
            feGaussianBlur.setAttribute(key, blurOptions[key]);
        }
        for (var key in blendOptions) {
            feBlend.setAttribute(key, blendOptions[key]);
        }
        filter.appendChild(feOffset);
        filter.appendChild(feGaussianBlur);
        filter.appendChild(feBlend);
        this._dropShadow = filter;
        this._defs.appendChild(filter);
    },
    _updateStyle: function() {
        this.__updateStyle.call(this);
        if (this.options.stroke) {
            if (this.options.lineCap) {
                this._path.setAttribute("stroke-linecap", this.options.lineCap);
            }
            if (this.options.lineJoin) {
                this._path.setAttribute("stroke-linejoin", this.options.lineJoin);
            }
        }
        if (this.options.gradient) {
            this._createGradient(this.options.gradient);
            this._path.setAttribute("fill", "url(#" + this._gradient.getAttribute("id") + ")");
        } else if (!this.options.fill) {
            this._path.setAttribute("fill", "none");
        }
        if (this.options.dropShadow) {
            this._createDropShadow();
            this._path.setAttribute("filter", "url(#" + this._dropShadow.getAttribute("id") + ")");
        } else {
            this._path.removeAttribute("filter");
        }
    }
};

L.Path.include(PathFunctions);

L.Polygon.include(PathFunctions);

L.Polyline.include(PathFunctions);

L.CircleMarker.include(PathFunctions);

L.MapMarker = L.Path.extend({
    initialize: function(centerLatLng, options) {
        L.Path.prototype.initialize.call(this, options);
        this._latlng = centerLatLng;
    },
    options: {
        fill: true,
        fillOpacity: 1,
        opacity: 1,
        radius: 15,
        innerRadius: 5,
        position: {
            x: 0,
            y: 0
        },
        rotation: 0,
        numberOfSides: 50,
        color: "#000000",
        fillColor: "#0000FF",
        weight: 1,
        gradient: true,
        dropShadow: true
    },
    setLatLng: function(latlng) {
        this._latlng = latlng;
        return this.redraw();
    },
    projectLatlngs: function() {
        this._point = this._map.latLngToLayerPoint(this._latlng);
        this._points = this._getPoints();
        if (this.options.innerRadius) {
            this._innerPoints = this._getPoints(true).reverse();
        }
    },
    getBounds: function() {
        var map = this._map, height = this.options.radius * 3, point = map.project(this._latlng), swPoint = new L.Point(point.x - this.options.radius, point.y), nePoint = new L.Point(point.x + this.options.radius, point.y - height), sw = map.unproject(swPoint), ne = map.unproject(nePoint);
        return new L.LatLngBounds(sw, ne);
    },
    getLatLng: function() {
        return this._latlng;
    },
    getPathString: function() {
        this._path.setAttribute("shape-rendering", "geometricPrecision");
        return new L.SVGPathBuilder(this._points, this._innerPoints).build(6);
    },
    _getPoints: function(inner) {
        var maxDegrees = !inner ? 210 : 360;
        var angleSize = !inner ? maxDegrees / 50 : maxDegrees / Math.max(this.options.numberOfSides, 3);
        var degrees = !inner ? maxDegrees : maxDegrees + this.options.rotation;
        var angle = !inner ? -30 : this.options.rotation;
        var points = [];
        var newPoint;
        var angleRadians;
        var radius = this.options.radius;
        var multiplier = Math.sqrt(.75);
        var toRad = function(number) {
            return number * L.LatLng.DEG_TO_RAD;
        };
        var startPoint = this._point;
        if (!inner) {
            points.push(startPoint);
            points.push(new L.Point(startPoint.x + multiplier * radius, startPoint.y - 1.5 * radius));
        }
        while (angle < degrees) {
            angleRadians = toRad(angle);
            newPoint = this._getPoint(angleRadians, radius, inner);
            points.push(newPoint);
            angle += angleSize;
        }
        if (!inner) {
            points.push(new L.Point(startPoint.x - multiplier * radius, startPoint.y - 1.5 * radius));
        }
        return points;
    },
    _getPoint: function(angle, radius, inner) {
        var markerRadius = radius;
        radius = !inner ? radius : this.options.innerRadius;
        return new L.Point(this._point.x + this.options.position.x + radius * Math.cos(angle), this._point.y - 2 * markerRadius + this.options.position.y - radius * Math.sin(angle));
    }
});

L.mapMarker = function(centerLatLng, options) {
    return new L.MapMarker(centerLatLng, options);
};

L.RegularPolygonMarker = L.Path.extend({
    initialize: function(centerLatLng, options) {
        L.Path.prototype.initialize.call(this, options);
        this._latlng = centerLatLng;
        this.options.numberOfSides = Math.max(this.options.numberOfSides, 3);
    },
    options: {
        fill: true,
        radiusX: 10,
        radiusY: 10,
        rotation: 0,
        numberOfSides: 3,
        position: {
            x: 0,
            y: 0
        },
        maxDegrees: 360,
        gradient: true,
        dropShadow: false
    },
    setLatLng: function(latlng) {
        this._latlng = latlng;
        return this.redraw();
    },
    projectLatlngs: function() {
        this._point = this._map.latLngToLayerPoint(this._latlng);
        this._textPoint = this._point;
        this._points = this._getPoints();
        if (this.options.innerRadius || this.options.innerRadiusX && this.options.innerRadiusY) {
            this._innerPoints = this._getPoints(true).reverse();
        }
    },
    getBounds: function() {
        var map = this._map, radiusX = this.options.radius || this.options.radiusX, radiusY = this.options.radius || this.options.radiusY, deltaX = radiusX * Math.cos(Math.PI / 4), deltaY = radiusY * Math.sin(Math.PI / 4), point = map.project(this._latlng), swPoint = new L.Point(point.x - deltaX, point.y + deltaY), nePoint = new L.Point(point.x + deltaX, point.y - deltaY), sw = map.unproject(swPoint), ne = map.unproject(nePoint);
        return new L.LatLngBounds(sw, ne);
    },
    getLatLng: function() {
        return this._latlng;
    },
    getPathString: function() {
        this._path.setAttribute("shape-rendering", "geometricPrecision");
        return new L.SVGPathBuilder(this._points, this._innerPoints).build(6);
    },
    _getPoints: function(inner) {
        var maxDegrees = this.options.maxDegrees || 360;
        var angleSize = maxDegrees / Math.max(this.options.numberOfSides, 3);
        var degrees = maxDegrees + this.options.rotation;
        var angle = this.options.rotation;
        var points = [];
        var newPoint;
        var angleRadians;
        var radiusX = !inner ? this.options.radius || this.options.radiusX : this.options.innerRadius || this.options.innerRadiusX;
        var radiusY = !inner ? this.options.radius || this.options.radiusY : this.options.innerRadius || this.options.innerRadiusY;
        var toRad = function(number) {
            return number * L.LatLng.DEG_TO_RAD;
        };
        while (angle < degrees) {
            angleRadians = toRad(angle);
            newPoint = this._getPoint(angleRadians, radiusX, radiusY);
            points.push(newPoint);
            angle += angleSize;
        }
        return points;
    },
    _getPoint: function(angle, radiusX, radiusY) {
        return new L.Point(this._point.x + this.options.position.x + radiusX * Math.cos(angle), this._point.y + this.options.position.y + radiusY * Math.sin(angle));
    }
});

L.regularPolygonMarker = function(centerLatLng, options) {
    return new L.RegularPolygonMarker(centerLatLng, options);
};

L.StarMarker = L.RegularPolygonMarker.extend({
    options: {
        numberOfPoints: 5,
        rotation: -15,
        maxDegrees: 360,
        gradient: true,
        dropShadow: true
    },
    _getPoints: function(inner) {
        var maxDegrees = this.options.maxDegrees || 360;
        var angleSize = maxDegrees / this.options.numberOfPoints;
        var degrees = maxDegrees + this.options.rotation;
        var angle = this.options.rotation;
        var points = [];
        var newPoint, newPointInner;
        var angleRadians;
        var radiusX = !inner ? this.options.radius || this.options.radiusX : this.options.innerRadius || this.options.innerRadiusX;
        var radiusY = !inner ? this.options.radius || this.options.radiusY : this.options.innerRadius || this.options.innerRadiusY;
        var toRad = function(number) {
            return number * L.LatLng.DEG_TO_RAD;
        };
        while (angle < degrees) {
            angleRadians = toRad(angle);
            newPoint = this._getPoint(angleRadians, radiusX, radiusY);
            newPointInner = this._getPoint(angleRadians + toRad(angleSize) / 2, radiusX / 2, radiusY / 2);
            points.push(newPoint);
            points.push(newPointInner);
            angle += angleSize;
        }
        return points;
    }
});

L.starMarker = function(centerLatLng, options) {
    return new L.StarMarker(centerLatLng, options);
};

L.TriangleMarker = L.RegularPolygonMarker.extend({
    options: {
        numberOfSides: 3,
        rotation: 30,
        radius: 5
    }
});

L.triangleMarker = function(centerLatLng, options) {
    return new L.TriangleMarker(centerLatLng, options);
};

L.DiamondMarker = L.RegularPolygonMarker.extend({
    options: {
        numberOfSides: 4,
        radiusX: 5,
        radiusY: 10
    }
});

L.diamondMarker = function(centerLatLng, options) {
    return new L.DiamondMarker(centerLatLng, options);
};

L.SquareMarker = L.RegularPolygonMarker.extend({
    options: {
        numberOfSides: 4,
        rotation: 45,
        radius: 5
    }
});

L.squareMarker = function(centerLatLng, options) {
    return new L.SquareMarker(centerLatLng, options);
};

L.PentagonMarker = L.RegularPolygonMarker.extend({
    options: {
        numberOfSides: 5,
        rotation: -18,
        radius: 5
    }
});

L.pentagonMarker = function(centerLatLng, options) {
    return new L.PentagonMarker(centerLatLng, options);
};

L.HexagonMarker = L.RegularPolygonMarker.extend({
    options: {
        numberOfSides: 6,
        rotation: 30,
        radius: 5
    }
});

L.hexagonMarker = function(centerLatLng, options) {
    return new L.HexagonMarker(centerLatLng, options);
};

L.OctagonMarker = L.RegularPolygonMarker.extend({
    options: {
        numberOfSides: 8,
        rotation: 22.5,
        radius: 5
    }
});

L.octagonMarker = function(centerLatLng, options) {
    return new L.OctagonMarker(centerLatLng, options);
};

L.BarMarker = L.Path.extend({
    initialize: function(centerLatLng, options) {
        L.Path.prototype.initialize.call(this, options);
        this._latlng = centerLatLng;
    },
    options: {
        fill: true,
        width: 2,
        maxHeight: 10,
        position: {
            x: 0,
            y: 0
        },
        weight: 1,
        color: "#000",
        opacity: 1,
        gradient: true,
        dropShadow: false,
        lineCap: "square",
        lineJoin: "miter"
    },
    setLatLng: function(latlng) {
        this._latlng = latlng;
        return this.redraw();
    },
    projectLatlngs: function() {
        this._point = this._map.latLngToLayerPoint(this._latlng);
        this._points = this._getPoints();
    },
    getBounds: function() {
        var map = this._map, point = map.project(this._latlng), halfWidth = this.options.width / 2, swPoint = new L.Point(point.x - halfWidth, point.y), nePoint = new L.Point(point.x + halfWidth, point.y - this.options.maxHeight), sw = map.unproject(swPoint), ne = map.unproject(nePoint);
        return new L.LatLngBounds(sw, ne);
    },
    getLatLng: function() {
        return this._latlng;
    },
    getPathString: function() {
        this._path.setAttribute("shape-rendering", "crispEdges");
        return new L.SVGPathBuilder(this._points).build();
    },
    _getPoints: function() {
        var points = [];
        var startX = this._point.x + this.options.position.x;
        var startY = this._point.y + this.options.position.y;
        var halfWidth = this.options.width / 2;
        var sePoint, nePoint, nwPoint, swPoint;
        var height = this.options.value / this.options.maxValue * this.options.maxHeight;
        sePoint = new L.Point(startX + halfWidth, startY);
        nePoint = new L.Point(startX + halfWidth, startY - height);
        nwPoint = new L.Point(startX - halfWidth, startY - height);
        swPoint = new L.Point(startX - halfWidth, startY);
        points = [ sePoint, nePoint, nwPoint, swPoint ];
        return points;
    }
});

L.barMarker = function(centerLatLng, options) {
    return new L.BarMarker(centerLatLng, options);
};

L.ChartMarker = L.FeatureGroup.extend({
    initialize: function(centerLatLng, options) {
        L.Util.setOptions(this, options);
        this._layers = {};
        this._latlng = centerLatLng;
        this._loadComponents();
    },
    setLatLng: function(latlng) {
        this._latlng = latlng;
        return this.redraw();
    },
    getLatLng: function() {
        return this._latlng;
    },
    _loadComponents: function() {},
    _highlight: function(options) {
        if (options.weight) {
            options.weight *= 2;
        }
        return options;
    },
    _unhighlight: function(options) {
        if (options.weight) {
            options.weight /= 2;
        }
        return options;
    },
    _bindMouseEvents: function(chartElement) {
        var self = this;
        var tooltipOptions = this.options.tooltipOptions;
        chartElement.on("mouseover", function(e) {
            var currentOptions = this.options;
            var key = currentOptions.key;
            var value = currentOptions.value;
            var layerPoint = e.layerPoint;
            var x = layerPoint.x - this._point.x;
            var y = layerPoint.y - this._point.y;
            var iconSize = currentOptions.iconSize;
            var newX = x;
            var newY = y;
            var newPoint;
            var offset = 5;
            newX = x < 0 ? iconSize.x - x + offset : -x - offset;
            newY = y < 0 ? iconSize.y - y + offset : -y - offset;
            newPoint = new L.Point(newX, newY);
            var legendOptions = {};
            var displayText = currentOptions.displayText ? currentOptions.displayText(value) : value;
            legendOptions[key] = {
                name: currentOptions.displayName,
                value: displayText
            };
            var icon = new L.LegendIcon(legendOptions, currentOptions, {
                className: "leaflet-div-icon",
                iconSize: tooltipOptions ? tooltipOptions.iconSize : iconSize,
                iconAnchor: newPoint
            });
            currentOptions.marker = new L.Marker(self._latlng, {
                icon: icon
            });
            currentOptions = self._highlight(currentOptions);
            this.initialize(self._latlng, currentOptions);
            this.redraw();
            this.setStyle(currentOptions);
            self.addLayer(currentOptions.marker);
        });
        chartElement.on("mouseout", function(e) {
            var currentOptions = this.options;
            currentOptions = self._unhighlight(currentOptions);
            this.initialize(self._latlng, currentOptions);
            this.redraw();
            this.setStyle(currentOptions);
            self.removeLayer(currentOptions.marker);
        });
    },
    bindPopup: function(content, options) {
        this.eachLayer(function(layer) {
            layer.bindPopup(content, options);
        });
    },
    openPopup: function(latlng) {
        for (var i in this._layers) {
            var layer = this._layers[i];
            latlng = latlng || this._latlng;
            layer.openPopup(latlng);
            break;
        }
    },
    closePopup: function() {
        for (var i in this._layers) {
            var layer = this._layers[i];
            latlng = latlng || this._latlng;
            layer.closePopup();
            break;
        }
    }
});

L.BarChartMarker = L.ChartMarker.extend({
    initialize: function(centerLatLng, options) {
        L.Util.setOptions(this, options);
        L.ChartMarker.prototype.initialize.call(this, centerLatLng, options);
    },
    options: {
        weight: 1,
        opacity: 1,
        color: "#000",
        fill: true,
        position: {
            x: 0,
            y: 0
        },
        width: 10,
        offset: 0,
        iconSize: new L.Point(50, 40)
    },
    _loadComponents: function() {
        var value, minValue, maxValue;
        var angle = this.options.rotation;
        var percentage = 0;
        var maxDegrees = this.options.maxDegrees || 360;
        var bar;
        var options = this.options;
        var dataPoint;
        var lastRadiusX = this.options.radiusX || this.options.radius;
        var lastRadiusY = this.options.radiusY || this.options.radius;
        var x;
        var y;
        var keys = Object.keys(this.options.data);
        var count = keys.length;
        var width = this.options.width;
        var offset = this.options.offset || 0;
        var data = this.options.data;
        var chartOptions = this.options.chartOptions;
        var chartOption;
        x = -(width * count + offset * (count - 1)) / 2 + width / 2;
        y = 0;
        for (var key in data) {
            value = data[key];
            chartOption = chartOptions[key];
            minValue = chartOption.minValue || 0;
            maxValue = chartOption.maxValue || 100;
            var range = maxValue - minValue;
            options.fillColor = chartOption.fillColor || this.options.fillColor;
            options.value = value;
            options.minValue = minValue;
            options.maxValue = maxValue;
            options.position = {
                x: x,
                y: y
            };
            options.width = width;
            options.maxHeight = chartOption.maxHeight || 10;
            options.key = key;
            options.value = value;
            options.displayName = chartOption.displayName;
            options.opacity = this.options.opacity || 1;
            options.fillOpacity = this.options.fillOpacity || .7;
            options.weight = this.options.weight || 1;
            options.color = chartOption.color || this.options.color;
            options.displayText = chartOption.displayText;
            bar = new L.BarMarker(this._latlng, options);
            this._bindMouseEvents(bar);
            this.addLayer(bar);
            x += width + offset;
        }
    }
});

L.RadialBarMarker = L.Path.extend({
    initialize: function(centerLatLng, options) {
        L.Path.prototype.initialize.call(this, options);
        this._latlng = centerLatLng;
    },
    options: {
        fill: true,
        radius: 10,
        rotation: 0,
        numberOfSides: 30,
        position: {
            x: 0,
            y: 0
        },
        gradient: true,
        dropShadow: false
    },
    setLatLng: function(latlng) {
        this._latlng = latlng;
        return this.redraw();
    },
    projectLatlngs: function() {
        this._point = this._map.latLngToLayerPoint(this._latlng);
        this._points = this._getPoints();
    },
    getBounds: function() {
        var map = this._map, radiusX = this.options.radiusX || this.options.radius, radiusY = this.options.radiusY || this.options.radius, deltaX = radiusX * Math.cos(Math.PI / 4), deltaY = radiusY * Math.sin(Math.PI / 4), point = map.project(this._latlng), swPoint = new L.Point(point.x - deltaX, point.y + deltaY), nePoint = new L.Point(point.x + deltaX, point.y - deltaY), sw = map.unproject(swPoint), ne = map.unproject(nePoint);
        return new L.LatLngBounds(sw, ne);
    },
    getLatLng: function() {
        return this._latlng;
    },
    getPathString: function() {
        var angle = this.options.endAngle - this.options.startAngle;
        var largeArc = angle >= 180 ? "1" : "0";
        var radiusX = this.options.radiusX || this.options.radius;
        var radiusY = this.options.radiusY || this.options.radius;
        var path = "M" + this._points[0].x.toFixed(2) + "," + this._points[0].y.toFixed(2) + "A" + radiusX.toFixed(2) + "," + radiusY.toFixed(2) + " 0 " + largeArc + ",1 " + this._points[1].x.toFixed(2) + "," + this._points[1].y.toFixed(2) + "L";
        if (this._innerPoints) {
            path = path + this._innerPoints[0].x.toFixed(2) + "," + this._innerPoints[0].y.toFixed(2);
            path = path + "A" + (radiusX - this.options.barThickness).toFixed(2) + "," + (radiusY - this.options.barThickness).toFixed(2) + " 0 " + largeArc + ",0 " + this._innerPoints[1].x.toFixed(2) + "," + this._innerPoints[1].y.toFixed(2) + "z";
        } else {
            path = path + this._point.x.toFixed(2) + "," + this._point.y.toFixed(2) + "z";
        }
        if (L.Browser.vml) {
            path = Core.SVG.path(path);
        }
        this._path.setAttribute("shape-rendering", "geometricPrecision");
        return path;
    },
    _getPoints: function() {
        var angleDelta = this.options.endAngle - this.options.startAngle;
        var angleSize = angleDelta / this.options.numberOfSides;
        var degrees = this.options.endAngle + this.options.rotation;
        var angle = this.options.startAngle + this.options.rotation;
        var points = [];
        var innerPoints = [];
        var newPoint, innerPoint;
        var angleRadians;
        var radiusX = "radiusX" in this.options ? this.options.radiusX : this.options.radius;
        var radiusY = "radiusY" in this.options ? this.options.radiusY : this.options.radius;
        var toRad = function(number) {
            return number * L.LatLng.DEG_TO_RAD;
        };
        if (angleDelta === 360) {
            degrees = degrees - .1;
        }
        var startRadians = toRad(angle);
        var endRadians = toRad(degrees);
        points.push(this._getPoint(startRadians, radiusX, radiusY));
        points.push(this._getPoint(endRadians, radiusX, radiusY));
        if (this.options.barThickness) {
            this._innerPoints = [];
            var innerRadiusX = radiusX - this.options.barThickness;
            var innerRadiusY = radiusY - this.options.barThickness;
            this._innerPoints.push(this._getPoint(endRadians, radiusX - this.options.barThickness, radiusY - this.options.barThickness));
            this._innerPoints.push(this._getPoint(startRadians, radiusX - this.options.barThickness, radiusY - this.options.barThickness));
        }
        return points;
    },
    _getPoint: function(angle, radiusX, radiusY) {
        return new L.Point(this._point.x + this.options.position.x + radiusX * Math.cos(angle), this._point.y + this.options.position.y + radiusY * Math.sin(angle));
    }
});

L.radialBarMarker = function(centerLatLng, options) {
    return new L.RadialBarMarker(centerLatLng, options);
};

L.PieChartMarker = L.ChartMarker.extend({
    initialize: function(centerLatLng, options) {
        L.Util.setOptions(this, options);
        L.ChartMarker.prototype.initialize.call(this, centerLatLng, options);
    },
    options: {
        weight: 1,
        opacity: 1,
        color: "#000",
        fill: true,
        radius: 10,
        rotation: 0,
        numberOfSides: 50,
        mouseOverExaggeration: 1.2,
        maxDegrees: 360,
        iconSize: new L.Point(50, 40)
    },
    _highlight: function(options) {
        var oldRadiusX = options.radiusX;
        var oldRadiusY = options.radiusY;
        var oldBarThickness = options.barThickness;
        options.oldBarThickness = oldBarThickness;
        options.oldRadiusX = oldRadiusX;
        options.oldRadiusY = oldRadiusY;
        options.radiusX *= options.mouseOverExaggeration;
        options.radiusY *= options.mouseOverExaggeration;
        options.barThickness = options.radiusX - oldRadiusX + oldBarThickness;
        return options;
    },
    _unhighlight: function(options) {
        options.radiusX = options.oldRadiusX;
        options.radiusY = options.oldRadiusY;
        options.barThickness = options.oldBarThickness;
        return options;
    },
    _loadComponents: function() {
        var value;
        var sum = 0;
        var angle = 0;
        var percentage = 0;
        var maxDegrees = this.options.maxDegrees || 360;
        var lastAngle = this.options.rotation;
        var bar;
        var options = this.options;
        var dataPoint;
        var data = this.options.data;
        var chartOptions = this.options.chartOptions;
        var chartOption;
        var key;
        var getValue = function(data, key) {
            var value = 0;
            if (data[key]) {
                value = parseFloat(data[key]);
            }
            return value;
        };
        for (key in data) {
            value = getValue(data, key);
            sum += value;
        }
        if (sum > 0) {
            for (key in data) {
                value = parseFloat(data[key]);
                chartOption = chartOptions[key];
                percentage = value / sum;
                angle = percentage * maxDegrees;
                options.startAngle = lastAngle;
                options.endAngle = lastAngle + angle;
                options.fillColor = chartOption.fillColor;
                options.color = chartOption.color || "#000";
                options.radiusX = this.options.radiusX || this.options.radius;
                options.radiusY = this.options.radiusY || this.options.radius;
                options.rotation = 0;
                options.key = key;
                options.value = value;
                options.displayName = chartOption.displayName;
                options.displayText = chartOption.displayText;
                bar = new L.RadialBarMarker(this._latlng, options);
                this._bindMouseEvents(bar);
                lastAngle = options.endAngle;
                this.addLayer(bar);
            }
        }
    }
});

L.pieChartMarker = function(centerLatLng, options) {
    return new L.PieChartMarker(centerLatLng, options);
};

L.CoxcombChartMarker = L.PieChartMarker.extend({
    statics: {
        SIZE_MODE_RADIUS: "radius",
        SIZE_MODE_AREA: "area"
    }
});

L.CoxcombChartMarker = L.CoxcombChartMarker.extend({
    initialize: function(centerLatLng, options) {
        L.Util.setOptions(this, options);
        L.PieChartMarker.prototype.initialize.call(this, centerLatLng, options);
    },
    options: {
        weight: 1,
        opacity: 1,
        color: "#000",
        fill: true,
        radius: 10,
        rotation: 0,
        numberOfSides: 50,
        mouseOverExaggeration: 1.2,
        maxDegrees: 360,
        iconSize: new L.Point(50, 40),
        sizeMode: L.CoxcombChartMarker.SIZE_MODE_AREA
    },
    _loadComponents: function() {
        var value, minValue, maxValue;
        var sum = 0;
        var angle = 0;
        var percentage = 0;
        var maxDegrees = this.options.maxDegrees || 360;
        var lastAngle = this.options.rotation;
        var bar;
        var options = this.options;
        var dataPoint;
        var radiusX = "radiusX" in this.options ? this.options.radiusX : this.options.radius;
        var radiusY = "radiusY" in this.options ? this.options.radiusY : this.options.radius;
        var keys = Object.keys(this.options.data);
        var count = keys.length;
        var data = this.options.data;
        var chartOptions = this.options.chartOptions;
        var chartOption;
        angle = maxDegrees / count;
        for (var key in data) {
            value = parseFloat(data[key]);
            chartOption = chartOptions[key];
            var minValue = chartOption.minValue || 0;
            var maxValue = chartOption.maxValue;
            if (this.options.sizeMode === L.CoxcombChartMarker.SIZE_MODE_RADIUS) {
                var evalFunctionX = new L.LinearFunction(new L.Point(minValue, 0), new L.Point(maxValue, radiusX));
                var evalFunctionY = new L.LinearFunction(new L.Point(minValue, 0), new L.Point(maxValue, radiusY));
                options.radiusX = evalFunctionX.evaluate(value);
                options.radiusY = evalFunctionY.evaluate(value);
            } else {
                var radius = Math.max(radiusX, radiusY);
                var maxArea = Math.PI * Math.pow(radius, 2) / count;
                var evalFunctionArea = new L.LinearFunction(new L.Point(minValue, 0), new L.Point(maxValue, maxArea), {
                    postProcess: function(value) {
                        return Math.sqrt(count * value / Math.PI);
                    }
                });
                options.radiusX = evalFunctionArea.evaluate(value);
                options.radiusY = options.radiusX;
            }
            options.startAngle = lastAngle;
            options.endAngle = lastAngle + angle;
            options.fillColor = chartOption.fillColor;
            options.color = chartOption.color || "#000";
            options.rotation = 0;
            options.key = key;
            options.value = value;
            options.displayName = chartOption.displayName;
            options.displayText = chartOption.displayText;
            bar = new L.RadialBarMarker(this._latlng, options);
            this._bindMouseEvents(bar);
            lastAngle = options.endAngle;
            this.addLayer(bar);
        }
    }
});

L.coxcombChartMarker = function(centerLatLng, options) {
    return new L.CoxcombChartMarker(centerLatLng, options);
};

L.RadialBarChartMarker = L.ChartMarker.extend({
    initialize: function(centerLatLng, options) {
        L.Util.setOptions(this, options);
        L.ChartMarker.prototype.initialize.call(this, centerLatLng, options);
    },
    options: {
        weight: 1,
        opacity: 1,
        color: "#000",
        fill: true,
        radius: 10,
        rotation: 0,
        numberOfSides: 30,
        offset: 2,
        barThickness: 5,
        maxDegrees: 360,
        iconSize: new L.Point(50, 40)
    },
    _loadComponents: function() {
        var value, minValue, maxValue;
        var angle = this.options.rotation;
        var percentage = 0;
        var maxDegrees = this.options.maxDegrees || 360;
        var bar;
        var options = this.options;
        var dataPoint;
        var count = 0;
        var lastRadiusX = this.options.radiusX || this.options.radius;
        var lastRadiusY = this.options.radiusY || this.options.radius;
        var data = this.options.data;
        var chartOptions = this.options.chartOptions;
        var chartOption;
        var barThickness = this.options.barThickness || 4;
        var offset = this.options.offset || 2;
        for (var key in data) {
            value = parseFloat(data[key]);
            chartOption = chartOptions[key];
            minValue = chartOption.minValue || 0;
            maxValue = chartOption.maxValue || 100;
            var angleFunction = new L.LinearFunction(new L.Point(minValue, 0), new L.Point(maxValue, maxDegrees));
            angle = angleFunction.evaluate(value);
            options.startAngle = this.options.rotation;
            options.endAngle = this.options.rotation + angle;
            options.fillColor = chartOption.fillColor;
            options.radiusX = lastRadiusX;
            options.radiusY = lastRadiusY;
            options.barThickness = barThickness;
            options.rotation = 0;
            options.key = key;
            options.value = value;
            options.displayName = chartOption.displayName;
            options.displayText = chartOption.displayText;
            options.weight = this.options.weight || 1;
            bar = new L.RadialBarMarker(this._latlng, options);
            this._bindMouseEvents(bar);
            this.addLayer(bar);
            lastRadiusX += barThickness + offset;
            lastRadiusY += barThickness + offset;
        }
    }
});

L.radialBarChartMarker = function(centerLatLng, options) {
    return new L.RadialBarChartMarker(centerLatLng, options);
};

L.StackedRegularPolygonMarker = L.ChartMarker.extend({
    options: {
        iconSize: new L.Point(50, 40)
    },
    initialize: function(centerLatLng, options) {
        L.Util.setOptions(this, options);
        L.ChartMarker.prototype.initialize.call(this, centerLatLng, options);
    },
    _loadComponents: function() {
        var value;
        var lastRadiusX = 0;
        var lastRadiusY = 0;
        var bar;
        var options = this.options;
        var data = this.options.data;
        var chartOptions = this.options.chartOptions;
        var chartOption;
        var key;
        for (key in data) {
            value = parseFloat(data[key]);
            chartOption = chartOptions[key];
            minValue = chartOption.minValue || 0;
            maxValue = chartOption.maxValue || 100;
            minRadius = chartOption.minRadius || 0;
            maxRadius = chartOption.maxRadius || 10;
            options.fillColor = chartOption.fillColor || this.options.fillColor;
            options.value = value;
            options.minValue = minValue;
            options.maxValue = maxValue;
            var evalFunction = new L.LinearFunction(new L.Point(minValue, minRadius), new L.Point(maxValue, maxRadius));
            var barThickness = evalFunction.evaluate(value);
            options.radiusX = lastRadiusX + barThickness;
            options.radiusY = lastRadiusY + barThickness;
            options.innerRadiusX = lastRadiusX;
            options.innerRadiusY = lastRadiusY;
            options.key = key;
            options.displayName = chartOption.displayName;
            options.opacity = this.options.opacity || 1;
            options.fillOpacity = this.options.fillOpacity || .7;
            options.weight = this.options.weight || 1;
            options.color = chartOption.color || this.options.color;
            options.displayText = chartOption.displayText;
            bar = new L.RegularPolygonMarker(this._latlng, options);
            this._bindMouseEvents(bar);
            lastRadiusX = options.radiusX;
            lastRadiusY = options.radiusY;
            this.addLayer(bar);
        }
    }
});

L.RadialMeterMarker = L.ChartMarker.extend({
    initialize: function(centerLatLng, options) {
        L.Util.setOptions(this, options);
        L.ChartMarker.prototype.initialize.call(this, centerLatLng, options);
    },
    options: {
        weight: 1,
        opacity: 1,
        color: "#000",
        fill: true,
        radius: 10,
        rotation: 180,
        numberOfSides: 30,
        offset: 2,
        barThickness: 5,
        maxDegrees: 180,
        iconSize: new L.Point(50, 40),
        backgroundStyle: {
            fill: true,
            fillColor: "#707070",
            fillOpacity: .2,
            opacity: .8,
            color: "#505050"
        }
    },
    _loadComponents: function() {
        var value, minValue, maxValue;
        var startAngle = this.options.rotation;
        var maxDegrees = this.options.maxDegrees || 360;
        var bar;
        var options = this.options;
        var radiusX = this.options.radiusX || this.options.radius;
        var radiusY = this.options.radiusY || this.options.radius;
        var data = this.options.data;
        var chartOptions = this.options.chartOptions;
        var chartOption;
        var barThickness = this.options.barThickness || 4;
        var lastAngle = startAngle;
        var numSegments = this.options.numSegments || 10;
        var angleDelta = maxDegrees / numSegments;
        var displayOptions;
        for (var key in data) {
            value = parseFloat(data[key]);
            chartOption = chartOptions[key];
            displayOptions = this.options.displayOptions ? this.options.displayOptions[key] : {};
            minValue = chartOption.minValue || 0;
            maxValue = chartOption.maxValue || 100;
            var range = maxValue - minValue;
            var angle = maxDegrees / range * (value - minValue);
            var endAngle = startAngle + angle;
            var maxAngle = startAngle + maxDegrees;
            var evalFunction = new L.LinearFunction(new L.Point(startAngle, minValue), new L.Point(maxAngle, maxValue));
            while (lastAngle < endAngle) {
                options.startAngle = lastAngle;
                var delta = Math.min(angleDelta, endAngle - lastAngle);
                options.endAngle = lastAngle + delta;
                options.fillColor = chartOption.fillColor;
                options.radiusX = radiusX;
                options.radiusY = radiusY;
                options.barThickness = barThickness;
                options.rotation = 0;
                options.key = key;
                options.value = value;
                options.displayName = chartOption.displayName;
                options.displayText = chartOption.displayText;
                var evalValue = evalFunction.evaluate(lastAngle + delta);
                for (var displayKey in displayOptions) {
                    options[displayKey] = displayOptions[displayKey].evaluate ? displayOptions[displayKey].evaluate(evalValue) : displayOptions[displayKey];
                }
                bar = new L.RadialBarMarker(this._latlng, options);
                this._bindMouseEvents(bar);
                this.addLayer(bar);
                lastAngle += delta;
            }
            if (this.options.backgroundStyle) {
                if (lastAngle < maxAngle) {
                    var delta = maxAngle - lastAngle;
                    options.endAngle = lastAngle + delta;
                    options.radiusX = radiusX;
                    options.radiusY = radiusY;
                    options.barThickness = barThickness;
                    options.rotation = 0;
                    options.key = key;
                    options.value = value;
                    options.displayName = chartOption.displayName;
                    options.displayText = chartOption.displayText;
                    options.fillColor = null;
                    options.fill = false;
                    options.gradient = false;
                    for (var property in this.options.backgroundStyle) {
                        options[property] = this.options.backgroundStyle[property];
                    }
                    var evalValue = evalFunction.evaluate(lastAngle + delta);
                    bar = new L.RadialBarMarker(this._latlng, options);
                    this.addLayer(bar);
                }
            }
        }
    }
});

L.LocationModes = {
    LATLNG: function(record, index) {
        var latitude = L.Util.getFieldValue(record, this.options.latitudeField);
        var longitude = L.Util.getFieldValue(record, this.options.longitudeField);
        var self = this;
        var getLocation = function(latitudeField, longitudeField) {
            var latitude = L.Util.getFieldValue(record, latitudeField);
            var longitude = L.Util.getFieldValue(record, longitudeField);
            var location = null;
            if (latitude && longitude) {
                var latlng = new L.LatLng(latitude, longitude);
                location = {
                    location: latlng,
                    text: [ latlng.lat.toFixed(3), latlng.lng.toFixed(3) ].join(", "),
                    center: latlng
                };
            }
            return location;
        };
        var location = getLocation(this.options.latitudeField, this.options.longitudeField);
        if (!location && this.options.fallbackLocationFields) {
            var index = 0;
            var fallbackLocationFields;
            while (!location && index < this.options.fallbackLocationFields.length) {
                fallbackLocationFields = this.options.fallbackLocationFields[index];
                location = getLocation(fallbackLocationFields.latitudeField, fallbackLocationFields.longitudeField);
                index++;
            }
        }
        return location;
    },
    GEOHASH: function(record, index) {
        var geohash = this.options.geohashField ? L.Util.getFieldValue(record, this.options.geohashField) : index;
        var locationInfo = decodeGeoHash(geohash);
        var bounds;
        if (locationInfo.latitude[2] && locationInfo.longitude[2]) {
            bounds = new L.LatLngBounds(new L.LatLng(locationInfo.latitude[0], locationInfo.longitude[0]), new L.LatLng(locationInfo.latitude[1], locationInfo.longitude[1]));
        }
        return {
            location: bounds,
            text: geohash,
            center: bounds.getCenter()
        };
    },
    COUNTRY: function(record, index) {
        var code = this.options.codeField ? L.Util.getFieldValue(record, this.options.codeField) : index;
        var geoJSON;
        var centroid;
        var codeLookup = L.codeLookup || {};
        var alpha2Lookup = L.alpha2Lookup || {};
        var fips2Lookup = L.fips2Lookup || {};
        var gwNoLookup = L.gwNoLookup || {};
        var countries = L.countries || {};
        var countryCentroids = L.countryCentroids || {};
        var originalCode = code.toUpperCase();
        code = originalCode;
        var gwNo = originalCode in gwNoLookup;
        if (gwNo) {
            code = gwNoLookup[originalCode] || code;
        } else if (code.length === 2) {
            code = alpha2Lookup[originalCode] || fips2Lookup[originalCode];
        } else if (code.length === 3) {
            code = codeLookup[originalCode] || code;
        }
        if (code) {
            geoJSON = countries[code];
            centroid = countryCentroids[code];
        } else {
            console.log("Code not found: " + originalCode);
        }
        var geoJSONLayer = new L.GeoJSON(geoJSON);
        return {
            location: geoJSONLayer,
            text: L.GeometryUtils.getName(geoJSON) || code,
            center: centroid
        };
    },
    STATE: function(record, index) {
        var code = this.options.codeField ? L.Util.getFieldValue(record, this.options.codeField) : index;
        var geoJSON;
        var centroid;
        var states = L.states || {};
        var stateCentroids = L.stateCentroids || {};
        var originalCode = code.toUpperCase();
        code = originalCode;
        geoJSON = states[code];
        centroid = stateCentroids[code];
        var geoJSONLayer = new L.GeoJSON(geoJSON);
        return {
            location: geoJSONLayer,
            text: L.GeometryUtils.getName(geoJSON) || code,
            center: centroid
        };
    },
    GEOJSON: function(record, index) {
        var locationField = this.options.geoJSONField;
        var geoJSON = locationField ? L.Util.getFieldValue(record, locationField) : record;
        var location = null;
        if (geoJSON) {
            var me = this;
            var recordToLayer = function(location, record) {
                return me.recordToLayer(location, record);
            };
            location = L.GeometryUtils.getGeoJSONLocation(geoJSON, record, this.options.locationTextField, recordToLayer);
        }
        return location;
    },
    LOOKUP: function(record, index) {
        var code = this.options.codeField ? L.Util.getFieldValue(record, this.options.codeField) : index;
        this._lookupIndex = this._lookupIndex || L.GeometryUtils.indexFeatureCollection(this.options.locationLookup, this.options.codeField);
        var geoJSON = this._lookupIndex[code];
        var location = null;
        if (geoJSON) {
            var me = this;
            var recordToLayer = function(location, record) {
                return me.recordToLayer(location, record);
            };
            location = L.GeometryUtils.getGeoJSONLocation(geoJSON, record, this.options.locationTextField, recordToLayer);
        }
        return location;
    },
    CUSTOM: function(record, index) {
        var locationField = this.options.codeField;
        var fieldValue = L.Util.getFieldValue(record, locationField);
        var context = {};
        var location;
        context[fieldValue] = record;
        if (this.options.getLocation) {
            var self = this;
            var callback = function(key, location) {
                self.locationToLayer(location, context[key]);
            };
            location = this.options.getLocation(context, locationField, [ fieldValue ], callback);
        }
        return location;
    }
};

L.DataLayer = L.LayerGroup.extend({
    initialize: function(data, options) {
        L.Util.setOptions(this, options);
        L.LayerGroup.prototype.initialize.call(this, options);
        data = data || {};
        this._boundaryLayer = new L.LayerGroup();
        this.addLayer(this._boundaryLayer);
        this.addData(data);
    },
    _zoomFunction: function(e) {
        var map = this._map;
        var self = this;
        var zoom = map.getZoom();
        if (this.options.maxZoom && zoom > this.options.maxZoom) {
            this.hiddenLayers = [];
            this.eachLayer(function(layer) {
                self.hiddenLayers.push(layer);
                map.removeLayer(layer);
            });
        } else if (this.hiddenLayers) {
            while (this.hiddenLayers.length > 0) {
                var layer = this.hiddenLayers.pop();
                map.addLayer(layer);
                if (this.options.backgroundLayer && layer.bringToBack) {
                    layer.bringToBack();
                }
            }
            this.hiddenLayers = null;
        }
    },
    onAdd: function(map) {
        L.LayerGroup.prototype.onAdd.call(this, map);
        map.on("zoomend", this._zoomFunction, this);
    },
    onRemove: function(map) {
        L.LayerGroup.prototype.onRemove.call(this, map);
        map.off("zoomend", this._zoomFunction, this);
    },
    getBounds: function() {
        var bounds;
        this.eachLayer(function(layer) {
            if (layer.getBounds) {
                if (!bounds) {
                    bounds = layer.getBounds();
                } else {
                    bounds.extend(layer.getBounds());
                }
            }
        });
        return bounds;
    },
    options: {
        recordsField: "features",
        locationMode: L.LocationModes.LATLNG,
        latitudeField: "geometry.coordinates.1",
        longitudeField: "geometry.coordinates.0",
        displayField: null,
        displayOptions: null,
        layerOptions: {
            numberOfSides: 4,
            radius: 10,
            weight: 1,
            color: "#000"
        },
        showLegendTooltips: true,
        tooltipOptions: {
            iconSize: new L.Point(60, 50),
            iconAnchor: new L.Point(-5, 50),
            mouseOverExaggeration: 2
        },
        setHighlight: function(layerStyle) {
            layerStyle.weight = layerStyle.weight || 1;
            layerStyle.fillOpacity = layerStyle.fillOpacity || .5;
            layerStyle.weight *= 2;
            layerStyle.fillOpacity /= 1.5;
            return layerStyle;
        },
        unsetHighlight: function(layerStyle) {
            layerStyle.weight = layerStyle.weight || 1;
            layerStyle.fillOpacity = layerStyle.fillOpacity || .25;
            layerStyle.weight /= 2;
            layerStyle.fillOpacity *= 1.5;
            return layerStyle;
        }
    },
    _getLocation: function(record, index) {
        var location;
        return this.options.locationMode.call(this, record, index);
    },
    _processLocation: function(location) {
        var processedLocation = location.center;
        return processedLocation;
    },
    _addBoundary: function(location, options) {
        var layer = location.location;
        if (this.options.includeBoundary) {
            if (layer instanceof L.LatLngBounds) {
                layer = new L.Rectangle(layer);
            }
            if (layer.setStyle) {
                var style = this.options.boundaryStyle || $.extend(true, {}, options, {
                    fillOpacity: .2,
                    clickable: false
                });
                layer.setStyle(style);
            }
            this._boundaryLayer.addLayer(layer);
        }
    },
    _getLayer: function(location, options, record) {
        this._addBoundary(location, options);
        location = this._processLocation(location);
        return this._getMarker(location, options, record);
    },
    _getMarker: function(location, options, record) {
        var marker;
        if (location) {
            if (options.numberOfSides >= 30 && !(options.innerRadius || options.innerRadiusX && options.innerRadiusY)) {
                marker = new L.CircleMarker(location, options);
            } else {
                marker = new L.RegularPolygonMarker(location, options);
            }
        }
        return marker;
    },
    _preProcessRecords: function(records) {
        return records;
    },
    _shouldLoadRecord: function(record) {
        return this._includeFunction ? this._includeFunction.call(this, record) : true;
    },
    _loadRecords: function(records) {
        var location;
        var includeFunction = this.options.filter || this.options.includeLayer;
        this._includeFunction = includeFunction;
        records = this._preProcessRecords(records);
        for (var recordIndex in records) {
            if (records.hasOwnProperty(recordIndex)) {
                var record = records[recordIndex];
                var includeLayer = includeFunction ? includeFunction.call(this, record) : true;
                if (includeLayer) {
                    location = this._getLocation(record, recordIndex);
                    this.locationToLayer(location, record);
                }
            }
        }
    },
    _preloadLocations: function(records) {
        var locationField = this.options.codeField;
        var locationValues = [];
        var indexedRecords = {};
        for (var recordIndex in records) {
            if (records.hasOwnProperty(recordIndex)) {
                var record = records[recordIndex];
                var fieldValue = L.Util.getFieldValue(record, locationField);
                indexedRecords[fieldValue] = record;
                locationValues.push(fieldValue);
            }
        }
        if (this.options.getLocation) {
            var self = this;
            var callback = function(key, location) {
                self.locationToLayer(location, indexedRecords[key]);
            };
            this.options.getLocation(indexedRecords, locationField, locationValues, callback);
        }
    },
    setDisplayOptions: function(displayOptions) {
        this.options.displayOptions = displayOptions;
        this.reloadData();
        return this;
    },
    setDisplayOption: function(key, options) {
        this.options.displayOptions = this.options.displayOptions || {};
        if (key in this.options.displayOptions) {
            var existingOption = this.options.displayOptions[key];
            this.options.displayOptions[key] = $.extend({}, existingOption, options);
        } else {
            this.options.displayOptions[key] = options;
        }
        this.reloadData();
        return this;
    },
    setFilter: function(filterFunction) {
        this.options.filter = filterFunction;
        this.reloadData();
        return this;
    },
    setData: function(data) {
        this._data = data;
        this.reloadData();
    },
    reloadData: function() {
        this.clearLayers();
        if (this._data) {
            this.addData(this._data);
        }
        return this;
    },
    addData: function(data) {
        var records = this.options.recordsField !== null && this.options.recordsField.length > 0 ? L.Util.getFieldValue(data, this.options.recordsField) : data;
        var layer;
        var location;
        if (this.options.locationMode === L.LocationModes.CUSTOM && this.options.preload) {
            this._preloadLocations(records);
        } else {
            this._loadRecords(records);
        }
        this._data = data;
    },
    locationToLayer: function(location, record) {
        var layer;
        layer = this.recordToLayer(location, record);
        if (layer) {
            this.addLayer(layer);
        }
    },
    _bindMouseEvents: function(layer, layerOptions, legendDetails) {
        var self = this;
        var options = this.options;
        var setHighlight = options.setHighlight;
        var unsetHighlight = options.unsetHighlight;
        var tooltipOptions = options.tooltipOptions;
        var highlight = function(e) {
            var target = e.target;
            var layerOptions = this.options || target.options;
            var icon = new L.LegendIcon(legendDetails, layerOptions, {
                className: tooltipOptions.className || "leaflet-div-icon",
                iconSize: tooltipOptions.iconSize,
                iconAnchor: tooltipOptions.iconAnchor
            });
            var latlng = e.latlng || e.target._latlng;
            var tooltip = new L.Marker(latlng, {
                icon: icon
            });
            self.addLayer(tooltip);
            if (self.tooltip) {
                self.removeLayer(self.tooltip);
                self.tooltip = null;
            }
            self.tooltip = tooltip;
            if (setHighlight) {
                layerOptions = setHighlight(layerOptions);
            }
            if (target.setStyle) {
                target.setStyle(layerOptions);
            }
        };
        var move = function(e) {
            if (self.tooltip) {
                self.tooltip.setLatLng(e.latlng);
            }
        };
        var unhighlight = function(e) {
            if (self.tooltip) {
                self.removeLayer(self.tooltip);
                self.tooltip = null;
            }
            var target = e.target;
            var layerOptions = this.options || target.options;
            if (unsetHighlight) {
                layerOptions = unsetHighlight(layerOptions);
            }
            if (target.setStyle) {
                target.setStyle(layerOptions);
            }
        };
        var bindLayerEvents = function(layer) {
            layer.on({
                mouseover: highlight,
                mouseout: unhighlight,
                mousemove: move
            });
        };
        var bindEvents = function(layer) {
            if (layer.eachLayer) {
                layer.eachLayer(function(subLayer) {
                    bindEvents(subLayer);
                });
            } else {
                bindLayerEvents(layer);
            }
        };
        bindEvents(layer);
    },
    _getDynamicOptions: function(record) {
        var layerOptions = L.Util.extend({}, this.options.layerOptions);
        var displayOptions = this.options.displayOptions;
        var legendDetails = {};
        if (displayOptions) {
            for (var property in displayOptions) {
                var propertyOptions = displayOptions[property];
                var fieldValue = L.Util.getFieldValue(record, property);
                var valueFunction;
                var displayText = propertyOptions.displayText ? propertyOptions.displayText(fieldValue) : fieldValue;
                legendDetails[property] = {
                    name: propertyOptions.displayName,
                    value: displayText
                };
                if (propertyOptions.styles) {
                    layerOptions = L.Util.extend(layerOptions, propertyOptions.styles[fieldValue]);
                    propertyOptions.styles[fieldValue] = layerOptions;
                } else {
                    for (var layerProperty in propertyOptions) {
                        valueFunction = propertyOptions[layerProperty];
                        layerOptions[layerProperty] = valueFunction.evaluate ? valueFunction.evaluate(fieldValue) : valueFunction.call ? valueFunction.call(fieldValue) : valueFunction;
                    }
                }
            }
        }
        return {
            layerOptions: layerOptions,
            legendDetails: legendDetails
        };
    },
    recordToLayer: function(location, record) {
        var layerOptions = L.Util.extend({}, this.options.layerOptions);
        var layer;
        var displayOptions = this.options.displayOptions;
        var legendDetails = {};
        var includeLayer = true;
        var includeFunction = this.options.filter || this.options.includeLayer;
        if (includeFunction) {
            includeLayer = includeFunction.call(this, record);
        }
        if (includeLayer) {
            var dynamicOptions = this._getDynamicOptions(record);
            layerOptions = dynamicOptions.layerOptions;
            legendDetails = dynamicOptions.legendDetails;
            if (location && layerOptions) {
                layerOptions.title = location.text;
                layer = this._getLayer(location, layerOptions, record);
                if (layer) {
                    if (this.options.showLegendTooltips) {
                        this._bindMouseEvents(layer, layerOptions, legendDetails);
                    }
                    if (this.options.onEachRecord) {
                        this.options.onEachRecord.call(this, layer, record, this);
                    }
                }
            }
        }
        return layer;
    },
    getLegend: function(legendOptions) {
        return this.options.getLegend ? this.options.getLegend.call(this, legendOptions) : this._getLegend(legendOptions);
    },
    _getLegendElement: function(params) {
        var displayMin;
        var displayMax;
        var $i = $("<i></i>");
        var displayProperties = params.displayProperties;
        var layerOptions = params.layerOptions;
        var ignoreProperties = params.ignoreProperties;
        var displayTextFunction = params.displayTextFunction;
        var index = params.index;
        var numSegments = params.numSegments;
        var segmentWidth = params.segmentWidth;
        var $minValue = params.$minValue;
        var $maxValue = params.$maxValue;
        L.StyleConverter.applySVGStyle($i, layerOptions);
        for (var property in displayProperties) {
            if (ignoreProperties.indexOf(property) === -1) {
                valueFunction = displayProperties[property];
                if (valueFunction && (valueFunction.getBounds || displayProperties.minValue && displayProperties.maxValue)) {
                    var bounds = valueFunction.getBounds ? valueFunction.getBounds() : null;
                    var minX = bounds ? bounds[0].x : displayProperties.minValue;
                    var maxX = bounds ? bounds[1].x : displayProperties.maxValue;
                    var binFunction = new L.LinearFunction(new L.Point(0, minX), new L.Point(numSegments, maxX));
                    displayMin = minX;
                    displayMax = maxX;
                    if (displayTextFunction) {
                        displayMin = displayTextFunction(minX);
                        displayMax = displayTextFunction(maxX);
                    }
                    if (index === 0) {
                        $minValue.html(displayMin);
                        $maxValue.html(displayMax);
                    }
                    var segmentSize = (maxX - minX) / numSegments;
                    var x = binFunction.evaluate(index);
                    var nextX = binFunction.evaluate(index + 1);
                    var value = valueFunction.evaluate ? valueFunction.evaluate(x) : valueFunction(x);
                    var nextValue = valueFunction.evaluate ? valueFunction.evaluate(nextX) : valueFunction(nextX);
                    L.StyleConverter.setCSSProperty($i, property, value);
                    if (property === "fillColor") {
                        $i.css("background-image", "linear-gradient(left , " + value + " 0%, " + nextValue + " 100%)");
                        $i.css("background-image", "-ms-linear-gradient(left , " + value + " 0%, " + nextValue + " 100%)");
                        $i.css("background-image", "-moz-linear-gradient(left , " + value + " 0%, " + nextValue + " 100%)");
                        $i.css("background-image", "-webkit-linear-gradient(left , " + value + " 0%, " + nextValue + " 100%)");
                    }
                    if (property === "color") {
                        $i.css("border-top-color", value);
                        $i.css("border-bottom-color", nextValue);
                        $i.css("border-left-color", value);
                        $i.css("border-right-color", nextValue);
                    }
                    if (property === "weight") {
                        $i.css("border-top-width", value);
                        $i.css("border-bottom-width", nextValue);
                        $i.css("border-left-width", value);
                        $i.css("border-right-width", nextValue);
                    }
                    var min = segmentSize * index + minX;
                    var max = min + segmentSize;
                    if (displayTextFunction && valueFunction) {
                        min = displayTextFunction(min);
                        max = displayTextFunction(max);
                    }
                    $i.attr("title", min + " - " + max);
                }
            }
        }
        $i.width(segmentWidth);
        return $i;
    },
    _getLegend: function(legendOptions) {
        legendOptions = legendOptions || this.options.legendOptions || {};
        var className = legendOptions.className;
        var legendElement = '<div class="legend"></div>';
        var $legendElement = $(legendElement);
        var displayOption;
        var valueFunction;
        var numSegments = legendOptions.numSegments || 10;
        var legendWidth = legendOptions.width || 100;
        var fieldBounds = {};
        var weight = this.options.layerOptions.weight || 0;
        var segmentWidth = legendWidth / numSegments - 2 * weight;
        var fieldElements = {};
        var layerOptions = this.options.layerOptions;
        var propertiesByField = {};
        var displayText;
        var displayOptions = this.options.displayOptions;
        var displayMin, displayMax;
        var radiusOptions = {
            property: [ "height" ],
            valueFunction: function(value) {
                return (2 * value).toFixed(0) + "px";
            }
        };
        if (className) {
            $legendElement.addClass(className);
        }
        if (legendOptions.title) {
            $legendElement.append("<legend>" + legendOptions.title + "</legend>");
        }
        var defaultFunction = function(value) {
            return value;
        };
        for (var field in displayOptions) {
            var displayProperties = displayOptions[field];
            var displayName = displayProperties.displayName || field;
            displayText = displayProperties.displayText;
            var displayTextFunction = displayText ? displayText : defaultFunction;
            var styles = displayProperties.styles;
            $legendElement.append('<div class="legend-title">' + displayName + "</div>");
            if (styles) {
                var legend = new L.CategoryLegend(styles);
                $legendElement.append(legend.generate());
            } else {
                var $legendItems = $('<div class="data-layer-legend"><div class="min-value"></div><div class="scale-bars"></div><div class="max-value"></div></div>');
                var $minValue = $legendItems.find(".min-value");
                var $maxValue = $legendItems.find(".max-value");
                var $scaleBars = $legendItems.find(".scale-bars");
                var ignoreProperties = [ "displayName", "displayText", "minValue", "maxValue" ];
                for (var index = 0; index < numSegments; ++index) {
                    var legendParams = {
                        displayProperties: displayProperties,
                        layerOptions: layerOptions,
                        ignoreProperties: ignoreProperties,
                        displayTextFunction: displayTextFunction,
                        index: index,
                        numSegments: numSegments,
                        segmentWidth: segmentWidth,
                        $minValue: $minValue,
                        $maxValue: $maxValue
                    };
                    var $element = this._getLegendElement(legendParams);
                    $scaleBars.append($element);
                }
            }
            $legendElement.append($legendItems);
        }
        return $legendElement.wrap("<div/>").parent().html();
    }
});

L.dataLayer = function(data, options) {
    return new L.DataLayer(data, options);
};

L.MapMarkerDataLayer = L.DataLayer.extend({
    _getMarker: function(latLng, layerOptions, record) {
        return new L.MapMarker(latLng, layerOptions);
    }
});

L.mapMarkerDataLayer = function(data, options) {
    return new L.MapMarkerDataLayer(data, options);
};

L.MarkerDataLayer = L.DataLayer.extend({
    initialize: function(data, options) {
        this._markerMap = {};
        L.DataLayer.prototype.initialize.call(this, data, options);
    },
    options: {
        recordsField: "features",
        locationMode: L.LocationModes.LATLNG,
        latitudeField: "latitude",
        longitudeField: "longitude",
        layerOptions: {
            icon: null
        },
        showLegendTooltips: false
    },
    _getMarker: function(latLng, layerOptions, record) {
        if (this.options.setIcon) {
            layerOptions.icon = this.options.setIcon.call(this, record, layerOptions);
        }
        return new L.Marker(latLng, layerOptions);
    },
    _getLegendElement: function(params) {},
    _getLegend: function(options) {
        return "<span>No legend available</span>";
    }
});

L.markerDataLayer = function(data, options) {
    return new L.MarkerDataLayer(data, options);
};

L.PanoramioLayer = L.MarkerDataLayer.extend({
    statics: {
        UPLOAD_DATE_FORMAT: "DD MMM YYYY",
        SIZE_BY_DATE: "date",
        SIZE_BY_POPULARITY: "popularity",
        SIZE_BY_NONE: "none",
        SIZES: {
            square: [ 60, 60 ],
            mini_square: [ 32, 32 ]
        },
        NUM_PHOTOS: 50
    }
});

L.PanoramioLayer = L.PanoramioLayer.extend({
    initialize: function(options) {
        L.MarkerDataLayer.prototype.initialize.call(this, {}, options);
        this._from = 0;
        this._to = L.PanoramioLayer.NUM_PHOTOS;
        this._calls = [];
    },
    options: {
        recordsField: "photos",
        latitudeField: "latitude",
        longitudeField: "longitude",
        locationMode: L.LocationModes.LATLNG,
        showLegendTooltips: false,
        sizeBy: L.PanoramioLayer.SIZE_BY_DATE,
        layerOptions: {
            opacity: 1
        },
        onEachRecord: function(layer, record) {
            var $html = L.HTMLUtils.buildTable(record);
            var photoUrl = record["photo_file_url"];
            var title = record["photo_title"];
            var me = this;
            var width = record["width"];
            var height = record["height"];
            var offset = 2e4;
            layer.on("click", function(e) {
                var $html = $('<div><img class="photo" onload="this.style.opacity=1" src="' + photoUrl + '"/><div class="photo-info"><span>' + title + '</span><a class="photo-link" target="_blank" href="' + record["photo_url"] + '"><img src="http://www.panoramio.com/img/glass/components/logo_bar/panoramio.png" style="height: 14px;"/></a></div><a class="author-link" target="_blank" href="' + record["owner_url"] + '">by ' + record["owner_name"] + "</a></div>");
                $html.find(".photo").width(width);
                $html.find(".photo-info").width(width - 20);
                var icon = new L.DivIcon({
                    className: "photo-details",
                    html: $html.wrap("<div/>").parent().html(),
                    iconAnchor: [ width / 2, height / 2 ]
                });
                var marker = new L.Marker(e.target._latlng, {
                    icon: icon,
                    zIndexOffset: offset
                });
                marker.on("click", function(e) {
                    me.removeLayer(e.target);
                });
                layer.viewedImage = marker;
                me.viewedImage = marker;
                me.addLayer(marker);
            });
            if (this.options.onEachPhoto) {
                this.options.onEachPhoto.call(this, layer, record);
            }
        },
        setIcon: function(record, options) {
            var title = L.Util.getFieldValue(record, "photo_title");
            var size = null;
            if (this._sizeFunction) {
                size = this._sizeFunction.evaluate(record.index);
            }
            var iconSize = size ? new L.Point(size, size) : L.PanoramioLayer.SIZES[this.options.size];
            var url = record["photo_file_url"].replace("/medium/", "/" + this.options.size + "/");
            var icon = new L.DivIcon({
                iconSize: iconSize,
                className: "",
                html: '<img class="photo" onload="this.style.opacity=1" title="' + title + '" src="' + url + '"/>'
            });
            return icon;
        },
        updateInterval: 3e5,
        size: "square",
        attributionText: 'Photos provided by <a href="http://www.panoramio.com"><img src="http://www.panoramio.com/img/glass/components/logo_bar/panoramio.png" style="height: 10px;"/></a>.  Photos provided by <a href="http://www.panoramio.com"><img src="http://www.panoramio.com/img/glass/components/logo_bar/panoramio.png" style="height: 10px;"/></a> are under the copyright of their owners',
        refreshEvents: "moveend",
        photoSet: "public"
    },
    includes: L.Mixin.Events,
    onAdd: function(map) {
        L.DataLayer.prototype.onAdd.call(this, map);
        if (map.attributionControl) {
            map.attributionControl.addAttribution(this.options.attributionText);
        }
        var me = this;
        var resetFunction = function(e) {
            me._from = 0;
            me._to = L.PanoramioLayer.NUM_PHOTOS;
            me.fire("requestingPhotos");
            if (me._call) {
                clearTimeout(me._call);
            }
            var request = function() {
                me.requestPhotos();
            };
            me._call = setTimeout(request, 1e3);
        };
        this.requestPhotos();
        this._interval = setInterval(resetFunction, this.options.updateInterval);
        this._resetFunction = resetFunction;
        map.on(this.options.refreshEvents, resetFunction);
    },
    onRemove: function(map) {
        L.DataLayer.prototype.onRemove.call(this, map);
        if (map.attributionControl) {
            map.attributionControl.removeAttribution(this.options.attributionText);
        }
        if (this._interval) {
            clearInterval(this._interval);
            this._interval = null;
        }
        map.off(this.options.refreshEvents, this._resetFunction);
    },
    calculateSizeByDate: function(data) {
        var photos = data.photos;
        var timestamps = [];
        for (var i = 0; i < photos.length; ++i) {
            var photo = photos[i];
            var timestamp = moment(photo["upload_date"], L.PanoramioLayer.UPLOAD_DATE_FORMAT);
            timestamps.push(timestamp);
            photos[i].index = timestamp;
        }
        timestamps.sort(function(t1, t2) {
            return t1 - t2;
        });
        var size = L.PanoramioLayer.SIZES[this.options.size][0];
        this._sizeFunction = new L.LinearFunction([ timestamps[0], size / 2 ], [ timestamps[timestamps.length - 1], size ]);
        return data;
    },
    calculateSizeByPopularity: function(data) {
        var photos = data.photos;
        for (var i = 0; i < photos.length; ++i) {
            photos[i].index = i;
        }
        var size = L.PanoramioLayer.SIZES[this.options.size][0];
        this._sizeFunction = new L.LinearFunction([ 0, size / 2 ], [ photos.length, size ]);
        return data;
    },
    next: function() {
        this._from = this._to;
        this._to = this._from + L.PanoramioLayer.NUM_PHOTOS;
        this.requestPhotos();
    },
    previous: function() {
        this._to = this._from;
        this._from = this._from - L.PanoramioLayer.NUM_PHOTOS;
        this.requestPhotos();
    },
    requestPhotos: function() {
        var me = this;
        var bounds = this._map.getBounds();
        var southWest = bounds.getSouthWest();
        var northEast = bounds.getNorthEast();
        while (me._calls.length > 0) {
            me._calls.pop().abort();
        }
        var request = $.ajax({
            url: "http://www.panoramio.com/map/get_panoramas.php",
            data: {
                set: this.options.photoSet,
                from: me._from,
                to: me._to,
                minx: southWest.lng,
                miny: southWest.lat,
                maxx: northEast.lng,
                maxy: northEast.lat,
                size: "medium",
                mapfilter: "true"
            },
            type: "GET",
            dataType: "jsonp",
            success: function(data) {
                me._count = data.count;
                if (moment && me.options.sizeBy === L.PanoramioLayer.SIZE_BY_DATE) {
                    data = me.calculateSizeByDate(data);
                } else if (me.options.sizeBy === L.PanoramioLayer.SIZE_BY_POPULARITY) {
                    data = me.calculateSizeByPopularity(data);
                }
                me.fire("photosAvailable", data);
                me.clearLayers();
                me.addData(data);
            }
        });
        me._calls.push(request);
    }
});

L.panoramioLayer = function(options) {
    return new L.PanoramioLayer(options);
};

L.GeohashDataLayer = L.DataLayer.extend({
    initialize: function(data, options) {
        L.DataLayer.prototype.initialize.call(this, data, options);
    },
    options: {
        recordsField: "features",
        locationMode: L.LocationModes.GEOHASH,
        geohashField: "geohash",
        displayField: null,
        displayOptions: null,
        layerOptions: {
            weight: 1,
            color: "#000"
        }
    },
    _getLayer: function(geohash, layerOptions, record) {
        return new L.Rectangle(geohash.location, layerOptions);
    }
});

L.geohashDataLayer = function(data, options) {
    return new L.GeohashDataLayer(data, options);
};

L.ChoroplethDataLayer = L.DataLayer.extend({
    initialize: function(data, options) {
        L.DataLayer.prototype.initialize.call(this, data, options);
    },
    options: {
        recordsField: "features",
        locationMode: L.LocationModes.COUNTRY,
        codeField: "ISO",
        displayField: null,
        displayOptions: null,
        layerOptions: {
            weight: 1,
            color: "#000"
        },
        maxZoom: 12,
        backgroundLayer: true
    },
    _getLayer: function(location, layerOptions, record) {
        if (location.location instanceof L.LatLng) {
            location.location = this._getMarker(location.location, layerOptions, record);
        }
        if (location.location.setStyle) {
            location.location.setStyle(layerOptions);
        }
        return location.location;
    }
});

L.choroplethDataLayer = function(data, options) {
    return new L.ChoroplethDataLayer(data, options);
};

L.ChartDataLayer = L.DataLayer.extend({
    options: {
        showLegendTooltips: false
    },
    initialize: function(data, options) {
        L.DataLayer.prototype.initialize.call(this, data, options);
    },
    _getLayer: function(latLng, layerOptions, record) {
        this._addBoundary(latLng, layerOptions);
        latLng = this._processLocation(latLng);
        var chartOptions = this.options.chartOptions;
        var tooltipOptions = this.options.tooltipOptions;
        var options = {};
        options = layerOptions;
        options.data = {};
        options.chartOptions = chartOptions;
        for (var key in this.options.chartOptions) {
            options.data[key] = L.Util.getFieldValue(record, key);
        }
        for (var key in this.options.tooltipOptions) {
            options[key] = this.options.tooltipOptions[key];
        }
        var marker;
        if (latLng) {
            marker = this._getMarker(latLng, options);
        }
        return marker;
    },
    _getMarker: function(latLng, options) {},
    _getLegend: function(legendOptions) {
        var legend = new L.CategoryLegend(this.options.chartOptions);
        legendOptions = legendOptions || this.options.legendOptions;
        return legend.generate(legendOptions);
    }
});

L.BarChartDataLayer = L.ChartDataLayer.extend({
    initialize: function(data, options) {
        L.ChartDataLayer.prototype.initialize.call(this, data, options);
    },
    _getMarker: function(latLng, options) {
        return new L.BarChartMarker(latLng, options);
    }
});

L.barChartDataLayer = function(data, options) {
    return new L.BarChartDataLayer(data, options);
};

L.RadialBarChartDataLayer = L.ChartDataLayer.extend({
    initialize: function(data, options) {
        L.ChartDataLayer.prototype.initialize.call(this, data, options);
    },
    _getMarker: function(latLng, options) {
        return new L.RadialBarChartMarker(latLng, options);
    }
});

L.radialBarChartDataLayer = function(data, options) {
    return new L.RadialBarChartDataLayer(data, options);
};

L.PieChartDataLayer = L.ChartDataLayer.extend({
    initialize: function(data, options) {
        L.ChartDataLayer.prototype.initialize.call(this, data, options);
    },
    _getMarker: function(latLng, options) {
        return new L.PieChartMarker(latLng, options);
    }
});

L.pieChartDataLayer = function(data, options) {
    return new L.PieChartDataLayer(data, options);
};

L.CoxcombChartDataLayer = L.ChartDataLayer.extend({
    initialize: function(data, options) {
        L.ChartDataLayer.prototype.initialize.call(this, data, options);
    },
    _getMarker: function(latLng, options) {
        return new L.CoxcombChartMarker(latLng, options);
    }
});

L.coxcombChartDataLayer = function(data, options) {
    return new L.CoxcombChartDataLayer(data, options);
};

L.StackedRegularPolygonDataLayer = L.ChartDataLayer.extend({
    initialize: function(data, options) {
        L.ChartDataLayer.prototype.initialize.call(this, data, options);
    },
    _getMarker: function(latLng, options) {
        return new L.StackedRegularPolygonMarker(latLng, options);
    }
});

L.stackedRegularPolygonDataLayer = function(data, options) {
    return new L.StackedRegularPolygonDataLayer(data, options);
};

L.RadialMeterMarkerDataLayer = L.DataLayer.extend({
    options: {
        showLegendTooltips: false
    },
    initialize: function(data, options) {
        L.DataLayer.prototype.initialize.call(this, data, options);
    },
    _getLayer: function(latLng, layerOptions, record) {
        this._addBoundary(latLng, layerOptions);
        latLng = this._processLocation(latLng);
        var chartOptions = this.options.chartOptions;
        var tooltipOptions = this.options.tooltipOptions;
        var displayOptions = this.options.displayOptions;
        var options = {};
        options = layerOptions;
        options.data = {};
        options.chartOptions = chartOptions;
        options.displayOptions = displayOptions;
        for (var key in this.options.chartOptions) {
            options.data[key] = L.Util.getFieldValue(record, key);
        }
        for (var key in this.options.tooltipOptions) {
            options[key] = this.options.tooltipOptions[key];
        }
        var marker;
        if (latLng) {
            marker = this._getMarker(latLng, options);
        }
        return marker;
    },
    _getMarker: function(latLng, options) {
        return new L.RadialMeterMarker(latLng, options);
    }
});

L.radialMeterMarkerDataLayer = function(data, options) {
    return new L.RadialMeterMarkerDataLayer(data, options);
};

L.CalloutLine = L.Path.extend({
    statics: {
        LINESTYLE: {
            ARC: "arc",
            ANGLE: "angle",
            STRAIGHT: "straight"
        },
        DIRECTION: {
            NE: "ne",
            NW: "nw",
            SE: "se",
            SW: "sw"
        }
    }
});

L.CalloutLine = L.CalloutLine.extend({
    initialize: function(latlng, options) {
        L.Util.setOptions(this, options);
        L.Path.prototype.initialize.call(this, options);
        this._latlng = latlng;
    },
    options: {
        size: new L.Point(60, 30),
        position: new L.Point(0, 0),
        color: "#FFFFFF",
        opacity: 1,
        weight: 2,
        fillColor: "#000000",
        fill: false,
        gradient: false,
        dropShadow: true,
        direction: L.CalloutLine.DIRECTION.NE,
        lineStyle: L.CalloutLine.LINESTYLE.ANGLE,
        lineCap: "butt",
        lineJoin: "miter",
        arrow: false
    },
    projectLatlngs: function() {
        this._point = this._map.latLngToLayerPoint(this._latlng);
        this._points = this._getPoints();
    },
    getEndPoint: function() {
        this.projectLatlngs();
        return this._points[this._points.length - 1];
    },
    _getPathAngle: function() {
        return new L.SVGPathBuilder(this._points, [], {
            closePath: false
        }).build(6);
    },
    _getPathArc: function() {
        var direction = (this.options.direction || L.CalloutLine.DIRECTION.NE).toLowerCase();
        var xDirection = direction[1];
        var yDirection = direction[0];
        var xMultiplier = xDirection === "w" ? -1 : 1;
        var yMultiplier = yDirection === "n" ? -1 : 1;
        var point1 = this._points[0];
        var point2 = this._points[this._points.length - 1];
        var parts = [ "M", point1.x, ",", point1.y, " Q", point1.x, ",", point1.y + yMultiplier * this.options.size.y, " ", point2.x, ",", point2.y ];
        return parts.join(" ");
    },
    _getPoints: function() {
        var x = this._point.x + this.options.position.x;
        var y = this._point.y + this.options.position.y;
        var width = this.options.size.x;
        var height = this.options.size.y;
        var direction = (this.options.direction || L.CalloutLine.DIRECTION.NE).toLowerCase();
        var points = [];
        var xDirection = direction[1];
        var yDirection = direction[0];
        var xMultiplier = xDirection === "w" ? -1 : 1;
        var yMultiplier = yDirection === "n" ? -1 : 1;
        points.push(new L.Point(x, y));
        var yEnd = y + yMultiplier * height;
        var halfWidth = width / 2;
        var angle = Math.atan(height / halfWidth);
        if (this.options.lineStyle === L.CalloutLine.LINESTYLE.ARC) {
            angle = Math.atan(Math.pow(height, 2) / halfWidth);
        } else if (this.options.lineStyle === L.CalloutLine.LINESTYLE.STRAIGHT) {
            angle = Math.atan(height / width);
        }
        this._angle = angle;
        if (this.options.lineStyle !== L.CalloutLine.LINESTYLE.STRAIGHT) {
            var elbowPoint = new L.Point(x + xMultiplier * halfWidth, yEnd);
            points.push(elbowPoint);
        }
        var endPoint = new L.Point(x + xMultiplier * width, yEnd);
        points.push(endPoint);
        return points;
    },
    getBounds: function() {
        var map = this._map, point = map.project(this._latlng), swPoint = new L.Point(point.x + this.options.position.x, point.y + this.options.position.y), nePoint = new L.Point(swPoint.x + this.options.size.x, swPoint.y - this.options.size.y), sw = map.unproject(swPoint), ne = map.unproject(nePoint);
        return new L.LatLngBounds(sw, ne);
    },
    setLatLng: function(latlng) {
        this._latlng = latlng;
        this.redraw();
    },
    getLatLng: function() {
        return this._latlng;
    },
    getPathString: function() {
        this._path.setAttribute("shape-rendering", "geometricPrecision");
        var lineStyle = this.options.lineStyle || L.CalloutLine.LINESTYLE.ANGLE;
        var path = "";
        if (lineStyle === L.CalloutLine.LINESTYLE.ANGLE || lineStyle === L.CalloutLine.LINESTYLE.STRAIGHT) {
            path += this._getPathAngle();
        } else {
            path += this._getPathArc();
        }
        return path;
    }
});

L.calloutLine = function(latlng, options) {
    return new L.CalloutLine(latlng, options);
};

L.Callout = L.LayerGroup.extend({
    options: {
        color: "#FFFFFF",
        fillColor: "#FFFFFF"
    },
    initialize: function(latlng, options) {
        L.Util.setOptions(this, options);
        L.LayerGroup.prototype.initialize.call(this, options);
        this._latlng = latlng;
    },
    onAdd: function(map) {
        L.LayerGroup.prototype.onAdd.call(this, map);
        this.addLayers();
    },
    addArrow: function(angle, direction, position) {
        if (this.options.arrow) {
            var angle = L.LatLng.RAD_TO_DEG * angle;
            var numberOfSides = this.options.numberOfSides || 3;
            var radius = this.options.radius || 6;
            var startRotation = 180 / numberOfSides;
            var offsets = {
                se: startRotation + angle,
                sw: 180 + startRotation - angle,
                nw: 180 + startRotation + angle,
                ne: startRotation - angle
            };
            var rotation = offsets[direction];
            var arrow = new L.RegularPolygonMarker(this._latlng, {
                position: position,
                numberOfSides: numberOfSides,
                rotation: rotation,
                fillColor: this.options.fillColor,
                color: this.options.color,
                weight: 1,
                opacity: 1,
                fillOpacity: 1,
                radius: radius,
                lineCap: "butt",
                lineJoin: "miter"
            });
            this.addLayer(arrow);
        }
    },
    addLine: function() {
        var lineOptions = {};
        for (var key in this.options) {
            if (key !== "icon") {
                lineOptions[key] = this.options[key];
            }
        }
        var calloutLine = new L.CalloutLine(this._latlng, lineOptions);
        this.addLayer(calloutLine);
        return calloutLine;
    },
    addIcon: function(direction, position) {
        var size = this.options.size;
        var icon = this.options.icon;
        var iconAnchor = icon.options.iconAnchor;
        var iconSize = icon.options.iconSize;
        var yDirection = direction[0];
        var xDirection = direction[1];
        var xAnchor = xDirection === "w" ? icon.options.iconSize.x + size.x - position.x : -1 * (size.x + position.x);
        var yAnchor = yDirection === "n" ? icon.options.iconSize.y / 2 + size.y - position.y : -1 * (-icon.options.iconSize.y / 2 + size.y + position.y);
        icon.options.iconAnchor = new L.Point(xAnchor, yAnchor);
        var iconMarker = new L.Marker(this._latlng, {
            icon: icon
        });
        this.addLayer(iconMarker);
    },
    addLayers: function() {
        var direction = (this.options.direction || "ne").toLowerCase();
        var position = this.options.position || new L.Point(0, 0);
        var calloutLine;
        calloutLine = this.addLine();
        this.addIcon(direction, position);
        this.addArrow(calloutLine._angle, direction, position);
    }
});

L.callout = function(latlng, options) {
    return new L.Callout(latlng, options);
};

L.FlowLine = L.DataLayer.extend({
    statics: {
        LINE_FUNCTION: function(latlng1, latlng2, options) {
            return new L.Polyline([ latlng1, latlng2 ], options);
        },
        LINE_FUNCTION_INTERPOLATED: function(latlng1, latlng2, options) {
            var point1 = this._map.latlngToLayerPoint(latlng1);
            var point2 = this._map.latlngToLayerPoint(latlng2);
            var lineFunction = new L.LinearFunction(point1, point2);
            var numPoints = Math.ceil(point1.distanceTo(point2) / options.interpolationOptions.segmentLength);
            var points = lineFunction.samplePoints(numPoints);
        }
    }
});

L.FlowLine = L.FlowLine.extend({
    initialize: function(data, options) {
        L.Util.setOptions(this, options);
        L.DataLayer.prototype.initialize.call(this, data, options);
    },
    options: {
        getLine: L.FlowLine.LINE_FUNCTION
    },
    onEachSegment: function(record1, record2, line) {
        var deltas = {};
        if (this.options.timeField) {
            var timeValue1 = L.Util.getFieldValue(record1, this.options.timeField);
            var timeValue2 = L.Util.getFieldValue(record2, this.options.timeField);
            var format = this.options.timeFormat;
            var moment1 = format ? moment(timeValue1, format) : moment(timeValue1);
            var moment2 = format ? moment(timeValue2, format) : moment(timeValue2);
            var deltaTime = moment2.valueOf() - moment1.valueOf();
            deltas.time = deltaTime;
        }
        for (var key in this.options.displayOptions) {
            var value1 = L.Util.getFieldValue(record1, key);
            var value2 = L.Util.getFieldValue(record2, key);
            var change = value2 - value1;
            var percentChange = change / value1 * 100;
            deltas[key] = {
                from: value1,
                to: value2,
                change: change,
                percentChange: percentChange,
                changeOverTime: change / deltas.time
            };
        }
        var latlngs = line.getLatLngs();
        var distance = latlngs[0].distanceTo(latlngs[1]);
        if (this.options.onEachSegment) {
            this.options.onEachSegment.call(this, record1, record2, line, deltas, distance);
        }
    },
    _loadRecords: function(records) {
        var location;
        var options = this.options.layerOptions;
        var markers = [];
        for (var recordIndex in records) {
            if (records.hasOwnProperty(recordIndex)) {
                var record = records[recordIndex];
                location = this._getLocation(record, recordIndex);
                if (location) {
                    var marker = this._getLayer(location, options, record);
                    var line;
                    var includeLayer = true;
                    if (this.options.includeLayer) {
                        includeLayer = this.options.includeLayer(record);
                    }
                    if (this._lastRecord && includeLayer) {
                        var options = this._getDynamicOptions(this._lastRecord);
                        line = this.options.getLine.call(this, this._lastMarker.getLatLng(), marker.getLatLng(), options.layerOptions);
                        this.addLayer(line);
                        this.onEachSegment(this._lastRecord, record, line);
                    }
                    if (includeLayer) {
                        this._lastRecord = record;
                        this._lastMarker = marker;
                    }
                }
            }
        }
        while (markers.length > 0) {
            this.addLayer(markers.pop());
        }
    }
});

L.flowLine = function(data, options) {
    return new L.FlowLine(data, options);
};

L.ArcedFlowLine = L.FlowLine.extend({
    options: {
        getLine: function(latlng1, latlng2, options) {
            return new L.ArcedPolyline([ latlng1, latlng2 ], options);
        }
    },
    initialize: function(data, options) {
        L.FlowLine.prototype.initialize.call(this, data, options);
    }
});

L.arcedFlowLine = function(data, options) {
    return new L.ArcedFlowLine(data, options);
};

L.ArcedPolyline = L.Path.extend({
    initialize: function(latlngs, options) {
        L.Path.prototype.initialize.call(this, options);
        this._latlngs = latlngs;
    },
    options: {
        distanceToHeight: new L.LinearFunction([ 0, 5 ], [ 1e3, 200 ]),
        color: "#FFFFFF",
        opacity: 1,
        weight: 1,
        fillColor: "#000000",
        fill: false,
        gradient: false,
        dropShadow: false,
        optimizeSpeed: false
    },
    projectLatlngs: function() {
        this._points = [];
        for (var i = 0; i < this._latlngs.length; ++i) {
            this._points.push(this._map.latLngToLayerPoint(this._latlngs[i]));
        }
    },
    getBounds: function() {
        var map = this._map, point = map.project(this._latlngs[0]), swPoint = new L.Point(point.x + this.options.offset.x, point.y + this.options.offset.y), nePoint = new L.Point(swPoint.x + this.options.size.x, swPoint.y - this.options.size.y), sw = map.unproject(swPoint), ne = map.unproject(nePoint);
        return new L.LatLngBounds(sw, ne);
    },
    setLatLngs: function(latlngs) {
        this._latlngs = latlngs;
        this.redraw();
    },
    getLatLngs: function() {
        return this._latlngs;
    },
    drawSegment: function(point1, point2) {
        var distance = Math.sqrt(Math.pow(point2.x - point1.x, 2) + Math.pow(point2.y - point1.y, 2));
        var heightOffset = this.options.distanceToHeight.evaluate(distance);
        var directionX = point1.x - point2.x;
        var multiplierX = directionX / Math.abs(directionX);
        var parts = [ "M", point1.x, ",", point1.y, " C", point1.x, ",", point1.y - heightOffset, " ", point2.x, ",", point2.y - heightOffset, " ", point2.x, ",", point2.y ];
        return parts.join(" ");
    },
    getPathString: function() {
        if (this.options.optimizeSpeed) {
            this._path.setAttribute("shape-rendering", "optimizeSpeed");
        }
        var parts = [];
        for (var i = 0; i < this._points.length - 1; ++i) {
            parts.push(this.drawSegment(this._points[i], this._points[i + 1]));
        }
        return parts.join("");
    }
});

L.arcedPolyline = function(latlngs, options) {
    return new L.ArcedPolyline(latlngs, options);
};

L.Control.Legend = L.Control.extend({
    options: {
        position: "bottomright",
        autoAdd: true
    },
    onAdd: function(map) {
        var className = "leaflet-control-legend", container = L.DomUtil.create("div", className);
        var self = this;
        if (this.options.autoAdd) {
            map.on("layeradd", function(e) {
                var layer = e.layer;
                self.addLayer(layer);
            });
            map.on("layerremove", function(e) {
                var layer = e.layer;
                self.removeLayer(layer);
            });
        }
        $(container).on("mouseover mouseout", function(e) {
            $(this).toggleClass("larger");
        });
        L.DomEvent.addListener(container, "click", L.DomEvent.stopPropagation).addListener(container, "click", L.DomEvent.preventDefault);
        return container;
    },
    clear: function() {
        $(this._container).empty();
    },
    toggleSize: function() {
        $(this._container).toggleClass("larger", "slow");
    },
    addLayer: function(layer) {
        var id = L.Util.stamp(layer);
        if (layer.getLegend) {
            this.addLegend(id, layer.getLegend());
        }
    },
    removeLayer: function(layer) {
        var id = L.Util.stamp(layer);
        if (layer.getLegend) {
            $(this._container).find("#" + id).remove();
        }
    },
    addLegend: function(id, html) {
        var $container = $(this._container);
        var $html = $(html);
        var $existingLegend = $container.find("#" + id);
        if ($existingLegend.size() === 0) {
            $container.append('<div id="' + id + '">' + html + "</div>");
        } else {
            $existingLegend.find("div.legend").replaceWith($html);
        }
    }
});

L.control.legend = function(options) {
    return new L.Control.Legend(options);
};
console.log(L);