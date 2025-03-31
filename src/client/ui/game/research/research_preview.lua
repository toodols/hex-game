local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local team = require(ReplicatedStorage.Shared.team)

local themes = require(ReplicatedStorage.Client.ui.themes)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Icon = require(script.Parent.icon).Icon
local Corner = util_components.Corner

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
		BackgroundTransparency = 0.9,
		Size = UDim2.new(0, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder,
		[React.Event.MouseButton1Click] = props.click,
		Text = "",
		AutoButtonColor = false,
		[React.Event.MouseEnter] = function(current)
			TweenService:Create(current, TweenInfo.new(0.5), {
				BackgroundColor3 = Color3.new(0.0588235, 0.898039, 0),
			}):Play()
		end,
		[React.Event.MouseLeave] = function(current)
			TweenService:Create(current, TweenInfo.new(0.5), {
				BackgroundColor3 = Color3.fromRGB(163, 162, 165),
			}):Play()
		end,
	}, {
		Padding = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
			PaddingBottom = UDim.new(0, 5),
		}),
		VerticalLayout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		-- SizeConstraint = React.createElement("UISizeConstraint", {
		-- 	MinSize = Vector2.new(80, 0),
		-- }),
		Stroke = if is_owner
			then React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = 1,
				Transparency = 0.9,
			})
			else nil,
		Corner = React.createElement(Corner),
		ResearchLabel = React.createElement(
			"TextLabel",
			themes.theme_description {
				Text = "Research",
				Size = UDim2.new(1, 0, 0, 20),
				TextColor3 = Color3.new(0.0588235, 0.898039, 0),
			}
		),
		Container = React.createElement(
			"Frame",
			{
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
			},
			{
				HorizontalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 5),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			},
			if #entity.researches.queue == 0
				then {
					TextLabel = React.createElement(
						"TextLabel",
						themes.theme_description {
							LayoutOrder = 2,
							Text = "<i>No researches in queue</i>",
							Size = UDim2.new(0, 0, 0, 20),
						}
					),
				}
				else util.table_map(entity.researches.queue, function(research_id, idx)
					local state = entity.researches.states[research_id]
					return React.createElement("Frame", {
						LayoutOrder = idx + 2,
						Size = UDim2.new(0, 30, 0, 30),
						BackgroundTransparency = 1,
					}, {
						Icon = React.createElement(Icon, {
							Size = UDim2.new(0, 30, 0, 30),
							icon = state.icon,
						}),
						Corner = React.createElement(Corner),
						Stroke = React.createElement("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(255, 255, 255),
							LineJoinMode = Enum.LineJoinMode.Round,
							Thickness = 1,
							Transparency = 0.9,
						}),
						Time = if state.cost_is_paid
							then React.createElement(
								"TextLabel",
								themes.theme_description {
									Text = `{state.time - state.progress}`,
									Size = UDim2.new(0, 0, 0, 20),
									AnchorPoint = Vector2.new(1, 1),
									Position = UDim2.new(1, 0, 1, 0),
								}
							)
							else nil,
					})
				end)
		),
	})
end

return {
	ResearchPreview = ResearchPreview,
}
