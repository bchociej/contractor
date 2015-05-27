async  = require 'async'
packer = require '../function-packer/'

module.exports = class Worker
	constructor: ->
		process.on 'message', (tasks) ->
			async.each tasks, (task, tcb) ->
				workFn = packer.unpack task.workFn

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
