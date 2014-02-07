_ = require('underscore')
address = require('./util/address.coffee');
DeviceManager = require('./device.coffee')

$(document).ready ->
	remoteDisplays = []
	port =[]
	firstTime = true
	activPeer = null
	$('#identify').css "font-size", $('#ifr').height()*0.9

	$('#cancelControl').on "click", (event) ->
		event.stopPropagation()
		$('#control').css "z-index", "-1"

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
										$('#ifr > iframe').attr('src', msg.content[1])

									when msg.content[0] is "msg"
										port.postMessage ["receiveMsg", msg.from.id, msg.content[1]]

									when msg.content[0] is "identify"
										$('#identify > p').text msg.content[1]
										$('#identify').css "z-index", "5"
										setTimeout ->
											$('#identify').css "z-index", "-1"
										, 1000
				else
					remoteDisplays.push peer


	control = (peer) ->
		$('#control').css "z-index", "5"
		if activPeer isnt null
			activPeer = peer
			return

		activPeer = peer

		if !Hammer.HAS_TOUCHEVENTS && !Hammer.HAS_POINTEREVENTS
			Hammer.plugins.fakeMultitouch()        
			Hammer.plugins.showTouches()
		

		hammertime = Hammer(document.getElementById('control'), {
			transform_always_block: true,
			transform_min_scale: 1,
			drag_block_horizontal: true,
			drag_block_vertical: true,
			drag_min_distance: 0
		});

		posX=0
		posY=0
		scale=last_scale=1
		rotation=last_rotation=1

		hammertime.on "drag transform", (event) ->
			touches = event.gesture.touches
			switch event.type
				when 'drag'
					posX = event.gesture.deltaX
					posY = event.gesture.deltaY

				when 'transform'
					rotation = event.gesture.rotation
					scale = event.gesture.scale
# 
			eventData = {
				posX: posX
				posY: posY
				rotarotation: rotation
				scale: scale
			}
			console.log eventData
			activPeer.send "remoteDisplay", ["msg", eventData]


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

					when evt.data[0] is "control"
						for peer in remoteDisplays
							if peer.id() is evt.data[1]
								control peer



