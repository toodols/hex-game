local ReplicatedStorage = game:GetService "ReplicatedStorage"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local formatting = require(ReplicatedStorage.Shared.formatting)
local researches_mod = require(ReplicatedStorage.Shared.researches)

local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Items = require(ReplicatedStorage.Client.ui.game.items).Items
local TextActionButton = require(ReplicatedStorage.Client.ui.game.action_button).TextActionButton

type ResearchItem = types.ResearchItem
type ResearchState = types.ResearchState

function Aside(props: { item: ResearchItem, state: ResearchState, on_add: () -> (), on_remove: () -> () })
	local world = React.useContext(MainContext).world
	local is_available = researches_mod.research_is_available(props.item, props.state)

	return React.createElement(
		"Frame",
		{
			Size = UDim2.new(0, 200, 0, 0),
			Position = UDim2.new(1, -10, 0.5, 0),
			ZIndex = 2,
			ClipsDescendants = true,
			[React.Tag] = "solid align-cr container-v list-v stroke",
		},
		{
			Container = React.createElement(
				"Frame",
				{
					[React.Tag] = "container-v pad-h-10 pad-b-10 list-v list-pad-5",
				},
				{
					Title = React.createElement("TextLabel", {
						Text = props.item.name,
						[React.Tag] = "text-c title",
						Size = UDim2.new(1, 0, 0, 30),
						LayoutOrder = 1,
					}),
					Description = React.createElement("TextLabel", {
						Text = formatting.format_text(world, props.item.description),
						[React.Tag] = "description",
						LayoutOrder = 2,
					}),
				},
				if not is_available
					then {
						UnavailableLabel = React.createElement("TextLabel", {
							Text = "Unavailable",
							TextColor3 = Color3.fromRGB(150, 50, 50),
							LayoutOrder = 4,
							[React.Tag] = "description",
						}),
					}
					else nil,
				if props.item.status ~= "complete"
					then {
						Items = React.createElement(Items, {
							items = props.item.cost,
							LayoutOrder = 3,
						}),
					}
					else {},
				if props.item.status == "complete" or props.item.status == "researching"
					then {
						CompletedLabel = React.createElement("TextLabel", {
							Text = if props.item.status == "complete" then "Complete" else "Researching",
							[React.Tag] = "description",
							LayoutOrder = 4,
						}),
					}
					else {}
			),
		},
		if props.item.status == "incomplete" and is_available
			then {
				AddButton = React.createElement(TextActionButton, {
					Size = UDim2.new(1, 0, 0, 20),
					Text = "Add Research",
					LayoutOrder = 3,
					color = Color3.fromRGB(200, 200, 200),
					on_click = function()
						props.on_add()
					end,
				}),
			}
			else {}
	)
end

return {
	Aside = Aside,
}
