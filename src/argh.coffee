async = require 'async'
Promise = require 'bluebird'
uuid = require 'node-uuid'

CPUS = require('os').cpus().length

class Contractor
	constructor: (workers = CPUS) ->
		@pool      = new WorkerPool workers
		@scheduler = new Scheduler @pool

	doWork: (work, args=[], priority=1) ->
		return @scheduler.schedule {workFn: work, args: args}, priority

class Scheduler
	constructor: (pool) ->
		@pq = async.priorityQueue (taskWrapper, callback) ->
			pool.getWorker().then (worker) ->
				taskWrapper(worker)
				callback()
		, pool.getSize()

	schedule: (task, priority) ->
		return new Promise (resolve, reject) =>
			@pq.push (worker) ->
				worker.run(task)
					.then resolve
					.catch reject
			, priority

class WorkerPool
	dispatchWorkersIfPossible = (ds, ws) ->
		while ds.length > 0 and ws.length > 0
			ds.pop().resolve(ws.pop())

	constructor: (@size) ->
		@deferreds = []

		@workers = [1..@size].map =>
			new Worker (readyWorker) =>
				@workers.push readyWorker
				dispatchWorkersIfPossible(@deferreds, @workers)

	getSize: -> @size

	getWorker: ->
		return new Promise (resolve, reject) =>
			@deferreds.push {resolve, reject}
			dispatchWorkersIfPossible(@deferreds, @workers)

class Worker
	constructor: (onWorkerReady) ->
		@deferreds = {}

		# pretend this worker is in another process, e.g. child_process.fork()'d
		@worker = do ->
			onmessage = -> undefined
			Promise = require 'bluebird'

			return {
				send: (task) ->
					do (process=undefined, module=undefined, onmessage=onmessage) ->
						eval "var workFn = #{task.workFn}"

						Promise.resolve().then(-> workFn(task.args...))
						.then (result) -> onmessage({resolve: result, id: task.id})
						.catch (error) -> onmessage({reject: error, id: task.id})
				on: (ev, fn) ->
					if ev is 'message'
						onmessage = fn
			}

		@worker.on 'message', (msg) =>
			if msg.reject?
				@deferreds[msg.id].reject msg.reject
			else if msg.resolve?
				@deferreds[msg.id].resolve msg.resolve
			else
				return

			@deferreds[msg.id] = undefined

	run: (task) ->
		id = uuid.v1()
		return new Promise (resolve, reject) =>
			@deferreds[id] = {resolve, reject}

			process.nextTick => @worker.send {
				workFn: task.workFn.toString()
				args: task.args
				id: id
			}

module.exports = Contractor





# Example usage

c = new Contractor

add2 = (x) ->
	if typeof x isnt 'number'
		throw new TypeError("not a number: #{x}")

	return x + 2

# "success" example
c.doWork(add2, [5])
	.then (result) -> console.log(result)

# "error" example 1000ms later
setTimeout ->
	c.doWork(add2, ['hi mom'])
		.catch (error) -> console.error(error)
, 1000
