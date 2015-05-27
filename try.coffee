WM = require './src/master/worker-marshal.coffee'

wm = new WM()

work = -> Promise.resolve('hi mom')


recvd = 0

printer = ->
	if ++recvd % 10000 is 0
		console.log recvd

start = new Date()

ps = [1..100000].map ->
	p = wm.send work
	p.then printer
	return p


Promise.all(ps).then ->
	end = new Date()

	console.log "#{ps.length} ops"
	console.log "#{end - start} ms"
	console.log "#{1000 * ps.length / (end - start)} ops/s"
	process.exit()
