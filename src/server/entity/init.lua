local registry = require(script.registry).registry
local methods = require(script.methods)

require(script.wires)
require(script.stockpile)
require(script.extractor)
require(script.scout)
require(script.factory)
require(script.generator)
require(script.laboratory)
require(script.turret)
require(script.infinite_source)
require(script.barrier)
require(script.obelisk)
require(script.proxy)
require(script.heart)
require(script.vault)
require(script.solution)
require(script.witness)
require(script.impression)
require(script.phony)
require(script.suggestion)
require(script.altar)

return {
	registry = registry,
	new_entity = methods.new_entity,
	autogenerate_wires = methods.autogenerate_wires,
	remove_entity = methods.remove_entity,
	-- entity_can_deconstruct = methods.entity_can_deconstruct,
}
