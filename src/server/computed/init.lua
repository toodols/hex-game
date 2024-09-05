-- Computes properties of HexGrid that are a reflection of
-- The grid's entities and cells

local compute_influences = require(script.compute_influences).compute_influences
local compute_presence = require(script.compute_presence).compute_presence
local compute_visibility = require(script.compute_visibility).compute_visibility
local compute_systems = require(script.compute_systems).compute_systems

return {
	compute_influences = compute_influences,
	compute_presence = compute_presence,
	compute_visibility = compute_visibility,
	compute_systems = compute_systems,
}
