child = require 'child_process'
path  = require 'path'
uuid  = require 'node-uuid'

Packer      = require '../util/packer'
Promise     = require 'bluebird'
WorkerError = require '../error/worker-error'

module.exports = class WorkerMarshal
	constructor: (requirePath, onWorkerReady) ->
		@deferreds = {}
		@packer = new Packer

		workerModule = path.resolve __dirname, '../worker/'

		# pretend this worker is in another process, e.g. child_process.fork()'d
		@worker = child.fork workerModule, [requirePath], {cwd: process.cwd()}

		@worker.on 'message', (msg) =>
			if msg.reject?
				rejection = msg.reject

				if rejection.isError
					rejection = new WorkerError(rejection.error.message, rejection.error.stack, rejection.error.name)
				else
					rejection = msg.reject.value

				@deferreds[msg.id].reject rejection
			else if msg.resolve?
				@deferreds[msg.id].resolve msg.resolve
			else
				return

			onWorkerReady this
			@deferreds[msg.id] = undefined

	run: (task) ->
		id = uuid.v1()
		return new Promise (resolve, reject) =>
			@deferreds[id] = {resolve, reject}

			process.nextTick => @worker.send [{
				workFn: @packer.pack task.workFn
				args: task.args
				id: id
			}]
