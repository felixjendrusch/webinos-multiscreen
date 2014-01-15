
class RemoteDisplayLib

	constructor: ->
		channel = new MessageChannel()
		@port = channel.port1
		@availableDisplays = []
		@connectedDisplays = []
		parent.postMessage("rdInit", "http://localhost:8080", [channel.port2])

		@port.onmessage = (evt) =>
			console.log("lib onmessage " + evt.data[0], evt.data[1])
			switch
				when evt.data[0] is "displayList"
					@availableDisplays = []
					for display in evt.data[1]
						@availableDisplays.push new RemoteDisplay(@, display.id, display.address, display.displayName)
					@grdCB? evt.data[1]

					window.clearTimeout(@refreshTimer)
					@refreshTimer = window.setTimeout( =>
						@port.postMessage ["getRemoteDisplays"]
					,10000)

				when evt.data[0] is "receiveMsg"
					for display in @connectedDisplays
						if display.id is evt.data[1]
							display.handleEvent [evt.data[2]]

 

	getRemoteDisplays: (@grdCB) =>
		@port.postMessage ["getRemoteDisplays"]

	connectToRemoteDisplay: (@ctrdCB, id) =>
		for display in @availableDisplays
			if display.id is id
				@connectedDisplays.push display
				@ctrdCB?()
				return display

	disconnectFromRemoteDisplay: (@dfrdCB, id) =>
		for display in @connectedDisplays
			if display.id is id
				@connectedDisplays.remove display
				@dfrdCB?()

	getAvailableDisplays:  =>
		@availableDisplays

	getConnectedDisplays: =>
		@connectedDisplays

	sendMsg: (id, msgType, msg) =>
		@port.postMessage ["sendMsg", id, msgType, msg]
		console.log "msg send lib"


class RemoteDisplay

	constructor: (@rdLib, @id, @address, @displayName) ->

	disconnect: (dfrdCB) ->
		@rdLib.disconnectFromRemoteDisplay dfrdCB, @id

	postMessage: (msg) ->
		@rdLib.sendMsg @id, "msg", msg

	openUrl: (url) ->
		@rdLib.sendMsg @id, "url", url

	addEventListener: (type, @handler) ->

	handleEvent: (evt) ->
		@handler?(evt)


module.exports = RemoteDisplayLib