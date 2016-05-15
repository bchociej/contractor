WorkerPool = require './worker-pool'
WrapbackMagic = require './wrapback-magic'

defaultOpts = {}

module.exports = class Contractor
	constructor: (opts = {}) ->
		@_opts = Object.assign({}, defaultOpts, opts)
		@_pool = new WorkerPool opts.workers

	ready: -> @_pool.ready()

	dispatch: (workFn, args...) -> @_pool.dispatch workFn, args

	wrap: (fn) -> (args...) => @dispatch fn, args...

	wrapback: (opts) -> new WrapbackMagic opts

Contractor.create = (args...) ->
	instance = new Contractor args...
	instance.ready().then -> instance
