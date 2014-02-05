_ = require('underscore')

webinos = require('webinos')
address = require('../util/address.coffee')

Bacon = require('baconjs')

Service = require('./service.coffee')

class PeerService extends Service
  @findServices: (channel, dtype, options = {interval: 5000}) ->
    new Bacon.EventStream (newSink) ->
      sink = (event) ->
        reply = newSink event
        unsub() if reply is Bacon.noMore or event.isEnd()
      unsubPoll = undefined
      unsub = ->
        sink = undefined
        unsubPoll?()
      # TODO: Autoconnect.
      if channel.connected()
        channel.onValue (event) ->
          if event.isMessage() and event.message().type is 'hello'
            sink? new Bacon.Next(PeerService.create(channel, event.message().from, dtype))
          else if event.isDisconnect()
            sink? new Bacon.End()
        if channel.service().address() is address.generalize(webinos.session.getServiceLocation())
          unsubPoll = Bacon.once(Date.now()).concat(Bacon.fromPoll(options.interval, -> Date.now())).onValue (now) ->
            channel.send({
              from: LocalPeerService.localPeer()
              type: 'hello'
            })
      else if channel.disconnected()
        sink? new Bacon.End()
      unsub
  @create: (channel, peer, dtype) ->
    if LocalPeerService.isLocalPeer(peer)
      new LocalPeerService(channel, peer, dtype)
    else
      new RemotePeerService(channel, peer, dtype)
  constructor: (channel, peer, dtype) ->
    messages = new Bacon.Bus()
    messages.plug channel
      .filter (event) ->
        return unless event.isMessage()
        to = event.message().to
        to?.address is peer.address and to?.id is peer.id
      .map('.message')
    super({
      serviceAddress: peer.address, id: peer.id,
      bindService: ({onBind}) -> onBind(this)
      unbindService: -> messages.end()
    })
    channel.filter('.isDisconnect').onValue => @unbindService()
    @channel = -> channel
    @messages = -> messages
    @dtype = -> dtype
    @send = (type, content) ->
      channel.send({
        from: LocalPeerService.localPeer()
        to: peer
        type, content
      })
  isLocal: -> no
  isRemote: -> no

class LocalPeerService extends PeerService
  @localPeer: ->
    address: webinos.session.getServiceLocation()
    id: webinos.session.getSessionId()
  @isLocalPeer: (peer) ->
    localPeer = @localPeer()
    peer.address is localPeer.address and peer.id is localPeer.id
  isLocal: -> yes

class RemotePeerService extends PeerService
  isRemote: -> yes

module.exports = PeerService
