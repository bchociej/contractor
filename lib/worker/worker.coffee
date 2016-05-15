execute = require './execute'

process.send type: 'worker:startup'

process.on 'message', (msg) ->
	switch msg.type
		when 'work'
			execute(msg.workFn, msg.args, msg.wrapback)
			.then (value) ->
				process.send {
					type: 'work:resolve'
					id: msg.id
					value
				}

			.catch (reason) ->
				process.send {
					type: 'work:reject'
					id: msg.id
					reason
				}
