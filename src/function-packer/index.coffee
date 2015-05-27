LRU = require 'lru-cache'
Promise = require 'bluebird'

cache = LRU {
	max: 32 * 1024 * 1024
	length: (s) -> s.length
}

module.exports =
	pack: (fn) ->
		unless typeof fn is 'function'
			throw new TypeError 'argument must be a function'

		return fn.toString()

	unpack: (fnString) ->
		unless typeof fnString is 'string'
			throw new TypeError 'argument must be a string'

		fn = cache.get fnString

		if fn?
			return fn

		fn = do (process = undefined, module = undefined)->
			eval "var reconstituted = #{fnString}"
			return reconstituted

		unless typeof fn is 'function'
			throw new Error 'unable to unpack string as a function'

		cache.set fnString, fn

		return fn
