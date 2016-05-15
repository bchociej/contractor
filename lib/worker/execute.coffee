Promise = require 'bluebird'

redirectedRequire = (what) ->
	requirePath = process.argv[2] ? process.cwd()
	# TODO FIXME LOL
	require what

rehydrateFn = (fn) ->
	createRealWorkFn = new Function 'require',
		'Promise',
		'process',
		'module',
		'rehydrateFn',
		'global',
		"return #{fn}"

	createRealWorkFn redirectedRequire, Promise

module.exports = (workFn, args, wrapback) ->
	if wrapback?.argnum?
		return Promise.fromCallback(((callback) ->
			args[wrapback.argnum] = callback
			rehydrateFn(workFn)(args...)
		), wrapback.opts)

	Promise.resolve rehydrateFn(workFn)(args...)
