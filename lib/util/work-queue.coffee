Promise = require 'bluebird'
{EventEmitter} = require 'events'

module.exports = class WorkQueue extends EventEmitter
	constructor: (concurrency = Infinity) ->
		@_nominalConcurrency = @_concurrency = @_tick = adding = null
		@_running = []
		@_queued = []
		@_pending = false
		@_stopped = false

		@concurrency concurrency

		# loop which runs each time a running task finishes or another is added
		pend = =>
			# filter finished promises from running list
			@_running = @_running.filter (r) -> r.isPending()

			# create a promise which is fulfilled when a task gets added
			unless adding?.isPending()
				adding = Promise.fromCallback (cb) => @_tick = cb

			# if possible, run the next queue item
			if @_running.length < @_concurrency and @_queued.length > 0
				next = @_queued.shift()
				@runImmediately(next.fn).asCallback next.cb

				@emit 'taskDequeued'

				if @_queued.length is 0
					@emit 'queueEmpty'

			# or else report idle
			else if @_running.length is 0

				# killed and no work left, so halt completely
				if @_nominalConcurrency is 0
					@emit 'halted'
					return

				# regular 'idle'; waiting for more work
				@emit 'idle'

			# and now, wait for something to happen!
			Promise.any(@_running.concat adding).then pend

		pend()

	# run task function `fn` if possible, otherwise, queue it
	# returns a Promise for the task function
	add: (fn) ->
		if @_stopped or @_nominalConcurrency is 0
			throw new Error 'cannot add(), work queue is stopped or killed'

		@emit 'taskAdded'

		if @_running.length >= @_concurrency
			promise = Promise.fromCallback (cb) => @_queued.push {fn, cb}

			if @_queued.length is 1
				@emit 'queuing'

			@emit 'taskQueued'

			return promise
		else
			@runImmediately fn

	# run the task function `fn` regardless of concurrency limit
	# returns a Promise for the task function
	runImmediately: (fn) ->
		if @_concurrency is 0
			throw new Error 'cannot runImmediately(), work queue is paused, stopped, or killed'

		promise = Promise.resolve(fn())

		@_running.push promise.reflect().tap (inspection) =>
			if inspection.isFulfilled()
				@emit 'taskFulfilled'

			if inspection.isRejected()
				@emit 'taskRejected'

			@emit 'taskFinished'

		@tick()

		if @_running.length is 1
			@emit 'working'

		@emit 'taskRunning'

		return promise

	# return number of running tasks
	running: -> @_running.length

	# return number of queued tasks
	queueLength: -> @_queued.length

	# force an iteration of the internal work-checking loop
	tick: -> @_tick()

	# get/set the concurrency limit
	# true => Infinity; false => 1
	concurrency: (newValue) ->
		if newValue?
			if newValue is true
				newValue = Infinity
			else if newValue is false
				newValue = 1

			unless typeof newValue is 'number' and newValue > 0
				throw new TypeError 'concurrency must be a positive number'

			unless @_concurrency is 0
				@_concurrency = newValue

			@_nominalConcurrency = newValue
			@tick()

		@_nominalConcurrency

	# pause the queue:
	# -> hold all queued tasks (don't run them)
	# -> add() queues all new tasks
	# -> disallow runImmediately()
	# -> running tasks are unaffected
	# -> can subsequently resume()
	pause: ->
		@emit 'paused'
		@_concurrency = 0
		@_stopped = false

	# stop the queue:
	# -> hold all queued tasks (don't run them)
	# -> disallow add() and runImmediately()
	# -> running tasks are unaffected
	# -> can subsequently resume()
	stop: ->
		@emit 'stopped'
		@_concurrency = 0
		@_stopped = true

	# resume the queue (remove stop/pause effects)
	resume: ->
		@emit 'resuming'
		@_concurrency = @_nominalConcurrency
		@_stopped = false
		@tick()

	# kill the queue:
	# -> reject all currently-queued tasks
	# -> disallow add() and runImmediately()
	# -> running tasks are unaffected
	# -> subsequently calls to pause(), stop(), or resume() have no effect
	kill: ->
		@emit 'killed'
		@_concurrency = @_nominalConcurrency = 0
		@_stopped = true
		@_queued.forEach (task) -> task.cb 'work queue has been killed'
		@_queued = []

	# return the current state of the work queue
	# 'active', 'paused', 'stopped', or 'killed'
	state: ->
		if @_nominalConcurrency is 0
			'killed'
		else if @_stopped
			'stopped'
		else if @_concurrency is 0
			'paused'
		else
			'active'

	# immediately kill the queue, abandon running work, and release resources
	# (cancels running Promises, which has no effect unless specially configured)
	HCF: ->
		@kill()
		@_running.forEach (r) -> r.cancel()
		@_running = []
		@emit 'tasksAbandoned'
		@tick()
