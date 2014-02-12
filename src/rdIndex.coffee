_ = require('underscore')
address = require('./util/address.coffee');
DeviceManager = require('./device.coffee')

$(document).ready ->
	curtime = Date.now()

	lastEventData  = {
				posX: 0
				posY: 0
				rotation: 0
				scale: 1

			}
	posX=posY=rotation=0
	scale=1
	remoteDisplays = []
	port = undefined
	firstTime = true
	activPeer = null

	$('#identify').css "font-size", $('#ifr').height()*0.8
	$('#cancelControl').on "click", (event) ->
		event.stopPropagation()
		$('#control').css "z-index", "-1"

	$('#resetControl').on "click", (event) ->
		event.stopPropagation()
		lastEventData = {
				posX: 0
				posY: 0
				rotation: 0
				scale: 1
			}
		posX=posY=rotation=0
		scale=1
		activPeer.send "remoteDisplay", ["msg", lastEventData]	

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
										if msg.content[1].substring(0,7) is "http://" or msg.content[1].substring(0,8) is "https://"
											$('#ifr > iframe').attr('src', msg.content[1])
										else
											$('#ifr > iframe').attr('src', "http://" + msg.content[1])

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
			port?.postMessage ["displayList", normalizePeers(remoteDisplays)]


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
		
		hammertime.on "touch drag transform", (event) ->
			touches = event.gesture.touches
			switch event.type
				when 'touch'
					lastEventData.posX = posX
					lastEventData.posY = posY
					lastEventData.rotation = rotation
					lastEventData.scale = scale

				when 'drag'
					posX = event.gesture.deltaX + lastEventData.posX
					posY = event.gesture.deltaY + lastEventData.posY

				when 'transform'
					rotation = event.gesture.rotation + lastEventData.rotation
					scale = Math.max(1, Math.min(lastEventData.scale* event.gesture.scale, 10))

			eventData = {
				posX: posX
				posY: posY
				rotation: rotation
				scale: scale
			}

			if(curtime<Date.now()-100)
				curtime = Date.now()
				activPeer.send "remoteDisplay", ["msg", eventData]


	normalizePeers = (peers) ->
		normalizedPeers = []
		for peer in peers
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



