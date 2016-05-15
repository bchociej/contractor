os = require 'os'
Promise = require 'bluebird'
WorkerMarshal = require './worker-marshal'

module.exports = class WorkerPool
	constructor: (workers) ->
		workers ?= os.cpus().length

		unless typeof workers is 'number' and 0 < workers < Infinity
			throw new TypeError 'workers must be a finite, positive number'

		@_marshals = (new WorkerMarshal for i in [1..Math.floor(workers)])

		# prefer idle
		for marshal in @_marshals
			marshal.on 'idle', =>
				@_marshals = [marshal].concat @_marshals.filter (m) ->
					m isnt marshal

	ready: -> Promise.all @_marshals.map (m) -> m.ready()

	# TODO: should a marshall only have one task at a time? prolly not i guess but idk
	dispatch: (fn, args) ->
		nextMarshal = @_marshals.shift()
		@_marshals.push nextMarshal

		nextMarshal.dispatch fn, args
