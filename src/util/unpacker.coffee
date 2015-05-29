LRUMap = require '../util/lru-map'

module.exports = class Unpacker
	constructor: (@cacheSize = 32)->
		@cache = new LRUMap {
			maxSize: @cacheSize * 1024 * 1024
			getSize: (item) -> item.length
		}

	unpack: (fnString, scopeInjections) ->
		unless typeof fnString is 'string'
			throw new TypeError 'fnString must be a string'

		if @cache.has fnString
			return @cache.get fnString

		fn = do (process = undefined, module = undefined, require = undefined) ->
			for k, v in scopeInjections
				this[k] = v

			eval "var reconstituted = #{packed.fnString}"
			return reconstituted

		unless typeof fn is 'function'
			throw new TypeError 'unpacked fnString is not a function'

		if @cache.fits fn
			@cache.set fnString, fn

		return fn
