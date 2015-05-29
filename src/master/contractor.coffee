path = require 'path'

CPUS = require('os').cpus().length

Scheduler  = require './scheduler'
WorkerPool = require './worker-pool'

module.exports = class Contractor
	constructor: (workers = CPUS) ->
		requirePath = path.dirname(module.parent?.filename) ? process.cwd()
		@pool       = new WorkerPool workers, requirePath
		@scheduler  = new Scheduler @pool

	doWork: (work, args=[], priority=1) ->
		return @scheduler.schedule {workFn: work, args: args}, priority
