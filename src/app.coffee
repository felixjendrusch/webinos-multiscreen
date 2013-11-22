_ = require('underscore')

DeviceManager = require('./device.coffee')

$(document).ready ->
  manager = new DeviceManager()
  manager
    .toProperty()
    .map (devices) ->
      _.chain(devices).map((device) -> device.peers()).flatten().value()
    .onValue (peers) ->
      console.log('peers', peers)
