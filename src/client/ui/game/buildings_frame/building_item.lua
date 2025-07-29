local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)

local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)
local types = require(ReplicatedStorage.Shared.types)
local formatting = require(ReplicatedStorage.Shared.formatting)
local team_mod = require(ReplicatedStorage.Shared.team)
local construction_condition_mod = require(ReplicatedStorage.Shared.construction_condition)
local validate_condition = construction_condition_mod.validate_condition
local cell_blocked = construction_condition_mod.cell_blocked

local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local client_entity_mod = require(ReplicatedStorage.Client.entity)
local themes = require(ReplicatedStorage.Client.ui.themes)
local Items = require(ReplicatedStorage.Client.ui.game.items).Items
local util_components = require(ReplicatedStorage.Client.ui.util_components)

local Corner = util_components.Corner
local Separator = util_components.Separator

type World = types.World
type CubicCoordinate = types.CubicCoordinate
type ResearchId = types.ResearchId

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

local BuildingItem = React.forwardRef(function(
	props: {
		do_animation: boolean,
		type: string,
		cell: CubicCoordinate,
		researches: { [ResearchId]: boolean },
		mouse_enter: () -> (),
		mouse_leave: () -> (),
		locked: boolean?,
		height: number,
	},
	ref
)
	local height = props.height
	local world: World = React.useContext(MainContext).world
	local player_team = team_mod.team_of(world, Players.LocalPlayer)
	local entity_config = world.entity_configurations[props.type]
	local item_ref = React.useRef(nil :: any)
	local viewport_ref = React.useRef(nil :: any)

	React.useEffect(function()
		local model = client_entity_mod.create_model_from_type(world, props.type)
		model.Parent = viewport_ref.current
		model:PivotTo(CFrame.new(0, -2, -4))
	end, { props.type })

	local coordinates = {}
	for _, offset in entity_config.offsets do
		table.insert(coordinates, coords.coords_add(props.cell, offset))
	end

	local can_build = true
	local construction_condition_status
	if world.global_configuration.construction_condition_enabled then
		local success, status =
			validate_condition(world, coordinates, player_team.id, entity_config.construction_condition, true)
		if not success then
			can_build = false
		end
		construction_condition_status = status
	end
	if cell_blocked(world, props.cell, player_team.id, props.type) then
		can_build = false
	end

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		ref = ref,
		Size = UDim2.new(0, 160, 0, if props.do_animation then 0 else height),
	}, {
		Inner = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Position = if props.do_animation then UDim2.new(0, 0, 0, -30) else UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 0, height),
			ref = item_ref,
		}, {
			LockedFrame = if props.locked
				then React.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 0.2,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				}, {
					UIPadding = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0, 5),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 5),
					}),
					LockedTitle = React.createElement(
						"TextLabel",
						themes.theme_title {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.new(0.5, 0, 0.5, -30),
							Size = UDim2.new(1, 0, 0, 30),
							Text = "Locked",
							TextColor3 = Color3.fromRGB(255, 255, 255),
							TextSize = 25,
							TextXAlignment = Enum.TextXAlignment.Center,
						}
					),
					RequiredLabel = if #entity_config.required_unlockable > 0
						then React.createElement(
							"TextLabel",
							themes.theme_description {
								AnchorPoint = Vector2.new(0.5, 0.5),
								AutomaticSize = Enum.AutomaticSize.Y,
								BackgroundTransparency = 1,
								LayoutOrder = 4,
								Position = UDim2.new(0.5, 0, 0.5, 10),
								Size = UDim2.new(0, 150, 0, 0),
								Text = "You haven't unlocked this building yet.",
								TextSize = 13,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Center,
							}
						)
						else nil,
				})
				else nil,
			Content = React.createElement(
				"TextButton",
				themes.theme_solid {
					Size = UDim2.new(1, 0, 1, 0),
					Text = "",
					[React.Event.MouseEnter] = function()
						if props.locked then
							return
						end
						props.mouse_enter()
						if props.do_animation then
							TweenService:Create(item_ref.current, TweenInfo.new(0.3), {
								Position = UDim2.new(0, 0, 0, -height),
								BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							}):Play()
						end
					end,
					[React.Event.MouseLeave] = function()
						if props.locked then
							return
						end
						props.mouse_leave()
						if props.do_animation then
							TweenService:Create(item_ref.current, TweenInfo.new(0.3), {
								Position = UDim2.new(0, 0, 0, -30),
								BackgroundColor3 = Color3.fromRGB(13, 13, 13),
							}):Play()
						end
					end,
					[React.Event.MouseButton1Click] = function()
						if props.locked then
							return
						end
						client_interaction_remote:FireServer {
							{
								type = "construct",
								entity_type = props.type,
								coordinate = props.cell,
							},
						}
					end,
				},
				{
					UIPadding = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0, 5),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 5),
					}),
					ViewportFrame = React.createElement("ViewportFrame", {
						Size = UDim2.new(0, 200, 0, 150),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						ImageTransparency = 0.6,
						ref = viewport_ref,
					}),
					Corner = React.createElement(Corner, {}),

					Top = React.createElement("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
					}, {

						ItemTitle = React.createElement(
							"TextLabel",
							themes.theme_title {
								BackgroundTransparency = 1,
								LayoutOrder = 1,
								Size = UDim2.new(1, 0, 0, 25),
								Text = entity_config.name,
								TextSize = 18,
								TextColor3 = if can_build
									then Color3.fromRGB(255, 255, 255)
									else Color3.fromRGB(90, 90, 90),
								TextXAlignment = Enum.TextXAlignment.Left,
							}
						),

						Separator = React.createElement(Separator, {
							LayoutOrder = 2,
						}),
						Description = React.createElement(
							"TextLabel",
							themes.theme_description {
								AutomaticSize = Enum.AutomaticSize.Y,
								BackgroundTransparency = 1,
								LayoutOrder = 3,
								Size = UDim2.new(1, 0, 0, 0),
								Text = formatting.format_text(world, entity_config.short_description),
								TextWrapped = true,
								TextSize = 12,
								TextTruncate = Enum.TextTruncate.AtEnd,
							},
							{
								SizeConstraint = React.createElement("UISizeConstraint", {
									MaxSize = Vector2.new(math.huge, 100),
								}),
							}
						),
						Items = React.createElement(Items, {
							items = entity_config.cost,
							LayoutOrder = 5,
						}),
						-- CanBuild = React.createElement(
						-- 	"TextLabel",
						-- 	themes.theme_description {
						-- 		LayoutOrder = 6,
						-- 		TextSize = 14,
						-- 		Size = UDim2.new(1, 0, 0, 25),
						-- 		Text = "Conditions",
						-- 		TextColor3 = if can_build
						-- 			then Color3.fromRGB(123, 165, 123)
						-- 			else Color3.fromRGB(138, 90, 90),
						-- 	}
						-- ),
						MustBeBuiltOn = if construction_condition_status
								and construction_condition_status.built_on
							then React.createElement(
								"TextLabel",
								themes.theme_description {
									TextSize = 12,
									AutomaticSize = Enum.AutomaticSize.Y,
									LayoutOrder = 7,
									Size = UDim2.new(1, 0, 0, 0),
									Text = formatting.format_text(
										world,
										`Built On: {table.concat(
											util.table_map(construction_condition_status.built_on, function(status)
												local text
												if status.entity_type:sub(1, 1) == "@" then
													text = status.entity_type
												else
													text = "{entity." .. status.entity_type .. "}"
												end
												return util.font(text, {
													color = if status.ok
														then Color3.fromRGB(123, 165, 123)
														else Color3.fromRGB(138, 90, 90),
												})
											end),
											" / "
										)}`
									),
								}
							)
							else nil,
						MustBeNearby = if construction_condition_status and construction_condition_status.nearby
							then React.createElement(
								"TextLabel",
								themes.theme_description {
									LayoutOrder = 8,
									Size = UDim2.new(1, 0, 0, 0),
									TextSize = 12,
									AutomaticSize = Enum.AutomaticSize.Y,

									Text = formatting.format_text(
										world,
										`Nearby: {table.concat(
											util.table_map(construction_condition_status.nearby, function(status)
												local text
												if status.entity_type:sub(1, 1) == "@" then
													text = status.entity_type
												else
													text = "{entity." .. status.entity_type .. "}"
												end
												return util.font(text, {
													color = if status.ok
														then Color3.fromRGB(123, 165, 123)
														else Color3.fromRGB(138, 90, 90),
												})
											end),
											" / "
										)}`
									),
								}
							)
							else nil,
						MustNotBeNearby = if construction_condition_status and construction_condition_status.not_nearby
							then React.createElement(
								"TextLabel",
								themes.theme_description {
									LayoutOrder = 9,
									Size = UDim2.new(1, 0, 0, 0),
									TextSize = 12,
									AutomaticSize = Enum.AutomaticSize.Y,
									Text = formatting.format_text(
										world,
										`Not Nearby: {table.concat(
											util.table_map(construction_condition_status.not_nearby, function(status)
												local text
												if status.entity_type:sub(1, 1) == "@" then
													text = status.entity_type
												else
													text = "{entity." .. status.entity_type .. "}"
												end
												return util.font(text, {
													color = if status.ok
														then Color3.fromRGB(123, 165, 123)
														else Color3.fromRGB(138, 90, 90),
												})
											end),
											" / "
										)}`
									),
								}
							)
							else nil,

						-- RequiredResearch = if #entity_config.required_research > 0
						-- 	then React.createElement(
						-- 		"TextLabel",
						-- 		themes.theme_description {
						-- 			BackgroundTransparency = 1,
						-- 			LayoutOrder = 4,
						-- 			AutomaticSize = Enum.AutomaticSize.Y,
						-- 			Size = UDim2.new(1, 0, 0, 0),
						-- 			Text = "Requires Research: " .. table.concat(
						-- 				util.table_map(entity_config.required_research, function(research_id)
						-- 					local research = researches_mod.researches[research_id]
						-- 					if props.researches[research_id] then
						-- 						return `<font color="rgb(50, 155, 50)">{research.name}</font>`
						-- 					else
						-- 						return `<font color="rgb(155, 50, 50)">{research.name}</font>`
						-- 					end
						-- 				end),
						-- 				", "
						-- 			),
						-- 			TextSize = 13,
						-- 		}
						-- 	)
						-- 	else nil,

						VerticalLayout = React.createElement("UIListLayout", {
							Padding = UDim.new(0, 4),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					}),
				}
			),
		}),
	})
end)

return {
	BuildingItem = BuildingItem,
}
