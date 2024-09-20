local registry = require(script.registry)
local util = require(script.Parent.util)
local types = require(script.Parent.types)
type EntityConfiguration = types.EntityConfiguration

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
require(script.scribe)

function create_configuration(): { [string]: EntityConfiguration }
	return util.deep_copy(registry.registry)
end

return { create_configuration = create_configuration, layer = registry.layer }
