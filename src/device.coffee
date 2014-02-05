_ = require('underscore')

Bacon = require('baconjs')

webinos = require('webinos')

DeviceStatusService = require('./service/devicestatus.coffee')
MessagingService = require('./service/messaging.coffee')
PeerService = require('./service/peer.coffee')

class DeviceManager extends Bacon.EventStream
  constructor: (interval = 15000, timeout = 30000) ->
    devices = {}
    compound = new Bacon.Bus()
    compound.onValue (event) ->
      device = event.device()
      if event.isAvailable()
        service = event.service()
        if service instanceof DeviceStatusService
          sink? new Bacon.Next(new Found(device))
        else
          if service instanceof MessagingService
            services.plug Bacon.fromPromise(service.createChannel(
                namespace: 'urn:webinos:multiscreen'
                properties:
                  mode: 'send-receive'
                  canDetach: yes
                  reclaimIfExists: yes
                null # requestCallback
              ).then(_.identity, -> Promise.reject(service)))
              .map(Bacon.once)
              .mapError((service) -> service.searchForChannels('urn:webinos:multiscreen'))
              .flatMap(_.identity)
              .flatMap((channel) -> Bacon.fromPromise(channel.connect()))
              .flatMap((channel) -> PeerService.findServices(channel, device.type()))
          if device.devicestatus()?
            sink? new Bacon.Next(new Changed(device))
      else if event.isUnavailable()
        if _.size(device.services()) is 0
          devices[device.address()].discovery.end()
          delete devices[device.address()]
        if event.service() instanceof DeviceStatusService
          sink? new Bacon.Next(new Lost(device))
        else if device.devicestatus()?
          sink? new Bacon.Next(new Changed(device))
      else if device.devicestatus()?
        sink? new Bacon.Next(event)
    services = new Bacon.Bus()
    services.plug Bacon.once(Date.now()).concat(Bacon.fromPoll(interval, -> Date.now())).flatMap (now) ->
      Bacon.mergeAll(
        DeviceStatusService.findServices(),
        MessagingService.findServices())
    services
      .flatMap (service) ->
        Bacon.fromPromise(service.bindService())
      .onValue (service) ->
        device = devices[service.address()]
        unless device?
          discovery = new Bacon.Bus()
          device = {ref: new Device(service.address(), discovery, timeout), discovery: discovery}
          devices[service.address()] = device
          compound.plug(device.ref)
        device.discovery.push(service)
    sink = undefined
    super (newSink) ->
      sink = (event) ->
        reply = newSink event
        unsub() if reply is Bacon.noMore or event.isEnd()
      unsub = ->
        sink = undefined
    @devices = ->
      _.chain(devices).filter(({ref}) -> ref.devicestatus()?).map(({ref}) -> [ref.address(), ref]).object().value()
    @toProperty = =>
      @scan @devices(), (devices, event) ->
        device = event.device()
        if event.isFound()
          devices = _.clone(devices)
          devices[device.address()] = device
        else if event.isLost()
          devices = _.omit(devices, device.address())
        devices

class Device extends Bacon.EventStream
  constructor: (address, discovery, timeout) ->
    type = undefined
    services = {}
    compound = new Bacon.Bus()
    compound.filter('.isUnbind').map('.service').onValue (service) =>
      delete services[service.id()]
      sink? new Bacon.Next(new Unavailable(this, service))
    discovery.onValue (service) =>
      if services[service.id()]?
        services[service.id()].seen = Date.now()
        service.unbindService()
      else
        services[service.id()] = {ref: service, seen: Date.now()}
        compound.plug(service)
        service.initialize?()
        sink? new Bacon.Next(new Available(this, service))
    discovery.onEnd ->
      unsubPoll()
      sink? new Bacon.End()
    unsubPoll = Bacon.fromPoll(timeout, -> Date.now()).onValue (now) ->
      for id, {ref, seen} of services
        ref.unbindService() if seen < (now - timeout)
    sink = undefined
    super (newSink) ->
      sink = (event) ->
        reply = newSink event
        unsub() if reply is Bacon.noMore or event.isEnd()
      unsub = ->
        sink = undefined
    @onValue (event) =>
      return unless event.isAvailable()
      service = event.service()
      if service instanceof DeviceStatusService
        service.getPropertyValue(
          component: '_DEFAULT'
          aspect: 'Device'
          property: 'type'
        ).then (value) =>
          type = value
          sink? new Bacon.Next(new Changed(this))
    @address = -> address
    @isLocal = -> address is webinos.session.getServiceLocation()
    @isRemote = => not @isLocal()
    @type = -> type
    @services = ->
      _.chain(services).map(({ref}) -> [ref.id(), ref]).object().value()
    @toProperty = =>
      @scan @services(), (services, event) ->
        service = event.service()
        if event.isAvailable()
          services = _.clone(services)
          services[service.id()] = service
        else if event.isUnavailable()
          _.omit(services, service.id())
        services
    @devicestatus = -> _.find(services, ({ref}) -> ref instanceof DeviceStatusService)?.ref
    @peers = -> _.chain(services).filter(({ref}) -> ref instanceof PeerService).pluck('ref').value()

class Event
  constructor: (device) ->
    @device = -> device
  isFound: -> no
  isChanged: -> no
  isLost: -> no
  isAvailable: -> no
  isUnavailable: -> no

class Found extends Event
  isFound: -> yes

class Changed extends Event
  isChanged: -> yes

class Lost extends Event
  isLost: -> yes

class WithService extends Event
  constructor: (device, service) ->
    super(device)
    @service = -> service

class Available extends WithService
  isAvailable: -> yes

class Unavailable extends WithService
  isUnavailable: -> yes

module.exports = DeviceManager
