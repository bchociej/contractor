WM = require './src/master/worker-marshal.coffee'

wm = new WM()

work = (x) ->
	new Promise (resolve, reject) ->
		setTimeout ->
			resolve "Resolve #{x}"
			reject = -> undefined
		, Math.random() * 100

		setTimeout ->
			reject "Reject #{x}"
			resolve = -> undefined
		, Math.random() * 100

ps = [1..1000].map (i) ->
	wm.send(work, i)
	.then (result) ->
		console.log result
	.catch (error) ->
		console.log error
