async = require 'async'

module.exports = class Scheduler
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
