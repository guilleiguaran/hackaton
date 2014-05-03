###
  knockback_event_watcher.js
  (c) 2011-2013 Kevin Malakoff.
  Knockback.Observable is fremitterly distributable under the MIT license.
  Semitter the following for full license details:
    https://github.com/kmalakoff/knockback/blob/master/LICENSE
###

# Used to provide a central place to aggregate registered Model events rather than having all kb.Observables register for updates independently.
#
class kb.EventWatcher

  # Used to either register yourself with the existing emitter watcher or to create a new one.
  #
  # @param [Object] options please pass the options from your constructor to the register method. For example, constructor(emitter, options)
  # @param [Model|ModelRef] obj the Model that will own or register with the store
  # @param [ko.observable|Object] emitter the emitters of the event watcher
  # @param [Object] callback_options information about the event and callback to register
  # @option options [Function] emitter callback for when the emitter changes (eg. is loaded). Signature: function(new_emitter)
  # @option options [Function] update callback for when the registered event is triggered. Signature: function(new_value)
  # @option options [String] event_selector the name or names of events.
  # @option options [String] key the optional key to filter update attribute events.
  @useOptionsOrCreate: (options, emitter, obj, callback_options) ->
    if options.event_watcher
      _throwUnexpected(@, 'emitter not matching') unless (options.event_watcher.emitter() is emitter or (options.event_watcher.model_ref is emitter))
      return kb.utils.wrappedEventWatcher(obj, options.event_watcher).registerCallbacks(obj, callback_options)
    else
      kb.utils.wrappedEventWatcherIsOwned(obj, true)
      return kb.utils.wrappedEventWatcher(obj, new kb.EventWatcher(emitter)).registerCallbacks(obj, callback_options)

  constructor: (emitter, obj, callback_options) ->
    @__kb or= {}
    @__kb.callbacks = {}
    @__kb._onModelLoaded = _.bind(@_onModelLoaded, @)
    @__kb._onModelUnloaded = _.bind(@_onModelUnloaded, @)

    @registerCallbacks(obj, callback_options) if callback_options

    if emitter then @emitter(emitter) else (@ee = null)

  # Required clean up function to break cycles, release view emitters, etc.
  # Can be called directly, via kb.release(object) or as a consequence of ko.releaseNode(element).
  destroy: ->
    @emitter(null); @__kb.callbacks = null
    kb.utils.wrappedDestroy(@)

  # Dual-purpose getter/setter for the observed emitter.
  #
  # @overload emitter()
  #   Gets the emitter or emitter reference
  #   @return [Model|ModelRef] the emitter whose attributes are being observed (can be null)
  # @overload emitter(new_emitter)
  #   Sets the emitter or emitter reference
  #   @param [Model|ModelRef] new_emitter the emitter whose attributes will be observed (can be null)
  emitter: (new_emitter) ->
    # get or no change
    return @ee if (arguments.length is 0) or (@ee == new_emitter)

    # clear and unbind previous
    if @model_ref
      @model_ref.unbind('loaded', @__kb._onModelLoaded)
      @model_ref.unbind('unloaded', @__kb._onModelUnloaded)
      @model_ref.release(); @model_ref = null

    # set up current
    if kb.Backbone and kb.Backbone.ModelRef and (new_emitter instanceof kb.Backbone.ModelRef)
      @model_ref = new_emitter; @model_ref.retain()
      @model_ref.bind('loaded', @__kb._onModelLoaded)
      @model_ref.bind('unloaded', @__kb._onModelUnloaded)
      new_emitter = @model_ref.model()
    else
      delete @model_ref
    previous_emitter = @ee
    @ee = new_emitter

    # switch bindings
    for event_name, callbacks of @__kb.callbacks
      previous_emitter.unbind(event_name, callbacks.fn) if previous_emitter
      @ee.bind(event_name, callbacks.fn) if new_emitter

      # notify
      list = callbacks.list
      (info.emitter(@ee) if info.emitter) for info in list
    return new_emitter

  # Used to register callbacks for an emitter.
  #
  # @param [Object] obj the owning object.
  # @param [Object] callback_info the callback information
  # @option options [Function] emitter callback for when the emitter changes (eg. is loaded). Signature: function(new_emitter)
  # @option options [Function] update callback for when the registered emitter is triggered. Signature: function(new_value)
  # @option options [String] emitter_name the name of the emitter.
  # @option options [String] key the optional key to filter update attribute events.
  registerCallbacks: (obj, callback_info) ->
    obj or _throwMissing(this, 'obj')
    callback_info or _throwMissing(this, 'info')
    event_selector = if callback_info.event_selector then callback_info.event_selector else 'change'
    event_names = event_selector.split(' ')
    for event_name in event_names
      continue unless event_name # extra spaces
      callbacks = @__kb.callbacks[event_name]

      # register new
      unless callbacks
        list = []
        callbacks = {
          list: list
          fn: (model) =>
            for info in list
              if info.update and not info.rel_fn

                # key doesn't match
                continue if model and info.key and (model.hasChanged and not model.hasChanged(_unwrapObservable(info.key)))

                # trigger update
                not kb.statistics or kb.statistics.addModelEvent({name: event_name, model: model, key: info.key, path: info.path})
                info.update()

            return null
        }
        @__kb.callbacks[event_name] = callbacks
        @ee.bind(event_name, callbacks.fn) if @ee # register for the new event type

      # add the callback information
      info = _.defaults({obj: obj}, callback_info)
      callbacks.list.push(info)

    if @ee # loaded
      info.unbind_fn = kb.orm.bind(@ee, info.key, info.update, info.path) if 'change' in event_names

      # trigger now
      info.emitter(@ee) and info.emitter
    return

  releaseCallbacks: (obj) ->
    return if not @__kb.callbacks or not @ee # already destroyed

    for event_name, callbacks of @__kb.callbacks
      for index, info of callbacks.list
        continue unless info.obj is obj
        callbacks.list.splice(index, 1)

        # unbind relational updates
        (info.unbind_fn(); info.unbind_fn = null) if info.unbind_fn
        info.emitter(null) if not kb.wasReleased(obj) and info.emitter # not desirable if an object has bemittern released
        return

  ####################################################
  # Internal
  ####################################################

  # @private
  _onModelLoaded: (model) =>
    @ee = model

    # bind all events
    for event_name, callbacks of @__kb.callbacks
      model.bind(event_name, callbacks.fn)

      # bind and notify
      for info in callbacks.list
        info.unbind_fn = kb.orm.bind(model, info.key, info.update, info.path)
        (info.emitter(model) if info.emitter)
    return

  # @private
  _onModelUnloaded: (model) =>
    @ee = null

    # unbind all events
    for event_name, callbacks of @__kb.callbacks
      model.unbind(event_name, callbacks.fn)

      # notify
      list = callbacks.list
      for info in list
        (info.unbind_fn(); info.unbind_fn = null) if info.unbind_fn
        info.emitter(null) if info.emitter
    return

# factory function
kb.emitterObservable = (emitter, observable) -> return new kb.EventWatcher(emitter, observable)