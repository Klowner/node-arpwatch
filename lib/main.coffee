ArpWatch = require './arpwatch'

arpwatch = new ArpWatch

arpwatch.on 'add', (record) ->
	console.log "added", record.ip, record.mac

arpwatch.on 'remove', (record) ->
	console.log "removed", record.ip, record.mac

module.exports =
	ArpWatch: ArpWatch


