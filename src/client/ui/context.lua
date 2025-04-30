--!nocheck

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local ui_types = require(script.Parent.types)

type World = types.World
type CubicCoordinate = types.CubicCoordinate
type SelectionMode = ui_types.SelectionMode
type QuestEffect = types.QuestEffect
type Submenu = ui_types.Submenu

export type MainContext = {
	world: World,
	selection_mode_stack: { SelectionMode },
	quest_effects: { QuestEffect },
	submenu: Submenu,
	set_submenu: (Submenu) -> nil,
}

local MainContext: React.ReactContext<MainContext> = React.createContext(nil)

return {
	MainContext = MainContext,
}
