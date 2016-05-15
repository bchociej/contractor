Contractor = require '../lib/main'

Contractor.create().then (c) ->
	wrappedAdd = c.wrap (a, b) -> a + b
	wrappedAdd(1, 2).then (result) -> console.log result

	wrappedCb = c.wrap (a, b, cb) -> cb(null, a + b, a, b)
	wrappedCb(7, 2, c.wrapback(multiArgs: true))
	.then (result) -> console.log result
