_ = require('underscore')

DeviceManager = require('./device.coffee')

$(document).ready ->
	remoteDisplays = []
	port =[]
	manager = new DeviceManager()
	manager
		.toProperty()
		.map (devices) ->
			_.chain(devices).map((device) -> device.peers()).flatten().value()
		.onValue (peers) ->
			remoteDisplays = peers
			for peer in peers
				if peer.isLocal()
					peer.messages().onValue (msg) ->+
						if msg.type is "remoteDisplay"
							switch
								when msg.content[0] is "url"
									$('#ifr').attr('src', msg.content[1])

								when msg.content[0] is "msg"
									port.postMessage ["receiveMsg", msg.from.id, msg.content[1]]


	normalizePeers = (peers) ->
		normalizedPeers = []
		for peer in peers
			normalizedPeers.push
				address: peer.address()
				displayName: peer.displayName()
				id: peer.id()
		normalizedPeers


	window.addEventListener 'message', (evt) =>
		if evt.origin is 'http://localhost:8080' and evt.data is "rdInit" and evt.ports?
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









