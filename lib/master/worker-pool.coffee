os = require 'os'
Promise = require 'bluebird'
WorkerMarshal = require './worker-marshal'
Scheduler = require './scheduler'

module.exports = class WorkerPool
	constructor: (workers) ->
		workers ?= os.cpus().length

		unless typeof workers is 'number' and 0 < workers < Infinity
			throw new TypeError 'workers must be a finite, positive number'

		@_marshals = (new WorkerMarshal for i in [1..Math.floor(workers)])
		@_scheduler = new Scheduler @_marshals

	ready: -> Promise.all @_marshals.map (m) -> m.ready()

	dispatch: (fn, args) -> @_scheduler.schedule 1, (marshal) -> marshal.dispatch fn, args
