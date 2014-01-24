RemoteDisplayLib = require('./lib.coffee')


$(document).ready ->

	rd = new RemoteDisplayLib()

	setTimeout ->
		rd.getRemoteDisplays connectToAllDisplays
	, 5000

	connectToAllDisplays = (remoteDisplays) ->
		for availableDisplays in remoteDisplays
			alreadyConnected = false
			for connectedDisplay in rd.getConnectedDisplays()
				if availableDisplays.id is connectedDisplay.id
					alreadyConnected = true
			if !alreadyConnected
				newDisplay = rd.connectToRemoteDisplay null, availableDisplays.id
				newDisplay.addEventListener "message", receiveMsg

		$('#connectedDisplays').empty()
		$('#connectedDisplays').append "<option value=0>all</option>"
		for display in rd.getConnectedDisplays()
			$('#connectedDisplays').append "<option value=" + display.id + ">" + display.id + "</option>"

	receiveMsg = (msg) ->
		textArea = $('#textArea')
		textArea.val textArea.val() + msg + "\n"


	$('#sendMsgButton').on "click", ->
			msgTarget = $('#connectedDisplays option:selected').attr("value")
			for display in rd.getConnectedDisplays()
				if msgTarget is "0" or  msgTarget is display.id
					display.postMessage $('#msg').val()