Promise = require 'bluebird'
async = require 'async'

# todo async priority queue
module.exports = class Scheduler
	constructor: (@nodes) ->
		@idle = @nodes.slice()
		@irr = 0
		@normal = []
		@nrr = 0
		@saturated = []

		q = []
		i = 0
		@pq =
			add: (pri, task) ->
				Promise.fromCallback (cb) ->
					q.push {pri, sn: i++, task, cb}
					q = q.sort (a, b) -> if a.pri is b.pri then (a.sn - b.sn) else (a.pri - b.pri)

			hasNext: -> q.length > 0

			next: -> q.shift()

		@nodes.forEach (node, i) ->
			return unless typeof node?.on is 'function'

			node.on 'saturated', => @saturated node

			node.on 'idle', =>
				if @pq.hasNext()
					next = @pq.next()
					node(next.task).asCallback(next.cb)
				else
					@idle node

			node.on 'taskFinished', =>
				if @pq.hasNext()
					next = @pq.next()
					node(next.task).asCallback(next.cb)
				else
					@normal node

	schedule: (priority, task) ->
		node = null

		if @idle.length > 0
			node = @idle[@irr]
			@normal node
			@irr = (@irr + 1) % @idle.length
			task node

		else if @normal.length > 0
			node = @normal[@nrr]
			@nrr = (@nrr + 1) % @normal.length
			task node

		else
			@pq.add priority, task

	idle: (node) ->
		@idle.push node
		@normal = @normal.filter (n) -> n isnt node
		@saturated = @saturated.filter (n) -> n isnt node

	saturated: (node) ->
		@saturated.push node
		@idle = @idle.filter (n) -> n isnt node
		@normal = @normal.filter (n) -> n isnt node

	normal: (node) ->
		@normal.push node
		@idle = @idle.filter (n) -> n isnt node
		@saturated = @saturated.filter (s) -> s isnt node
