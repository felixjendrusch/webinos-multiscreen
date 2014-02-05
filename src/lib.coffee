
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
					newAvailableDisplay = []
					for actualDisplay in evt.data[1]
						alreadyListed = null
						for display in @availableDisplays
							if actualDisplay.id is display.id
								alreadyListed = display
						if alreadyListed
							newAvailableDisplay.push alreadyListed
						else
							newAvailableDisplay.push new RemoteDisplay(@, actualDisplay.id, actualDisplay.address, actualDisplay.displayName)

					@availableDisplays = newAvailableDisplay
					@grdCB? @availableDisplays

					connectedTemp = @connectedDisplays.slice()
					for connectedDisplay in connectedTemp
						stillConnected = false
						for availableDisplay in @availableDisplays
							if connectedDisplay.id is availableDisplay.id
								stillConnected = true
						if !stillConnected
							@connectedDisplays.splice @connectedDisplays.indexOf(connectedDisplay), 1
							@ctrdCB?()


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

	connectToRemoteDisplay: (id, @ctrdCB) =>
		for display in @availableDisplays
			if display.id is id
				if @connectedDisplays.indexOf(display) is -1
					@connectedDisplays.push display
					@ctrdCB?()
					return display
				else return null

	disconnectFromRemoteDisplay: (id, @dfrdCB) =>
		for display in @connectedDisplays
			if display.id is id
				console.log id
				@connectedDisplays.remove display
				@dfrdCB?()

	getAvailableDisplays:  =>
		@availableDisplays

	getConnectedDisplays: =>
		@connectedDisplays

	sendMsg: (id, msgType, msg) =>
		@port.postMessage ["sendMsg", id, msgType, msg]


class RemoteDisplay

	constructor: (@rdLib, @id, @address, @displayName) ->

	disconnect: (dfrdCB) ->
		@rdLib.disconnectFromRemoteDisplay dfrdCB, @id

	postMessage: (msg) ->
		@rdLib.sendMsg @id, "msg", msg

	openUrl: (url) ->
		@rdLib.sendMsg @id, "url", url

	identify: (identNo)->
		@rdLib.sendMsg @id, "identify", identNo

	addEventListener: (type, @handler) ->

	handleEvent: (evt) ->
		@handler?(evt)


module.exports = RemoteDisplayLib
window.RemoteDisplayLib = RemoteDisplayLib