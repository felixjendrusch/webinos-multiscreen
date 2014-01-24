
RemoteDisplayLib = require('./lib.coffee')

$(document).ready ->

	cd = []

	showRemoteDisplayList = (remoteDisplays) ->
		$('#remoteDisplayTable > tbody:last').empty()
		for display in remoteDisplays
			$('#remoteDisplayTable > tbody:last').append "<tr><td>" + display.displayName + "</td><td>" + display.address + "</td><td>" + display.id + "<td><button value='" + display.id + "' class='connectButton'>connect...</button></td>"
	
	connectedToDisplay = ->
		$('#connectedDisplays').empty()
		for display in rd.getConnectedDisplays()
			$('#connectedDisplays').append "<option value=" + display.id + ">" + display.id + "</option>"

	receiveMsg = (msg) ->
		textArea = $('#textArea')
		textArea.val textArea.val() + msg + "\n"


	rd = new RemoteDisplayLib()
	$('#showRemoteDisplays').on "click", ->
		rd.getRemoteDisplays showRemoteDisplayList

	$('#remoteDisplayTable').on "click", ".connectButton", ->
		newDisplay = rd.connectToRemoteDisplay connectedToDisplay, $(this).attr("value")
		if newDisplay?	
			newDisplay.addEventListener "message", receiveMsg
			cd.push newDisplay

	$('.disconnectButton').on "click", ->
		rd.disconnectFromRemoteDisplay connectedToDisplay, $('#connectedDisplays option:selected').attr("value")

	$('#sendMsgButton').on "click", ->
		for display in rd.getConnectedDisplays()
			if display.id is $('#connectedDisplays option:selected').attr("value")
				if $('#msgType option:selected').attr("value") is "msg"
					display.postMessage $('#msg').val()
				else if $('#msgType option:selected').attr("value") is "url"
					display.openUrl $('#msg').val()
