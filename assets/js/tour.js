(function() {
  define(['bootstrap-tour', 'i18next', 'cs!app/jade', 'cs!app/models'], function(_bst, _arg, jade, models) {
    var NUM_STEPS, STEPS, getExamples, t, unit;
    t = _arg.t;
    unit = new models.Unit({
      id: 8215
    });
    STEPS = [
      {
        orphan: true
      }, {
        element: '#navigation-header',
        placement: 'bottom',
        backdrop: true
      }, {
        element: '#search-region',
        placement: 'right',
        backdrop: true,
        onShow: function(tour) {
          var $container, $input;
          $container = $('#search-region');
          $input = $container.find('input');
          $input.typeahead('val', '');
          $input.typeahead('val', 'terve');
          $input.val('terve');
          return $input.click();
        },
        onHide: function() {
          var $container, $input;
          $container = $('#search-region');
          $input = $container.find('input');
          return $input.typeahead('val', '');
        }
      }, {
        element: '#browse-region',
        placement: 'right',
        backdrop: true,
        onShow: function(tour) {
          var $container;
          $container = $('#browse-region');
          return _.defer((function(_this) {
            return function() {
              return $container.click();
            };
          })(this));
        }
      }, {
        element: '.service-hover-color-50003',
        placement: 'right',
        backdrop: true
      }, {
        element: '.leaflet-marker-icon',
        placement: 'bottom',
        backdrop: false,
        onShow: function(tour) {
          return unit.fetch({
            data: {
              include: 'root_services,department,municipality,services'
            },
            success: function() {
              return app.commands.execute('selectUnit', unit);
            }
          });
        }
      }, {
        element: '.route-section',
        placement: 'right',
        backdrop: true,
        onNext: function() {
          return app.commands.execute('clearSelectedUnit');
        }
      }, {
        element: '#personalisation',
        placement: 'left',
        backdrop: true
      }, {
        element: '#personalisation',
        placement: 'left',
        backdrop: true,
        onShow: function() {
          return $('#personalisation .personalisation-button').click();
        },
        onHide: function() {
          return $('#personalisation .ok-button').click();
        }
      }, {
        element: '#service-cart',
        placement: 'left',
        backdrop: true
      }, {
        element: '#language-selector',
        placement: 'left',
        backdrop: true
      }, {
        element: '#persistent-logo .feedback-prompt',
        placement: 'left',
        backdrop: true
      }, {
        onShow: function(tour) {
          app.commands.execute('home');
          p13n.set('skip_tour', true);
          return $('#app-container').one('click', (function(_this) {
            return function() {
              return tour.end();
            };
          })(this));
        },
        onShown: function(tour) {
          var $container, $step;
          $container = $(tour.getStep(tour.getCurrentStep()).container);
          $step = $($container).children();
          $step.attr('tabindex', -1).focus();
          $('.tour-success', $container).on('click', (function(_this) {
            return function(ev) {
              return tour.end();
            };
          })(this));
          return $container.find('a.service').on('click', (function(_this) {
            return function(ev) {
              tour.end();
              return app.commands.execute('addService', new models.Service({
                id: $(ev.currentTarget).data('service')
              }));
            };
          })(this));
        },
        orphan: true
      }
    ];
    NUM_STEPS = STEPS.length;
    getExamples = (function(_this) {
      return function() {
        return [
          {
            key: 'health',
            name: t('tour.examples.health'),
            service: 25002
          }, {
            key: 'beach',
            name: t('tour.examples.beach'),
            service: 33467
          }, {
            key: 'art',
            name: t('tour.examples.art'),
            service: 25658
          }, {
            key: 'glass_recycling',
            name: t('tour.examples.glass_recycling'),
            service: 29475
          }
        ];
      };
    })(this);
    return {
      startTour: function() {
        var i, languages, selected, step, tour, _i, _len;
        selected = p13n.getLanguage();
        languages = _.chain(p13n.getSupportedLanguages()).map((function(_this) {
          return function(l) {
            return l.code;
          };
        })(this)).filter((function(_this) {
          return function(l) {
            return l !== selected;
          };
        })(this)).value();
        tour = new Tour({
          template: function(i, step) {
            step.length = NUM_STEPS - 2;
            step.languages = languages;
            step.first = step.next === 1;
            step.last = step.next === -1;
            if (step.last) {
              step.examples = getExamples();
            }
            return jade.template('tour', step);
          },
          storage: false,
          container: '#tour-region',
          onShown: function(tour) {
            var $step;
            $step = $('#' + this.id);
            return $step.attr('tabindex', -1).focus();
          },
          onEnd: function(tour) {
            p13n.set('skip_tour', true);
            return p13n.trigger('tour-skipped');
          }
        });
        for (i = _i = 0, _len = STEPS.length; _i < _len; i = ++_i) {
          step = STEPS[i];
          step.title = t("tour.steps." + i + ".title");
          step.content = t("tour.steps." + i + ".content");
          tour.addStep(step);
        }
        return tour.start(true);
      }
    };
  });

}).call(this);

//# sourceMappingURL=tour.js.map
