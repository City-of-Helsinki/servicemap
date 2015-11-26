(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  define(['underscore', 'i18next', 'cs!app/models', 'cs!app/views/base'], function(_, i18n, models, base) {
    var ServiceTreeView;
    return ServiceTreeView = (function(_super) {
      __extends(ServiceTreeView, _super);

      function ServiceTreeView() {
        return ServiceTreeView.__super__.constructor.apply(this, arguments);
      }

      ServiceTreeView.prototype.id = 'service-tree-container';

      ServiceTreeView.prototype.className = 'navigation-element';

      ServiceTreeView.prototype.template = 'service-tree';

      ServiceTreeView.prototype.events = function() {
        var openOnKbd, toggleOnKbd;
        openOnKbd = this.keyboardHandler(this.openService, ['enter']);
        toggleOnKbd = this.keyboardHandler(this.toggleLeafButton, ['enter', 'space']);
        return {
          'click .service.has-children': 'openService',
          'keydown .service.parent': openOnKbd,
          'keydown .service.has-children': openOnKbd,
          'keydown .service.has-children a.show-icon': toggleOnKbd,
          'click .service.parent': 'openService',
          'click .crumb': 'handleBreadcrumbClick',
          'click .service.leaf': 'toggleLeaf',
          'keydown .service.leaf': toggleOnKbd,
          'click .service .show-icon': 'toggleButton',
          'mouseenter .service .show-icon': 'showTooltip',
          'mouseleave .service .show-icon': 'removeTooltip'
        };
      };

      ServiceTreeView.prototype.type = 'service-tree';

      ServiceTreeView.prototype.initialize = function(options) {
        this.selectedServices = options.selectedServices;
        this.breadcrumbs = options.breadcrumbs;
        this.animationType = 'left';
        this.scrollPosition = 0;
        this.listenTo(this.selectedServices, 'remove', this.render);
        this.listenTo(this.selectedServices, 'add', this.render);
        return this.listenTo(this.selectedServices, 'reset', this.render);
      };

      ServiceTreeView.prototype.toggleLeaf = function(event) {
        return this.toggleElement($(event.currentTarget).find('.show-icon'));
      };

      ServiceTreeView.prototype.toggleLeafButton = function(event) {
        return this.toggleElement($(event.currentTarget));
      };

      ServiceTreeView.prototype.toggleButton = function(event) {
        this.removeTooltip();
        event.preventDefault();
        event.stopPropagation();
        return this.toggleElement($(event.target));
      };

      ServiceTreeView.prototype.showTooltip = function(event) {
        var $targetEl, buttonOffset, originalOffset;
        this.removeTooltip();
        this.$tooltipElement = $("<div id=\"tooltip\">" + (i18n.t('sidebar.show_tooltip')) + "</div>");
        $targetEl = $(event.currentTarget);
        $('body').append(this.$tooltipElement);
        buttonOffset = $targetEl.offset();
        originalOffset = this.$tooltipElement.offset();
        this.$tooltipElement.css('top', "" + (buttonOffset.top + originalOffset.top) + "px");
        return this.$tooltipElement.css('left', "" + (buttonOffset.left + originalOffset.left) + "px");
      };

      ServiceTreeView.prototype.removeTooltip = function(event) {
        var _ref;
        return (_ref = this.$tooltipElement) != null ? _ref.remove() : void 0;
      };

      ServiceTreeView.prototype.getShowIconClasses = function(showing, rootId) {
        if (showing) {
          return "show-icon selected service-color-" + rootId;
        } else {
          return "show-icon service-hover-color-" + rootId;
        }
      };

      ServiceTreeView.prototype.toggleElement = function($targetElement) {
        var service, serviceId;
        serviceId = $targetElement.closest('li').data('service-id');
        if (this.selected(serviceId) !== true) {
          app.commands.execute('clearSearchResults');
          service = new models.Service({
            id: serviceId
          });
          return service.fetch({
            success: (function(_this) {
              return function() {
                return app.commands.execute('addService', service);
              };
            })(this)
          });
        } else {
          return app.commands.execute('removeService', serviceId);
        }
      };

      ServiceTreeView.prototype.handleBreadcrumbClick = function(event) {
        event.preventDefault();
        event.stopPropagation();
        return this.openService(event);
      };

      ServiceTreeView.prototype.openService = function(event) {
        var $target, index, serviceId, serviceName, spinnerOptions;
        $target = $(event.currentTarget);
        serviceId = $target.data('service-id');
        serviceName = $target.data('service-name');
        this.animationType = $target.data('slide-direction');
        if (!serviceId) {
          return null;
        }
        if (serviceId === 'root') {
          serviceId = null;
          this.breadcrumbs.splice(0, this.breadcrumbs.length);
        } else {
          index = _.indexOf(_.pluck(this.breadcrumbs, 'serviceId'), serviceId);
          if (index !== -1) {
            this.breadcrumbs.splice(index, this.breadcrumbs.length - index);
          }
          this.breadcrumbs.push({
            serviceId: serviceId,
            serviceName: serviceName
          });
        }
        spinnerOptions = {
          container: $target.get(0),
          hideContainerContent: true
        };
        return this.collection.expand(serviceId, spinnerOptions);
      };

      ServiceTreeView.prototype.onRender = function() {
        var $targetElement, $ul;
        if (this.serviceToDisplay) {
          $targetElement = this.$el.find("[data-service-id=" + this.serviceToDisplay.id + "]").find('.show-icon');
          this.serviceToDisplay = false;
          this.toggleElement($targetElement);
        }
        $ul = this.$el.find('ul');
        $ul.on('scroll', (function(_this) {
          return function(ev) {
            return _this.scrollPosition = ev.currentTarget.scrollTop;
          };
        })(this));
        $ul.scrollTop(this.scrollPosition);
        this.scrollPosition = 0;
        return this.setBreadcrumbWidths();
      };

      ServiceTreeView.prototype.setBreadcrumbWidths = function() {
        var $chevrons, $container, $crumbs, $lastCrumb, CRUMB_MIN_WIDTH, crumbWidth, lastWidth, spaceAvailable, spaceNeeded;
        CRUMB_MIN_WIDTH = 40;
        $container = this.$el.find('.header-item').last();
        $crumbs = $container.find('.crumb');
        if (!($crumbs.length > 1)) {
          return;
        }
        $lastCrumb = $crumbs.last();
        $crumbs = $crumbs.not(':last');
        $chevrons = $container.find('.icon-icon-forward');
        spaceAvailable = $container.width() - ($chevrons.length * $chevrons.first().outerWidth());
        lastWidth = $lastCrumb.width();
        spaceNeeded = lastWidth + $crumbs.length * CRUMB_MIN_WIDTH;
        if (spaceNeeded > spaceAvailable) {
          lastWidth = spaceAvailable - $crumbs.length * CRUMB_MIN_WIDTH;
          $lastCrumb.css({
            'max-width': lastWidth
          });
          return $crumbs.css({
            'max-width': CRUMB_MIN_WIDTH
          });
        } else {
          crumbWidth = (spaceAvailable - lastWidth) / $crumbs.length;
          return $crumbs.css({
            'max-width': crumbWidth
          });
        }
      };

      ServiceTreeView.prototype.selected = function(serviceId) {
        return this.selectedServices.get(serviceId) != null;
      };

      ServiceTreeView.prototype.close = function() {
        this.removeTooltip();
        this.remove();
        return this.stopListening();
      };

      ServiceTreeView.prototype.serializeData = function() {
        var back, classes, data, listItems, parentItem;
        classes = function(category) {
          if (category.get('children').length > 0) {
            return ['service has-children'];
          } else {
            return ['service leaf'];
          }
        };
        listItems = this.collection.map((function(_this) {
          return function(category) {
            var rootId, selected;
            selected = _this.selected(category.id);
            rootId = category.get('root');
            return {
              id: category.get('id'),
              name: category.getText('name'),
              classes: classes(category).join(" "),
              has_children: category.attributes.children.length > 0,
              unit_count: category.attributes.unit_count || 1,
              selected: selected,
              root_id: rootId,
              show_icon_classes: _this.getShowIconClasses(selected, rootId)
            };
          };
        })(this));
        parentItem = {};
        back = null;
        if (this.collection.chosenService) {
          back = this.collection.chosenService.get('parent') || 'root';
          parentItem.name = this.collection.chosenService.getText('name');
          parentItem.rootId = this.collection.chosenService.get('root');
        }
        return data = {
          back: back,
          parent_item: parentItem,
          list_items: listItems,
          breadcrumbs: _.initial(this.breadcrumbs)
        };
      };

      ServiceTreeView.prototype.onRender = function() {
        var $target;
        $target = null;
        if (this.collection.chosenService) {
          $target = this.$el.find('li.service.parent.header-item');
        } else {
          $target = this.$el.find('li.service').first();
        }
        return _.defer((function(_this) {
          return function() {
            return $target.focus().addClass('autofocus').on('blur', function() {
              return $target.removeClass('autofocus');
            });
          };
        })(this));
      };

      return ServiceTreeView;

    })(base.SMLayout);
  });

}).call(this);

//# sourceMappingURL=service-tree.js.map
