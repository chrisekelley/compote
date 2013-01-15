class Router extends Backbone.Router
  routes:
    "": "default"
    "reports": "default"

  route: (route, name, callback) ->
    Backbone.history || (Backbone.history = new Backbone.History)
    if !_.isRegExp(route)
      route = this._routeToRegExp(route)
    Backbone.history.route(route, (fragment) =>
      args = this._extractParameters(route, fragment)
      callback.apply(this, args)

# Run this before
      $('#loading').slideDown()
      this.trigger.apply(this, ['route:' + name].concat(args))
# Run this after
      $('#loading').fadeOut()

    , this)

  default: (options) ->
    options = options?.split(/\//)
    reportViewOptions = {}

    # Allows us to get name/value pairs from URL
    _.each options, (option,index) ->
      unless index % 2
        reportViewOptions[option] = options[index+1]

    Coconut.reportView ?= new DashboardView()
    Coconut.reportView.render reportViewOptions

Coconut = {}
Coconut.router = new Router()
Backbone.history.start()

Coconut.debug = (string) ->
  console.log string
  $("#log").append string + "<br/>"
