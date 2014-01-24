fs = require 'fs'
timers = require 'timers'
events = require 'events'

_ = require 'lodash'
Lazy = require 'lazy'

class ArpWatch extends events.EventEmitter
	constructor: (filepath = "/proc/net/arp") ->
		if process.platform.indexOf('linux') == -1
			throw new Error "ArpWatch only supported on Linux platforms"

		@filepath = filepath
		@registry = {}

		do @extractMacAddresses
		do @addPeriodical

	addWatch: () ->
		@watcher = fs.watch @filepath, (event, filename) =>
			@onChange event, filename

	addPeriodical: () ->
		@periodTimeout = new timers.setInterval ((event) => @onChange event), 1000, 'change'

	onChange: (event, filename) ->
		if event is "change"
			do @extractMacAddresses

	handleMacAddresses: (result) ->
		for record in result
			if record.flags is '0x2'
				if @registry[record.mac] == undefined
					@emit "add", record
				@registry[record.mac] = record

			else if record.flags is '0x0' and @registry[record.mac] != undefined
				delete @registry[record.mac]
				@emit "remove", record

	extractMacAddresses: ->
		res = new Lazy fs.createReadStream @filepath
		mac_re = new RegExp /([0-9A-Fa-f]{2}[:-]?){6}/
		ip_re = new RegExp /([0-9]{1,3}\.){3}[0-9]{1,3}/
		parts = ['ip', 'hw', 'flags', 'mac', 'mask', 'dev']

		res
			.lines
			.map(String)
			.filter (line) ->
				(mac_re.test line) and (ip_re.test line)
			.map (line) ->
				_.extend (_.zipObject parts, line.match(/([^\ ]+)/g)),
					seen_at: new Date
			.filter (record) ->
				record.mac != '00:00:00:00:00:00'
			.join (result) =>
				@handleMacAddresses result

module.exports = ArpWatch
