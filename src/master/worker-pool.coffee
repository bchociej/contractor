Promise       = require 'bluebird'
WorkerMarshal = require './worker-marshal'

module.exports = class WorkerPool
	dispatchWorkersIfPossible = (ds, ws) ->
		while ds.length > 0 and ws.length > 0
			ds.shift().resolve(ws.shift())

	constructor: (@size, @requirePath) ->
		@deferreds = []

		@workers = [1..@size].map =>
			new WorkerMarshal @requirePath, (readyWorker) =>
				@workers.push readyWorker
				dispatchWorkersIfPossible(@deferreds, @workers)

	getSize: -> @size

	getWorker: ->
		return new Promise (resolve, reject) =>
			@deferreds.push {resolve, reject}
			dispatchWorkersIfPossible(@deferreds, @workers)
