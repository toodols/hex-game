-- Computes properties of World that are a reflection of
-- The world's entities and cells

local compute_influences = require(script.compute_influences).compute_influences
local compute_presence = require(script.compute_presence).compute_presence

return {
	compute_influences = compute_influences,
	compute_presence = compute_presence,
}
