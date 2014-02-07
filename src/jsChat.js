
$(document).ready(function() {
	rd = new RemoteDisplayLib();
	setTimeout(function() {
		rd.getRemoteDisplays(connectToAllDisplays);
	}, 5000);

	connectToAllDisplays = function(remoteDisplays) {
	 	var availableDisplays = remoteDisplays;
	 	var connectedDisplays = rd.getConnectedDisplays();

	 	for (var i=0; i<availableDisplays.length; i++){
	 		var alreadyConnected = false;
	 		for(var j=0; j<connectedDisplays.length; j++){
	 			if(availableDisplays[i].id === connectedDisplays[j].id)
	 				alreadyConnected = true;
	 				break;
	 		}
	 		if(!alreadyConnected){
	 			var newDisplay = rd.connectToRemoteDisplay(availableDisplays[i].id);
	 			newDisplay.addEventListener("message", receiveMsg);
	 		}
	 	}

	 	$('#connectedDisplays').empty();
	 	$('#connectedDisplays').append("<option value=0>all</option>");
	 	connectedDisplays = rd.getConnectedDisplays();
	 	for(var h=0; h<connectedDisplays; h++){
	 		var display = connectedDisplays[h];
	 		$('#connectedDisplays').append("<option value=" + display.id + ">" + display.id + "</option>");
	 	}
	};

	receiveMsg = function(msg) {
	 	var textArea = $('#textArea');
		textArea.val(textArea.val() + msg + "\n");
	};

	$('#sendMsgButton').on("click", function(){
		msgTarget = $('#connectedDisplays option:selected').attr("value");
		var connectedDisplays = rd.getConnectedDisplays();
		for(var i=0; i<connectedDisplays.length; i++) {
			if(msgTarget === "0" || msgTarget === connectedDisplays[i].id) {
				connectedDisplays[i].postMessage($('#msg').val());
			}
		}
	});
});