child_process = require 'child_process'
path = require 'path'
uuid = require 'node-uuid'
Promise = require 'bluebird'
{EventEmitter} = require 'events'

WrapbackMagic = require './wrapback-magic'

module.exports = class WorkerMarshal extends EventEmitter
	constructor: (requirePath) ->
		requirePath ?= process.cwd()
		workerModule = path.resolve __dirname, '../worker/index.js'

		forkOpts =
			cwd: process.cwd()
			env: process.env

		@_inflightWork = {}
		@_worker = child_process.fork workerModule, [requirePath], forkOpts

		@_ready = new Promise (resolve, reject) =>
			@_worker.once 'message', (msg) ->
				if msg.type is 'worker:startup'
					resolve()
				else
					reject()

		@_worker.on 'message', (msg) =>
			switch msg.type
				when 'work:resolve'
					@_inflightWork[msg.id]?.resolve msg.value
					delete @_inflightWork[msg.id]
					@emit 'taskFinished'

				when 'work:reject'
					@_inflightWork[msg.id]?.reject msg.reason
					delete @_inflightWork[msg.id]
					@emit 'taskFinished'

	ready: -> @_ready

	dispatch: (fn, args) ->
		id = uuid.v1()

		wrapback = undefined
		args.forEach (arg, i) ->
			if arg instanceof WrapbackMagic
				if wrapback?
					throw new Error 'cannot define multiple wrapped callbacks'

				wrapback = {argnum: i, opts: arg.opts}

		msg = {
			type: 'work',
			workFn: fn.toString(),
			wrapback: wrapback,
			id,
			args
		}

		new Promise (resolve, reject) =>
			sendCb = (err) =>
				if err?
					return reject 'Contractor: failed to deliver work to child'

				@_inflightWork[id] = {resolve, reject}

			unless @_worker.send(msg, sendCb)
				reject 'Contractor: failed to send work to child'
