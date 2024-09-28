--!nocheck

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local ui_types = require(script.Parent.types)

type HexGrid = types.HexGrid
type CubicCoordinate = types.CubicCoordinate
type SelectionMode = ui_types.SelectionMode
type QuestEffect = types.QuestEffect

local MainContext: React.ReactContext<{
	grid: HexGrid,
	selection_mode_stack: { SelectionMode },
	quest_effects: { QuestEffect },
}> =
	React.createContext(nil)

return {
	MainContext = MainContext,
}
