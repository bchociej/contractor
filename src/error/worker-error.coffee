WorkerError = (message, stack, name) ->
	@name = 'WorkerError'
	@type = name
	@message = message
	@stack = stack

WorkerError.prototype = new Error

module.exports = WorkerError
