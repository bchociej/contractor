Contractor = require '../'
Promise    = require 'bluebird'

c = new Contractor

combine = (first, last) ->
	Promise.resolve "The name's #{last}. #{first} #{last}."

names = [
	['James', 'Bond']
	['John', 'Smith']
	['George', 'Washington']
	['Ringo', 'Starr']
	['Hillary', 'Clinton']
	['Michael', 'Jackson']
	['Barack', 'Obama']
	['Warren', 'Buffett']
	['Ronald', 'McDonald']
	['Colin', 'Powell']
	['Peter', 'Parker']
	['Tim', 'Taylor']
]

Promise
	.all (c.doWork(combine, name) for name in names)

	.then (result) ->
		console.log JSON.stringify(result, null, '\t')

	.catch (error) ->
		console.log error

	.finally process.exit
