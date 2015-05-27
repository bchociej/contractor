async = require 'async'
child = require 'child_process'
path  = require 'path'
uuid  = require 'node-uuid'

Map     = require 'es6-map'
Promise = require 'bluebird'

packer = require '../function-packer/'


module.exports = class WorkerMarshal
	constructor: (opts = {}) ->
		opts.wd ?= __dirname
		opts.cargoPayload ?= 64

		workerModule = path.resolve __dirname, '../worker/'

		@responseHandlers = new Map
		@stopping = false
		@killed = false

		@worker = child.fork(workerModule, [], {cwd: opts.wd})

		@worker.on 'message', (msg) =>
			handler = @responseHandlers.get(msg.taskId)

			if msg.resolve?
				handler.resolve msg.resolve
			else if msg.reject?
				handler.reject msg.reject
			else
				return

			@responseHandlers.delete msg.taskId

		@cargo = async.cargo (tasks, cb) =>
			promises = tasks.map (t) -> t.promise
			tasks.forEach (t) -> t.promise = undefined

			emptyCallback = -> cb()
			Promise.all(promises).then emptyCallback, emptyCallback

			@worker.send tasks
		, opts.cargoPayload

	send: (work, args...) ->
		if @stopping or @killed
			throw new Error 'cannot send work to a killed or stopping worker'

		id = uuid.v1()

		p = new Promise (resolve, reject) =>
			@responseHandlers.set id,
				resolve: resolve
				reject: reject

		@cargo.push
			workFn: packer.pack work
			args: args
			id: id
			promise: p

		return p

	stop: ->
		@stopping = true

		return if @killed

		oldDrain = @worker.drain
		@worker.drain = =>
			oldDrain()
			@worker.kill() unless @killed

		if @cargo.length() is 0
			@worker.kill() unless @killed
			@killed = true

	kill: ->
		@stopping = true
		@worker.kill() unless @killed
		@killed = true
