(function() {
  var module, w,
    __slice = [].slice,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  w = window;

  w.ck = CoffeeKup;

  w.wait = function(someTime, thenDo) {
    return setTimeout(thenDo, someTime);
  };

  w.doEvery = function(someTime, action) {
    return setInterval(action, someTime);
  };

  Backbone.Model.prototype.connectSocket = Backbone.Collection.prototype.connectSocket = Backbone.View.prototype.connectSocket = function() {
    var _ref;
    return (_ref = this.io) != null ? _ref : this.io = window.app.sock;
  };

  Backbone.View.prototype.open = function(cont) {
    if (cont == null) {
      cont = 'body';
    }
    this.$el.appendTo(cont);
    this.trigger('open', cont);
    return this;
  };

  module = function(target, name, block) {
    var item, top, _i, _len, _ref, _ref1;
    if (arguments.length < 3) {
      _ref = [(typeof exports !== 'undefined' ? exports : window)].concat(__slice.call(arguments)), target = _ref[0], name = _ref[1], block = _ref[2];
    }
    top = target;
    _ref1 = name.split('.');
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      item = _ref1[_i];
      target = target[item] || (target[item] = {});
    }
    return block(target, top);
  };

  module('UI', function(exports, top) {
    var Slider;
    Slider = (function(_super) {

      __extends(Slider, _super);

      function Slider() {
        return Slider.__super__.constructor.apply(this, arguments);
      }

      Slider.prototype.tagName = 'div';

      Slider.prototype.className = 'slider-cont';

      Slider.prototype.initialize = function() {
        return _.defaults(this.options, {
          min: 0,
          max: 100,
          handleWidthPerc: 0
        });
      };

      Slider.prototype.template = function() {
        return div({
          "class": 'slider-groove'
        }, function() {
          return div({
            "class": 'slider-handle'
          });
        });
      };

      Slider.prototype.render = function() {
        this.$el.html(ck.render(this.template));
        this.on('open', function() {
          this.groove = this.$('.slider-groove');
          this.handle = this.$('.slider-handle');
          return this.setHandleWidthPerc(this.options.handleWidthPerc * this.grooveW() / 100);
        });
        return this;
      };

      Slider.prototype.events = {
        'mousedown': 'startDrag',
        'mouseup': 'stopDrag',
        'mousemove': 'drag'
      };

      Slider.prototype.handleW = function() {
        return this.handle.width();
      };

      Slider.prototype.handleX = function() {
        return this.handle.position().left;
      };

      Slider.prototype.getVal = function() {
        return this.options.min + (this.handleX() / this.grooveW()) * (this.options.max - this.options.min);
      };

      Slider.prototype.setVal = function(v) {
        this.setSliderX((v - this.options.min) / (this.options.max - this.options.min) * this.grooveW());
        return this;
      };

      Slider.prototype.grooveW = function() {
        return this.groove.width() - this.handleW();
      };

      Slider.prototype.setHandleWidthPerc = function(perc) {
        return this.handle.width((perc * this.grooveW() / 100) || 8);
      };

      Slider.prototype.setSliderX = function(x) {
        x = x - (this.handleW() / 2);
        x = x < 0 ? 0 : x > this.grooveW() ? this.grooveW() : x;
        this.$('.slider-handle').css('left', x);
        this.trigger('change', this.getVal());
        return this;
      };

      Slider.prototype.startDrag = function(e) {
        var newX, targetOffsetX;
        targetOffsetX = $(e.target).hasClass('slider-handle') ? this.handleX() : 0;
        newX = e.offsetX + targetOffsetX;
        this.setSliderX(newX);
        this.dragging = true;
        return this;
      };

      Slider.prototype.stopDrag = function(e) {
        this.dragging = false;
        return this;
      };

      Slider.prototype.drag = function(e) {
        var newX, targetOffsetX;
        targetOffsetX = $(e.target).hasClass('slider-handle') ? this.handleX() : 0;
        newX = e.offsetX + targetOffsetX;
        if (this.dragging) {
          this.setSliderX(newX);
        }
        return this;
      };

      return Slider;

    })(Backbone.View);
    return exports.Slider = Slider;
  });

  (function($) {
    return $.fn.center = function() {
      this.css("position", "absolute");
      this.css("top", Math.max(0, (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop()) + "px");
      this.css("left", Math.max(0, (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft()) + "px");
      return this;
    };
  })(jQuery);

  (function($) {
    return $.fn.slider = function(method) {
      var _this = this;
      this.methods = {
        init: function(options) {
          var groove, handle, root, _ref, _ref1,
            _this = this;
          if (options == null) {
            options = {};
          }
          if ((_ref = options.min) == null) {
            options.min = 0;
          }
          if ((_ref1 = options.max) == null) {
            options.max = 100;
          }
          handle = $('<div/>').addClass('slider-handle');
          groove = $('<div/>').addClass('slider-groove');
          root = $(this).addClass('slider-cont');
          handle.appendTo(groove);
          groove.appendTo(root);
          /*
                  handle.draggable {
                    containment: groove
                    axis: 'x'
                  }
          */

          root.on('mousedown', function(e) {
            _this.setHandleX(e.offsetX);
            return _this.data('dragging', true);
          });
          root.on('mouseover', function(e) {
            return _this.data('dragging', false);
          });
          return root.on('mousemove', function(e) {
            return _this.setHandleX(e.offsetX);
          });
        },
        setHandleX: function(x) {
          return handle.css('left', x - (handle.width() * 0.5));
        },
        update: function() {
          var newpx;
          console.log('move:', newpx = (this.data('v') - this.options.min) / (this.options.max - this.options.min));
          $(this).find('.slider-handle').css('left', newpx);
          return this;
        },
        val: function(v) {
          console.log(this.data('v'), v);
          if (v != null) {
            this.data('v', v);
            this.update;
            return this;
          } else {
            return this.data('v');
          }
        }
      };
      if (this.methods[method]) {
        return this.methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
      } else if (typeof method === "object" || !this.method) {
        return this.methods.init.apply(this, arguments);
      } else {
        return $.error("Method " + this.method + " does not exist");
      }
    };
  })(jQuery);

  module('App.Activity', function(exports, top) {
    var Model, Time, Timer, Views, _ref;
    Timer = (function() {

      Timer.prototype.cueTimes = [];

      function Timer(options) {
        this.options = options != null ? options : {};
        _(this).extend(Backbone.Events);
        _.defaults(this.options, {
          tickBank: 0,
          cues: [],
          autostart: false,
          loop: false,
          duration: null,
          speed: 1
        });
        this.tickBank = this.options.tickBank;
        this.cues = this.options.cues;
        this.setStatus('initialized');
        if (this.options.autostart) {
          this.start();
        }
      }

      Timer.prototype.normalize = function(secs) {
        return Math.floor(secs * 10);
      };

      Timer.prototype.seek = function(secs) {
        this.tickBank = Math.floor(secs * 1000);
        this.multiTrigger('event', 'seek', {
          from: this.currentSecs(),
          to: secs
        });
        return this;
      };

      Timer.prototype.start = function(silent) {
        var _this = this;
        if (silent == null) {
          silent = false;
        }
        this.setStatus('started', silent);
        this.tickMark = Date.now();
        this.engine = doEvery(25, function() {
          var act, thisTick, _i, _len, _ref, _ref1;
          _this.tickBank -= (_this.tickMark - (_this.tickMark = Date.now())) * _this.options.speed;
          _this.multiTrigger('event', 'tick');
          if (_ref = (thisTick = _this.normalize(_this.tickBank / 1000)), __indexOf.call(_this.cueTimes, _ref) >= 0) {
            _this.multiTrigger('event', 'cue', {
              comment: _this.comment
            });
            _ref1 = _this.cues;
            for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
              act = _ref1[_i];
              if (Math.floor(act.at * 10) === thisTick) {
                act.fn();
              }
            }
          }
          if (_this.options.duration && thisTick === _this.normalize(_this.options.duration)) {
            _this.multiTrigger('event', 'ended');
            if (_this.options.loop) {
              return _this.restart();
            } else {
              return _this.stop();
            }
          }
        });
        return this;
      };

      Timer.prototype.pause = function(silent) {
        if (silent == null) {
          silent = false;
        }
        clearTimeout(this.engine);
        this.setStatus('paused', silent);
        return this;
      };

      Timer.prototype.togglePlay = function(silent) {
        if (silent == null) {
          silent = false;
        }
        if (this.status === 'started') {
          this.pause();
        } else {
          this.start();
        }
        return this;
      };

      Timer.prototype.stop = function(silent) {
        if (silent == null) {
          silent = false;
        }
        this.pause(true);
        this.tickBank = 0;
        this.setStatus('stopped', silent);
        return this;
      };

      Timer.prototype.restart = function(silent) {
        if (silent == null) {
          silent = false;
        }
        this.multiTrigger('event', 'restarted');
        this.pause(true).stop(true).start();
        return this;
      };

      Timer.prototype.currentSecs = function() {
        return this.normalize(this.tickBank / 1000) / 10;
      };

      Timer.prototype.currentTimeObj = function() {
        var hrs, mins, secs, tenths, timeObj, totalSecs;
        totalSecs = this.currentSecs();
        hrs = Math.floor(totalSecs / 3600);
        mins = Math.floor((totalSecs - (3600 * hrs)) / 60);
        secs = Math.floor(totalSecs - (hrs * 3600) - (mins * 60));
        tenths = Math.floor(10 * (totalSecs - secs));
        return timeObj = {
          hrs: hrs,
          mins: mins,
          secs: secs,
          tenths: tenths
        };
      };

      Timer.prototype.setSpeed = function(speed) {
        return this.options.speed = speed;
      };

      Timer.prototype.addCues = function(newCues) {
        var cue, _i, _len;
        if (!_.isArray(newCues)) {
          newCues = [newCues];
        }
        for (_i = 0, _len = newCues.length; _i < _len; _i++) {
          cue = newCues[_i];
          cue.fn = _.debounce(cue.fn, 500, true);
          this.cues.push(cue);
          this.cueTimes.push(this.normalize(cue.at));
        }
        return this;
      };

      Timer.prototype.setStatus = function(status, silent) {
        this.status = status;
        if (silent == null) {
          silent = false;
        }
        if (!silent) {
          return this.multiTrigger('status', this.status);
        }
      };

      Timer.prototype.multiTrigger = function(type, name, data) {
        if (data == null) {
          data = {};
        }
        _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          type: type,
          name: name
        });
        this.trigger(name, _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          type: type
        }));
        this.trigger(type, _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          name: name
        }));
        return this.trigger('any', _.extend(data, {
          secs: this.currentSecs(),
          ticks: this.tickBank,
          type: type,
          name: name
        }));
      };

      return Timer;

    })();
    Time = (function() {

      function Time(totalSecs) {
        this.totalSecs = totalSecs;
        this.intSecs = Math.floor(this.totalSecs);
      }

      Time.prototype.getSecs = function() {
        var _ref;
        return (_ref = this.secs) != null ? _ref : this.secs = this.intSecs % 60;
      };

      Time.prototype.getMins = function() {
        var _ref;
        return (_ref = this.mins) != null ? _ref : this.mins = Math.floor((this.intSecs % 3600) / 60);
      };

      Time.prototype.getHrs = function() {
        return this.hrs || (this.hrs = Math.floor(this.intSecs / 3600));
      };

      Time.prototype.getTenths = function() {
        var _ref;
        return (_ref = this.tenths) != null ? _ref : this.tenths = Math.floor(10 * (this.totalSecs - this.intSecs));
      };

      Time.prototype.getSecStr = function() {
        var s;
        return ((s = this.getSecs()) < 10 ? "0" : "") + s;
      };

      Time.prototype.getMinStr = function() {
        var m;
        return ((m = this.getMins()) < 10 ? "0" : "") + m;
      };

      Time.prototype.getHrStr = function() {
        var h;
        return ((h = this.getHrs()) < 10 ? "0" : "") + h;
      };

      Time.prototype.setSecs = function(totalSecs) {
        this.totalSecs = totalSecs;
        this.intSecs = Math.floor(this.totalSecs);
        this.hrs = this.mins = this.secs = this.tenths = null;
        return this;
      };

      Time.prototype.getTimeStr = function() {
        return "" + (this.getHrs() ? this.getHrStr() + ":" : "") + (this.getMinStr()) + ":" + (this.getSecStr()) + "." + (this.getTenths());
      };

      return Time;

    })();
    exports.Time = Time;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      Model.prototype.initialize = function() {
        this.events = new App.Activity.Event.Collection(this.get('events'));
        this.events.duration = this.get('duration');
        return this.timer = new Timer({
          duration: this.get('duration')
        });
      };

      return Model;

    })(Backbone.Model);
    exports.Views = Views = {};
    Views.Timeline = (function(_super) {

      __extends(Timeline, _super);

      function Timeline() {
        return Timeline.__super__.constructor.apply(this, arguments);
      }

      Timeline.prototype.tagName = 'div';

      Timeline.prototype.className = 'timeline';

      Timeline.prototype.initialize = function() {
        var _this = this;
        this.pixelScaleFactor = $(window).width() * 0.94 / this.model.get('duration');
        this.on('open', function() {
          _this.zoomControl.on('change', function(newZoomLevel) {
            console.log(newZoomLevel);
            _this.scaleTime(newZoomLevel);
            return _this.moveCursorToTime('timer', _this.timer.model.currentSecs());
          });
          return _this.scaleTime(1);
        });
        $(window).resize(function() {
          _this.pixelScaleFactor = $(window).width() * 0.94 / _this.model.get('duration');
          return _this.render();
        });
        this.timer = new Views.Timer({
          model: this.model.timer
        });
        this.zoomControl = new UI.Slider({
          min: 1,
          max: 4
        });
        this.model.timer.on('event', function(data) {
          var _ref;
          if ((_ref = data.name) === 'seek' || _ref === 'tick') {
            return _this.moveCursorToTime('timer', _this.model.timer.currentSecs());
          }
        });
        return this.model.timer.on('status', function(data) {
          if (data.name === 'started') {
            return _this.$('.timer-mark').addClass('active');
          } else if (data.name === 'stopped') {
            _this.$('.timer-mark').removeClass('active');
            return _this.moveCursorToTime('timer', _this.model.timer.currentSecs());
          }
        });
      };

      Timeline.prototype.events = {
        'mousedown .tick-marks': function(e) {
          var extra, target, x;
          target = $(e.target);
          extra = $(e.target).position().left;
          x = (target.hasClass('lbl') ? 0 : e.offsetX) + extra;
          if (this.userDragging) {
            this.model.timer.seek(this.toSecs(x));
          }
          this.userDragging = true;
          return this.model.timer.seek(Math.round(this.toSecs(x)));
        },
        'mouseup .tick-marks': function(e) {
          this.userDragging = false;
          return this.$('.user-mark').show();
        },
        'mousemove .tick-marks': function(e) {
          var extra, target, x;
          target = $(e.target);
          extra = $(e.target).position().left;
          x = (target.hasClass('lbl') ? 0 : e.offsetX) + extra;
          if (this.userDragging) {
            this.model.timer.seek(this.toSecs(x));
          }
          return this.moveCursorToTime('user', Math.round(this.toSecs(x)));
        },
        'mouseover .tick-marks': function(e) {
          return this.$('.user-mark').show();
        },
        'mouseout .tick-marks': function(e) {
          return this.$('.user-mark').hide();
        }
      };

      Timeline.prototype.moveCursorTo = function(type, x) {
        var t;
        if (type == null) {
          type = '';
        }
        this.$(".cursor-mark" + (type ? '.' + type + '-mark' : '')).css('left', x);
        t = new Time(this.toSecs(x));
        this.$(".user-mark .time-info").text(t.getTimeStr());
        return this;
      };

      Timeline.prototype.moveCursorToTime = function(type, secs) {
        var pixels;
        if (type == null) {
          type = '';
        }
        pixels = this.toPixels(secs);
        this.moveCursorTo(type, pixels);
        return this;
      };

      Timeline.prototype.toPixels = function(secs) {
        return secs * $('.time-cont').width() / this.model.get('duration');
      };

      Timeline.prototype.toSecs = function(pixels) {
        return pixels * this.model.get('duration') / this.$('.time-cont').width();
      };

      Timeline.prototype.scaleTime = function(zoomLevel) {
        var i, m, s, val, _i, _len, _ref;
        this.zoomLevel = zoomLevel;
        console.log('scaleTime ', this.zoomLevel, this.pixelScaleFactor);
        val = this.zoomLevel * this.pixelScaleFactor;
        this.$('.time-cont').width(val * this.model.get('duration'));
        _ref = this.$('.mark,.lbl');
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          m = _ref[i];
          s = $(m).data('sec');
          $(m).css('left', "" + (Math.floor(val * s)) + "px");
        }
        this.moveCursorToTime(this.timer.model.currentSecs());
        return this.addEvents();
      };

      Timeline.prototype.template = function() {
        div({
          "class": 'time-window'
        }, function() {
          return div({
            "class": 'time-cont'
          }, function() {
            div({
              "class": 'time'
            }, function() {});
            div({
              "class": 'cursor-mark user-mark'
            }, function() {
              return div({
                "class": 'time-info'
              }, 'xx:xx:xx');
            });
            div({
              "class": 'cursor-mark timer-mark'
            }, function() {});
            return div({
              "class": 'tick-marks'
            }, function() {
              var markLbl, sec, type, _i, _ref, _results;
              _results = [];
              for (sec = _i = 0, _ref = Math.floor(this.model.get('duration')); 0 <= _ref ? _i <= _ref : _i >= _ref; sec = 0 <= _ref ? ++_i : --_i) {
                type = sec % 60 === 0 ? 'minute' : sec % 30 === 0 ? 'half-minute' : sec % 15 === 0 ? 'quarter-minute' : sec % 5 === 0 ? 'five-second' : 'second';
                div({
                  "class": "" + type + "-mark mark",
                  'data-sec': "" + sec
                });
                markLbl = type === 'half-minute' || type === 'quarter-minute' ? (sec % 60) + 's' : (sec / 60) + 'm';
                if (type === 'half-minute' || type === 'quarter-minute' || type === 'minute') {
                  _results.push(span({
                    "class": "" + type + "-mark-lbl lbl",
                    'data-sec': "" + sec
                  }, "" + markLbl));
                } else {
                  _results.push(void 0);
                }
              }
              return _results;
            });
          });
        });
        div({
          "class": 'timer-cont'
        }, function() {});
        div({
          "class": 'time-scroll-cont'
        });
        return div({
          "class": 'scale-slider'
        });
      };

      Timeline.prototype.addEvent = function(ev) {
        var _ref;
        if ((_ref = ev.view) != null) {
          _ref.remove();
        }
        ev.view = new App.Activity.Event.Views.Event({
          model: ev
        });
        return ev.view.renderIn(this.$('.time'));
      };

      Timeline.prototype.render = function() {
        this.$el.html(ck.render(this.template, this));
        this.timer.render().open(this.$('.timer-cont'));
        this.zoomControl.render().open(this.$('.scale-slider'));
        return this;
      };

      Timeline.prototype.addEvents = function() {
        var ev, _i, _len, _ref;
        _ref = this.model.events.models;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          ev = _ref[_i];
          this.addEvent(ev);
        }
        return this;
      };

      return Timeline;

    })(Backbone.View);
    Views.Timer = (function(_super) {

      __extends(Timer, _super);

      function Timer() {
        return Timer.__super__.constructor.apply(this, arguments);
      }

      Timer.prototype.tagName = 'div';

      Timer.prototype.className = 'timer';

      Timer.prototype.initialize = function() {
        var _this = this;
        this.model.on('tick', function() {
          return _this.renderClock();
        });
        this.model.on('seek', function() {
          return _this.renderClock();
        });
        return this.model.on('status', function(event) {
          switch (event.name) {
            case "started":
              _this.$('.toggle-play').removeClass('btn-success');
              _this.$('.toggle-play i').removeClass('icon-play').addClass('icon-pause');
              return _this.$('.stop').removeClass('disabled');
            case "paused":
            case "stopped":
              _this.$('.toggle-play').addClass('btn-success');
              return _this.$('.toggle-play i').removeClass('icon-pause').addClass('icon-play');
            case "stopped":
              _this.$('.stop').addClass('disabled');
              return _this.renderClock();
          }
        });
      };

      Timer.prototype.events = {
        'click .toggle-play': function() {
          return this.model.togglePlay();
        },
        'click .stop': function() {
          return this.model.stop();
        },
        'click .speed-control a': function(e) {
          this.$('.speed-label').text($(e.currentTarget).text() + ' ');
          return this.model.setSpeed($(e.currentTarget).data('value'));
        }
      };

      Timer.prototype.clockTemplate = function() {
        var time;
        time = this.currentTimeObj();
        span({
          "class": 'mins digit'
        }, "" + time.mins);
        text(" : ");
        span({
          "class": 'secs digit'
        }, "" + time.secs);
        text(" . ");
        return span({
          "class": 'tenths digit'
        }, "" + time.tenths);
      };

      Timer.prototype.template = function() {
        div({
          "class": 'clock span4'
        }, function() {});
        return div({
          "class": 'btn-group span4'
        }, function() {
          button({
            "class": 'btn btn-success toggle-play'
          }, function() {
            return i({
              "class": 'icon-play'
            });
          });
          button({
            "class": 'btn btn-inverse stop'
          }, function() {
            return i({
              "class": 'icon-stop'
            });
          });
          a({
            "class": 'btn dropdown-toggle btn-inverse',
            'data-toggle': 'dropdown',
            href: '#'
          }, function() {
            span({
              "class": 'speed-label'
            }, '1x ');
            return span({
              "class": 'caret'
            });
          });
          return ul({
            "class": 'dropdown-menu speed-control'
          }, function() {
            li(function() {
              return a({
                'data-value': '0.25'
              }, '&frac14;x');
            });
            li(function() {
              return a({
                'data-value': '0.5'
              }, '&frac12;x');
            });
            li(function() {
              return a({
                'data-value': '0.75'
              }, '&frac34;x');
            });
            li(function() {
              return a({
                'data-value': '1'
              }, '1x');
            });
            li(function() {
              return a({
                'data-value': '1.5'
              }, '1&frac12;x');
            });
            return li(function() {
              return a({
                'data-value': '2'
              }, '2x');
            });
          });
        });
      };

      Timer.prototype.renderClock = function() {
        return this.$('.clock').html(ck.render(this.clockTemplate, this.model));
      };

      Timer.prototype.render = function() {
        this.$el.html(ck.render(this.template, this.model));
        this.renderClock();
        return this;
      };

      return Timer;

    })(Backbone.View);
    return _ref = [Timer, Model], exports.Timer = _ref[0], exports.Model = _ref[1], _ref;
  });

  module('App.Activity.Event', function(exports, top) {
    var Collection, Model, Views, _ref;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      return Model;

    })(Backbone.Model);
    Collection = (function(_super) {

      __extends(Collection, _super);

      function Collection() {
        return Collection.__super__.constructor.apply(this, arguments);
      }

      Collection.prototype.model = Model;

      Collection.prototype.initialize = function() {
        var _ref;
        return (_ref = this.duration) != null ? _ref : this.duration = 60;
      };

      return Collection;

    })(Backbone.Collection);
    exports.Views = Views = {};
    Views.Event = (function(_super) {

      __extends(Event, _super);

      function Event() {
        return Event.__super__.constructor.apply(this, arguments);
      }

      Event.prototype.tagName = 'div';

      Event.prototype.className = 'event';

      Event.prototype.renderIn = function(parent) {
        var style;
        console.log(parent.width());
        style = {
          width: this.model.get('duration') * $(parent).width() / this.model.collection.duration,
          left: this.model.get('start') * $(parent).width() / this.model.collection.duration
        };
        this.$el.css(style);
        this.$el.appendTo(parent);
        return this;
      };

      return Event;

    })(Backbone.View);
    return _ref = [Model, Collection], exports.Model = _ref[0], exports.Collection = _ref[1], _ref;
  });

  module('App', function(exports, top) {
    var Session, Views;
    Session = (function(_super) {

      __extends(Session, _super);

      function Session() {
        return Session.__super__.constructor.apply(this, arguments);
      }

      return Session;

    })(Backbone.Model);
    exports.Views = Views = {};
    Views.Main = (function(_super) {

      __extends(Main, _super);

      function Main() {
        return Main.__super__.constructor.apply(this, arguments);
      }

      Main.prototype.className = 'main';

      Main.prototype.tagName = 'div';

      Main.prototype.template = function() {
        i({
          "class": 'icon-plane plane'
        });
        return div({
          "class": 'hero-unit'
        }, function() {
          return h2('boilerplate!');
        });
      };

      Main.prototype.render = function() {
        this.$el.html(ck.render(this.template));
        this.$el.hide();
        return this;
      };

      Main.prototype.resize = function() {
        var x, y, _ref;
        this.$el.center();
        _ref = [$(window).width() / 7, $(window).height() / 7], x = _ref[0], y = _ref[1];
        move('.plane').set('left', x).set('top', y).end();
        move('.plane').scale($(window).height() / 600).end();
        return move('.hero-unit').scale($(window).height() / 600).end();
      };

      Main.prototype.open = function() {
        var _this = this;
        Main.__super__.open.call(this);
        this.resize();
        return wait(400, function() {
          _this.$el.center().fadeIn();
          return $(window).resize(function() {
            return _this.resize();
          });
        });
      };

      return Main;

    })(Backbone.View);
    return exports.Router = (function(_super) {

      __extends(Router, _super);

      function Router() {
        return Router.__super__.constructor.apply(this, arguments);
      }

      Router.prototype.views = {
        main: new App.Views.Main()
      };

      Router.prototype.clearViews = function(exceptFor) {
        var key, view, _ref, _results;
        _ref = this.views;
        _results = [];
        for (key in _ref) {
          view = _ref[key];
          if (key !== exceptFor) {
            _results.push(view.remove());
          }
        }
        return _results;
      };

      Router.prototype.routes = {
        '': 'home',
        'timeline': 'timeline',
        'timer': 'timer'
      };

      Router.prototype.home = function() {
        var v;
        v = new UI.Slider({
          handleWidthPerc: 25
        });
        v.render().open();
        return v.on('change', function(val) {
          return console.log('new val: ', val);
        });
      };

      Router.prototype.timeline = function() {
        this.clearViews();
        this.activity = new App.Activity.Model({
          duration: 600,
          events: [
            {
              start: 10,
              pause: true,
              duration: 5
            }, {
              start: 30,
              pause: false,
              duration: 10
            }
          ]
        });
        this.views.tl = new App.Activity.Views.Timeline({
          model: this.activity
        });
        return this.views.tl.render().open();
      };

      Router.prototype.timer = function() {
        var throttledLog;
        this.clearViews();
        console.log('route: timer');
        this.t = new App.Activity.Timer();
        this.t.addCues([
          {
            at: 4,
            fn: function() {
              return console.log('hi 4');
            }
          }, {
            at: 10,
            fn: function() {
              return console.log('hi 10');
            }
          }, {
            at: 4,
            fn: function() {
              return console.log('hello 4');
            }
          }, {
            at: 11,
            fn: function() {
              return console.log('yo yo');
            }
          }
        ]);
        throttledLog = _.throttle((function(txt) {
          return console.log(txt);
        }), 200, true);
        this.t.on('status', function(data) {
          var msg;
          return msg = "" + data.name + " at " + data.secs + "s";
        });
        this.v = new App.Activity.Views.Timer({
          model: this.t
        });
        return this.v.render().open();
      };

      return Router;

    })(Backbone.Router);
  });

  $(function() {
    var _ref;
    if ((_ref = app.router) == null) {
      app.router = new App.Router();
    }
    if (!window.user) {
      return Backbone.history.start();
    }
  });

}).call(this);
