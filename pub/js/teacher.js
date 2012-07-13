// Generated by CoffeeScript 1.3.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  module('App.File', function(exports, top) {
    var Collection, Model, Views, _ref;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      Model.prototype.idAttribute = '_id';

      Model.prototype.thumbBase = "http://s3.amazonaws.com/lingualabio-media";

      Model.prototype.iconHash = {
        video: 'facetime-video',
        image: 'picture',
        pdf: 'file',
        audio: 'volume-up'
      };

      Model.prototype.thumbnail = function() {
        var _ref,
          _this = this;
        console.log(this.get('type'), this.get('ext'));
        return (_ref = this.thumbnailUrl) != null ? _ref : this.thumbnailUrl = (function() {
          switch (_this.get('type')) {
            case 'video':
              return "" + _this.thumbBase + "/" + _this.id + "_0001.png";
            case 'image':
              return "" + _this.thumbBase + "/" + _this.id + "." + (_this.get('ext'));
            case 'audio':
              return "/img/mp3.png";
            case 'application':
              if (_this.get('ext') === 'pdf') {
                return "/img/pdf.png";
              }
              break;
            default:
              return 'http://placehold.it/100x100';
          }
        })();
      };

      Model.prototype.icon = function() {
        if (this.get('type') === 'application') {
          return this.iconHash[this.get('ext')];
        } else {
          return this.iconHash[this.get('type')];
        }
      };

      return Model;

    })(Backbone.Model);
    Collection = (function(_super) {

      __extends(Collection, _super);

      function Collection() {
        return Collection.__super__.constructor.apply(this, arguments);
      }

      Collection.prototype.model = Model;

      Collection.prototype.url = '/t/files';

      Collection.prototype.initialize = function() {
        return this.fetch();
      };

      Collection.prototype.comparator = function() {
        return 0 - this.get('created');
      };

      Collection.prototype.filteredBy = function(searchTerm) {
        return this.filter(function(m) {
          var re;
          re = new RegExp(searchTerm, 'i');
          return re.test(m.get('title'));
        });
      };

      Collection.prototype.fromDB = function(data) {
        var method, model, options;
        method = data.method, model = data.model, options = data.options;
        console.log('updating ', model);
        switch (method) {
          case 'create':
            return this.add(model);
          case 'status':
            return this.get(model._id).set(model);
        }
      };

      Collection.prototype.uploadFile = function(file) {
        var onProgress, onSuccess, uplTask;
        onProgress = function(e) {
          var perc;
          return uplTask.trigger('progress', perc = Math.round((e.position / e.total) * 100));
        };
        onSuccess = function() {
          return uplTask.trigger('complete');
        };
        uplTask = $.upload("/upload", file, {
          upload: {
            progress: onProgress
          },
          success: onSuccess
        });
        _.extend(uplTask, Backbone.Events);
        console.log('upl task', uplTask);
        uplTask.file = file;
        return this.trigger('upload:start', uplTask);
      };

      return Collection;

    })(Backbone.Collection);
    exports.Views = Views = {};
    Views.DragOver = (function(_super) {

      __extends(DragOver, _super);

      function DragOver() {
        return DragOver.__super__.constructor.apply(this, arguments);
      }

      DragOver.prototype.dragOver = function(e) {
        e.originalEvent.dataTransfer.dropEffect = "copy";
        e.stopPropagation();
        e.preventDefault();
        return false;
      };

      DragOver.prototype.dragEnter = function(e) {
        console.log('dragenter', $(e.target));
        e.stopPropagation();
        e.preventDefault();
        return false;
      };

      DragOver.prototype.dragLeave = function(e) {
        console.log('dragleave', $(e.target));
        e.stopPropagation();
        e.preventDefault();
        return false;
      };

      DragOver.prototype.drop = function(e) {
        var f, files, i, _i, _len;
        e.stopPropagation();
        e.preventDefault();
        files = e.originalEvent.dataTransfer.files;
        i = 0;
        for (_i = 0, _len = files.length; _i < _len; _i++) {
          f = files[_i];
          console.log('uploading ', f);
          this.collection.uploadFile(f);
        }
        return false;
      };

      return DragOver;

    })(Backbone.View);
    Views.Main = (function(_super) {

      __extends(Main, _super);

      function Main() {
        return Main.__super__.constructor.apply(this, arguments);
      }

      Main.prototype.tagName = 'div';

      Main.prototype.className = 'files-main';

      Main.prototype.events = {
        'click .toggle-list': 'toggleList',
        'dragenter': 'dragEnter',
        'dragleave': 'dragLeave',
        'drop': 'drop',
        'keyup .search-query': function(e) {
          var _this = this;
          clearTimeout(this.searchWait);
          return this.searchWait = wait(200, function() {
            return _this.currentList.doSearch($(e.target).val());
          });
        }
      };

      Main.prototype.initialize = function() {
        var _ref, _ref1,
          _this = this;
        if ((_ref = this.browser) == null) {
          this.browser = new Views.Browser({
            collection: this.collection
          });
        }
        if ((_ref1 = this.list) == null) {
          this.list = new Views.List({
            collection: this.collection
          });
        }
        this.currentList = this.browser;
        this.collection.on('reset', function() {
          return _this.renderList();
        });
        return this.collection.on('upload:start', function(task) {
          task.view = new Views.UploadProgress({
            model: task
          });
          return task.view.render().$el.prependTo(_this.$el);
        });
      };

      Main.prototype.template = function() {
        div({
          "class": 'row'
        }, function() {
          span({
            "class": 'btn-toolbar span3'
          }, function() {
            return input({
              "class": 'search-query span3',
              type: 'text',
              placeholder: 'search'
            });
          });
          return span({
            "class": 'btn-toolbar span9 pull-right'
          }, function() {
            span({
              classs: 'btn-loose-group pull-left'
            }, function() {
              a({
                "class": 'btn tt',
                rel: 'tooltip',
                'data-original-title': "you can also add files by dragging them right onto the window!"
              }, function() {
                i({
                  "class": 'icon-info'
                });
                return i({
                  "class": 'icon-hand-up'
                });
              });
              button({
                "class": 'btn select-upload tt',
                rel: 'tooltip',
                'data-original-title': 'upload files from your computer'
              }, function() {
                text("+ ");
                return i({
                  "class": 'icon-folder-open'
                });
              });
              return button({
                "class": 'btn internet-upload tt',
                rel: 'tooltip',
                'data-original-title': 'find files on the internet to upload'
              }, function() {
                text("+ ");
                return i({
                  "class": 'icon-cloud'
                });
              });
            });
            return span({
              "class": 'btn-group pull-right',
              'data-toggle': 'buttons-radio'
            }, function() {
              button({
                "class": "btn toggle-list " + (this.currentList === this.browser ? 'active' : '')
              }, function() {
                return i({
                  "class": 'icon-th'
                });
              });
              return button({
                "class": "btn toggle-list " + (this.currentList === this.list ? 'active' : '')
              }, function() {
                return i({
                  "class": 'icon-list'
                });
              });
            });
          });
        });
        return div({
          "class": 'files-list'
        }, function() {});
      };

      Main.prototype.doSearch = function() {
        return console.log('searching!!!');
      };

      Main.prototype.toggleList = function() {
        console.log('toggle-list');
        this.currentList.remove();
        this.currentList = this.currentList === this.browser ? this.list : this.browser;
        return this.renderList();
      };

      Main.prototype.renderList = function() {
        this.currentList.remove();
        return this.currentList.render().open(this.$('.files-list'));
      };

      Main.prototype.render = function() {
        this.$el.html(ck.render(this.template, this));
        this.renderList();
        this.$('.tt').tooltip();
        this.delegateEvents();
        return this;
      };

      return Main;

    })(Views.DragOver);
    Views.UploadProgress = (function(_super) {

      __extends(UploadProgress, _super);

      function UploadProgress() {
        return UploadProgress.__super__.constructor.apply(this, arguments);
      }

      UploadProgress.prototype.tagName = 'div';

      UploadProgress.prototype.className = 'uplaod-progress row';

      UploadProgress.prototype.initialize = function() {
        var _this = this;
        console.log('new upl task model: ', this.model);
        this.model.on('progress', function(perc) {
          _this.setPercentTo(perc);
          if (perc === 100) {
            return _this.remove();
          }
        });
        return this.model.on('success', function() {
          return _this.remove();
        });
      };

      UploadProgress.prototype.template = function() {
        span({
          "class": 'span2 pull-left'
        }, "" + this.name);
        return span({
          "class": 'span9 pull-right'
        }, function() {
          return div({
            "class": 'progress upload-progress'
          }, function() {
            return div({
              "class": 'bar'
            });
          });
        });
      };

      UploadProgress.prototype.setPercentTo = function(p) {
        this.$('.bar').width("" + p + "%");
        return this;
      };

      return UploadProgress;

    })(Backbone.View);
    Views.Browser = (function(_super) {

      __extends(Browser, _super);

      function Browser() {
        this.addItem = __bind(this.addItem, this);
        return Browser.__super__.constructor.apply(this, arguments);
      }

      Browser.prototype.tagName = 'div';

      Browser.prototype.className = 'file-browser';

      Browser.prototype.initialize = function() {
        var _this = this;
        this.collection.on('add', this.addItem);
        this.collection.on('change', function(f) {
          return f.brItemView.render();
        });
        return this.collection.on('reset', function() {
          return _this.render();
        });
      };

      Browser.prototype.doSearch = function(searchTerm) {
        this.searchTerm = searchTerm;
        return this.render();
      };

      Browser.prototype.template = function() {
        return ul({
          "class": 'thumbnails'
        }, function() {});
      };

      Browser.prototype.addItem = function(f) {
        var _ref;
        if ((_ref = f.brItemView) == null) {
          f.brItemView = new Views.BrowserItem({
            model: f
          });
        }
        f.brItemView.render().open(this.$('ul.thumbnails'));
        return this;
      };

      Browser.prototype.render = function() {
        var f, _i, _len, _ref;
        this.$el.html(ck.render(this.template));
        _ref = (this.searchTerm ? this.collection.filteredBy(this.searchTerm) : this.collection.models);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          f = _ref[_i];
          this.addItem(f);
        }
        return this;
      };

      return Browser;

    })(Backbone.View);
    Views.List = (function(_super) {

      __extends(List, _super);

      function List() {
        this.addItem = __bind(this.addItem, this);
        return List.__super__.constructor.apply(this, arguments);
      }

      List.prototype.tagName = 'div';

      List.prototype.className = 'container file-list';

      List.prototype.initialize = function() {
        var _this = this;
        this.collection.on('add', this.addItem);
        this.collection.on('change', function(f) {
          return f.listItemView.render();
        });
        return this.collection.on('reset', function() {
          return _this.render();
        });
      };

      List.prototype.doSearch = function(searchTerm) {
        this.searchTerm = searchTerm;
        return this.render();
      };

      List.prototype.template = function() {
        return table({
          "class": 'table table-fluid span12'
        }, function() {
          thead(function() {});
          tbody(function() {});
          return tfoot(function() {});
        });
      };

      List.prototype.addItem = function(f) {
        var _ref, _ref1;
        if ((_ref = f.listItemView) != null) {
          _ref.remove();
        }
        if ((_ref1 = f.listItemView) == null) {
          f.listItemView = new Views.ListItem({
            model: f
          });
        }
        f.listItemView.render().open(this.$('tbody'));
        return this;
      };

      List.prototype.render = function() {
        var f, input, upl, _i, _len, _ref;
        this.$el.html(ck.render(this.template, this.collection));
        _ref = (this.searchTerm ? this.collection.filteredBy(this.searchTerm) : this.collection.models);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          f = _ref[_i];
          this.addItem(f);
        }
        upl = this.collection.uploadFile;
        input = this.$('.select-upload').browseElement();
        input.on('change', function(e) {
          var _j, _len1, _ref1, _results;
          _ref1 = e.target.files;
          _results = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            f = _ref1[_j];
            console.log('uploading ', f);
            _results.push(upl(f));
          }
          return _results;
        });
        this.delegateEvents();
        return this;
      };

      return List;

    })(Backbone.View);
    Views.ListItem = (function(_super) {

      __extends(ListItem, _super);

      function ListItem() {
        return ListItem.__super__.constructor.apply(this, arguments);
      }

      ListItem.prototype.tagName = 'tr';

      ListItem.prototype.className = 'file-list-item';

      ListItem.prototype.events = {
        'change .title': function(e) {
          return this.model.save({
            title: $(e.target).val()
          });
        }
      };

      ListItem.prototype.template = function() {
        td(function() {
          return i({
            "class": "icon-" + (this.icon()) + " icon-large"
          });
        });
        td(function() {
          return input({
            "class": 'title',
            value: "" + (this.get('title'))
          });
        });
        td(moment(this.get('created')).format("MMM D h:mm:ss a"));
        return td(function() {
          return input({
            "class": 'tags',
            value: "" + (this.get('tags'))
          });
        });
      };

      ListItem.prototype.render = function() {
        this.delegateEvents();
        return ListItem.__super__.render.call(this);
      };

      return ListItem;

    })(Backbone.View);
    Views.BrowserItem = (function(_super) {

      __extends(BrowserItem, _super);

      function BrowserItem() {
        return BrowserItem.__super__.constructor.apply(this, arguments);
      }

      BrowserItem.prototype.tagName = 'li';

      BrowserItem.prototype.className = 'browser-item span3';

      BrowserItem.prototype.events = {
        'change .title': function(e) {
          return this.model.save({
            title: $(e.target).val()
          });
        }
      };

      BrowserItem.prototype.template = function() {
        div({
          "class": "thumbnail " + (this.get('type'))
        }, function() {
          img({
            src: "" + (this.thumbnail())
          });
          return i({
            "class": "icon-" + (this.icon()) + " icon-large file-type-icon"
          });
        });
        return div({
          "class": 'item-info caption'
        }, function() {
          return input({
            "class": 'title',
            value: "" + (this.get('title'))
          });
        });
      };

      BrowserItem.prototype.render = function() {
        BrowserItem.__super__.render.call(this);
        this.delegateEvents();
        return this;
      };

      return BrowserItem;

    })(Backbone.View);
    Views.Detail = (function(_super) {

      __extends(Detail, _super);

      function Detail() {
        return Detail.__super__.constructor.apply(this, arguments);
      }

      Detail.prototype.tagName = 'div';

      Detail.prototype.className = 'file-video-detail';

      Detail.prototype.template = function() {
        return video;
      };

      return Detail;

    })(Backbone.View);
    return _ref = [Model, Collection], exports.Model = _ref[0], exports.Collection = _ref[1], _ref;
  });

  module('App.Teacher', function(exports, top) {
    var Model, Views;
    Model = (function(_super) {

      __extends(Model, _super);

      function Model() {
        return Model.__super__.constructor.apply(this, arguments);
      }

      return Model;

    })(Backbone.Model);
    exports.Views = Views = {};
    Views.TopBar = (function(_super) {

      __extends(TopBar, _super);

      function TopBar() {
        return TopBar.__super__.constructor.apply(this, arguments);
      }

      TopBar.prototype.tagName = 'div';

      TopBar.prototype.className = 'top-bar navbar navbar-fixed-top';

      TopBar.prototype.template = function() {
        return div({
          "class": 'navbar-inner'
        }, function() {
          return div({
            "class": 'container'
          }, function() {
            a({
              "class": 'brand',
              href: '#'
            }, function() {
              i({
                "class": 'icon-beaker icon-large'
              });
              return span(' lingualab.io');
            });
            a({
              "class": 'btn btn-navbar',
              'data-toggle': 'collapse',
              'data-target': '.nav-collapse'
            }, function() {
              span({
                "class": 'icon-beaker icon-large'
              });
              return span({
                "class": 'icon-reorder icon-large'
              });
            });
            return div({
              "class": 'nav-collapse'
            }, function() {
              ul({
                "class": 'nav'
              }, function() {
                return li(function() {
                  return a({
                    href: '#files'
                  }, function() {
                    i({
                      "class": 'icon-briefcase'
                    });
                    return text(' Files');
                  });
                });
              });
              return ul({
                "class": 'nav pull-right'
              }, function() {
                li({
                  "class": 'divider-vertical'
                });
                return li({
                  "class": 'dropdown'
                }, function() {
                  a({
                    href: '',
                    "class": 'dropdown-toggle',
                    'data-toggle': 'dropdown'
                  }, function() {
                    img({
                      src: "" + (this.get('twit').profileImageUrl)
                    });
                    text(" " + (this.get('twit').name) + " ");
                    return b({
                      "class": 'caret'
                    });
                  });
                  return ul({
                    "class": 'dropdown-menu'
                  }, function() {
                    li({
                      "class": 'divider'
                    });
                    return li(function() {
                      return a({
                        href: '/logout'
                      }, function() {
                        i({
                          "class": 'icon-signout'
                        });
                        return text(" sign out");
                      });
                    });
                  });
                });
              });
            });
          });
        });
      };

      TopBar.prototype.render = function() {
        this.$el.html(ck.render(this.template, this.model));
        return this;
      };

      return TopBar;

    })(Backbone.View);
    return exports.Router = (function(_super) {

      __extends(Router, _super);

      function Router() {
        return Router.__super__.constructor.apply(this, arguments);
      }

      Router.prototype.initialize = function() {
        this.extendRoutesWith(this.teacherRoutes);
        this.teacher = new Model(top.app.session.user);
        this.filez = new top.App.File.Collection(this.teacher.get('files'));
        this.views = {
          topBar: new Views.TopBar({
            model: this.teacher
          }),
          filez: new App.File.Views.Main({
            collection: this.filez
          })
        };
        this.fromDB();
        return this.showTopBar();
      };

      Router.prototype.teacherRoutes = {
        '/': 'home',
        'files': 'files'
      };

      Router.prototype.fromDB = function() {
        var _this = this;
        this.io = top.app.sock;
        return this.io.on('file:sync', function(data) {
          console.log('file:sync', data);
          return _this.filez.fromDB(data);
        });
      };

      Router.prototype.showTopBar = function() {
        return this.views.topBar.render().open();
      };

      Router.prototype.home = function() {
        console.log('home route');
        return this.clearViews('topBar');
      };

      Router.prototype.files = function() {
        console.log('files route');
        this.clearViews('topBar');
        return this.views.filez.render().open('.main');
      };

      Router.prototype.extra = function() {
        return console.log('get jiggy withit');
      };

      return Router;

    })(top.App.Router);
  });

}).call(this);
