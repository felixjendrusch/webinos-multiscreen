
RemoteDisplayLib = require('./lib.coffee')

$(document).ready ->

	showRemoteDisplayList = (remoteDisplays) ->
		$('#remoteDisplayTable > tbody:last').empty()
		for display, i in remoteDisplays
			newLine = 
			"<tr>
				<td>" + ++i + "</td>
				<td>" + display.displayName + "</td>
				<td>" + display.id + "</td>
				<td>
					<button value='" + display.id + "' class='connectButton'>connect</button>
					<button value='" + display.id + "' class='disconnectButton'>disconnect</button>
					<button value='" + display.id + "' class='controlButton'>control</button>
				</td>"
			$('#remoteDisplayTable > tbody:last').append newLine
		refreshConnectedDisplays()

	refreshConnectedDisplays = ->
		$('#connectedDisplays').empty()
		$('#remoteDisplayTable > tbody > tr').css("background-color", "")
		for display in rd.getConnectedDisplays()
			$('#connectedDisplays').append "<option value=" + display.id + ">" + display.id + "</option>"
			for row in $('#remoteDisplayTable > tbody > tr')
				if $(row).children('td:eq(2)').text() is display.id
					$(row).css("background-color", "lightgreen")

	receiveMsg = (msg) ->
		textArea = $('#textArea')
		textArea.val textArea.val() + msg + "\n"
		textArea.scrollTop textArea.prop('scrollHeight')


	rd = new RemoteDisplayLib(showRemoteDisplayList)
	$('#showRemoteDisplays').on "click", ->
		rd.getRemoteDisplays showRemoteDisplayList

	$('#remoteDisplayTable').on "click", ".connectButton", ->
		newDisplay = rd.connectToRemoteDisplay $(this).attr("value"), refreshConnectedDisplays
		if newDisplay?
			newDisplay.addEventListener "message", receiveMsg

	$('#remoteDisplayTable').on "click", ".disconnectButton", ->
		rd.disconnectFromRemoteDisplay $(this).attr("value"), refreshConnectedDisplays

	$('#remoteDisplayTable').on "click", ".controlButton", ->
		rd.controlRemoteDisplay $(this).attr("value")


	$('#sendMsgButton').on "click", ->
		for display in rd.getConnectedDisplays()
			if display.id is $('#connectedDisplays option:selected').attr("value")
				if $('#msgType option:selected').attr("value") is "msg"
					display.postMessage $('#msg').val()
				else if $('#msgType option:selected').attr("value") is "url"
					display.openUrl $('#msg').val()

	$('#identifyButton').on "click", ->
		for display, i in rd.getAvailableDisplays()
			display.identify ++i

	$('#backToDefault').on "click", ->
		window.open("defaultRemoteDisplay.html","_self");
