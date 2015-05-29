async = require 'async'
path  = require 'path'

Promise  = require 'bluebird'
Unpacker = require '../util/unpacker'

module.exports = class Worker
	constructor: (requirePath) ->
		unpacker     = new Unpacker 32
		requirePath ?= process.cwd()

		redirectedRequire = (what) ->
			if /^[\.]/.test(what)
				what = path.resolve requirePath, what

			return require(what)

		scopeInjections = {Promise, require: redirectedRequire}

		process.on 'message', (tasks) ->
			async.each tasks, (task, tcb) ->
				workFn = unpacker.unpack task.workFn, scopeInjections

				Promise.resolve(workFn(task.args...))
				.then (result) ->
					process.send
						taskId: task.id
						resolve: result

					tcb()
				.catch (error) ->
					process.send
						taskId: task.id
						reject: error

					tcb()
