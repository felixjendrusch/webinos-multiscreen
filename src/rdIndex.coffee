_ = require('underscore')
address = require('./util/address.coffee');
DeviceManager = require('./device.coffee')

$(document).ready ->
	remoteDisplays = []
	port =[]
	firstTime = true
	$('#identify').css "font-size", $('#ifr').height()*0.9

	manager = new DeviceManager()
	manager
		.toProperty()
		.map (devices) ->
			_.chain(devices).map((device) -> device.peers()).flatten().value()
		.onValue (peers) ->
			remoteDisplays = []
			for peer in peers
				if peer.isLocal()
					if firstTime
						firstTime = false
						peer.messages().onValue (msg) ->
							if msg.type is "remoteDisplay"
								switch
									when msg.content[0] is "url"
										$('#ifr').attr('src', msg.content[1])

									when msg.content[0] is "msg"
										port.postMessage ["receiveMsg", msg.from.id, msg.content[1]]

									when msg.content[0] is "identify"
										$('#identify').text msg.content[1]
										$('#ifr').css "display", "none"
										setTimeout ->
											$('#identify').text ""
											$('#ifr').css "display", "inherit"
										, 1000
				else
					remoteDisplays.push peer


	normalizePeers = (peers) ->
		normalizedPeers = []
		for peer in peers
			console.log(peer);
			normalizedPeers.push
				address: peer.address()
				displayName: address.friendlyName(peer.address());
				id: peer.id()
				type: peer.dtype()
		normalizedPeers


	window.addEventListener 'message', (evt) =>
		# evt.origin is 'http://localhost:8080' and
		if evt.data is "rdInit" and evt.ports?
			port = evt.ports[0]
			port.onmessage = (evt) =>
				console.log "app onmessage " + evt.data[0]
				switch
					when evt.data[0] is "getRemoteDisplays"
						port.postMessage ["displayList", normalizePeers(remoteDisplays)]

					when evt.data[0] is "sendMsg"
						for peer in remoteDisplays
							if peer.id() is evt.data[1]
								peer.send "remoteDisplay", [evt.data[2], evt.data[3]]

