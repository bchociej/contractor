WorkerPool = require './worker-pool'

defaultOpts = {}

module.exports = class Contractor
	constructor: (opts = {}) ->
		@_opts = Object.assign({}, defaultOpts, opts)
		@_pool = new WorkerPool opts.workers

	ready: -> @_pool.ready()
