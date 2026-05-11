local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local team = require(ReplicatedStorage.Shared.team)

local hooks = require(ReplicatedStorage.Client.ui.hooks)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Icon = require(script.Parent.icon).Icon

type EntityId = types.EntityId
type TeamData = types.TeamData

function ResearchPreview(props: {
	LayoutOrder: number?,
	entity_id: EntityId,
	click: () -> (),
})
	local world = React.useContext(MainContext).world
	local entity = hooks.use_synced_entity(props.entity_id)
	local is_owner = entity.owner == (team.team_of(world, Players.LocalPlayer) :: TeamData).id

	return React.createElement("TextButton", {
		Size = UDim2.new(0, 0, 0, 100),
		AutomaticSize = Enum.AutomaticSize.X,
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = Color3.fromRGB(100, 100, 100),

		[React.Event.MouseButton1Click] = props.click,
		[React.Tag] = `research-preview background pad-h-5 pad-b-5 list-v {if is_owner then "editable" else ""}`,
		Text = "",
		AutoButtonColor = false,
		[React.Event.MouseEnter] = function(current)
			TweenService:Create(current, TweenInfo.new(0.5), {
				BackgroundColor3 = Color3.new(0.0588235, 0.898039, 0),
			}):Play()
		end,
		[React.Event.MouseLeave] = function(current)
			TweenService:Create(current, TweenInfo.new(0.5), {
				BackgroundColor3 = Color3.fromRGB(100, 100, 100),
			}):Play()
		end,
	}, {
		-- SizeConstraint = React.createElement("UISizeConstraint", {
		-- 	MinSize = Vector2.new(80, 0),
		-- }),
		ResearchLabel = React.createElement("TextLabel", {
			Text = "Research",
			Size = UDim2.new(1, 0, 0, 20),
			TextColor3 = Color3.new(0.0588235, 0.898039, 0),
			[React.Tag] = "subtitle",
		}),
		Container = React.createElement(
			"Frame",
			{
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				[React.Tag] = "list-h list-pad-5 list-cc",
			},
			if #entity.researches.queue == 0
				then {
					TextLabel = React.createElement("TextLabel", {
						LayoutOrder = 2,
						Text = "<i>No researches in queue</i>",
						[React.Tag] = "description",
					}),
				}
				else util.table_map(entity.researches.queue, function(research_id, idx)
					local state = entity.researches.states[research_id]
					return React.createElement("Frame", {
						LayoutOrder = idx + 2,
						Size = UDim2.new(0, 30, 0, 30),
						BackgroundTransparency = 1,
						[React.Tag] = "stroke",
					}, {
						Icon = React.createElement(Icon, {
							Size = UDim2.new(0, 30, 0, 30),
							icon = state.icon,
						}),
						Time = if state.cost_is_paid
							then React.createElement("TextLabel", {
								Text = `{state.time - state.progress}`,
								[React.Tag] = "description align-br",
							})
							else nil,
					})
				end)
		),
	})
end

return {
	ResearchPreview = ResearchPreview,
}
