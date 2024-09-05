local ContextActionService = game:GetService "ContextActionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local UserInputService = game:GetService "UserInputService"

local asset_server = require(ReplicatedStorage.Shared.asset_server)
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)

local themes = require(script.Parent.themes)
local MainContext = require(script.Parent.context).MainContext
local ActionButton = require(script.Parent.action_button).ActionButton
local Cost = require(script.Parent.cost).Cost
local Corner = require(script.Parent.corner).Corner
local hooks = require(script.Parent.hooks)
local decision_remote = ReplicatedStorage:FindFirstChild "DecisionRemote" :: RemoteEvent
local formatting = require(ReplicatedStorage.Shared.formatting)

type CubicCoordinate = types.CubicCoordinate
type Entity = types.Entity
type ResearchState = types.ResearchState
type HexGrid = types.HexGrid
type EntityId = types.EntityId
type Icon = types.Icon

function Icon(props: {
	ZIndex: number?,
	LayoutOrder: number?,
	Size: UDim2?,
	icon: Icon,
})
	local ref = React.useRef(nil :: any)
	local icon = props.icon
	local ZIndex = props.ZIndex
	local Size = props.Size or UDim2.new(1, 0, 1, 0)
	React.useEffect(function()
		if icon and icon.type == "model" then
			ref.current:ClearAllChildren()
			local template = asset_server.load(icon.model)
			local model = template:Clone()
			model.Parent = ref.current
			model:PivotTo(CFrame.new(0, -1, -4))
		end
	end, { icon })

	if not icon then
		return React.createElement(React.Fragment)
	end

	if icon.type == "model" then
		return React.createElement("ViewportFrame", {
			Size = Size,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			ref = ref,
			ZIndex = ZIndex,
			LayoutOrder = props.LayoutOrder,
		})
	elseif icon.type == "image" then
		return React.createElement("ImageLabel", {
			Size = Size,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Image = icon.image,
			ZIndex = ZIndex,
			LayoutOrder = props.LayoutOrder,
		})
	elseif icon.type == "none" then
		return React.createElement(React.Fragment)
	end
end

function Aside(props: { state: ResearchState, on_add: () -> (), on_remove: () -> () })
	local icon = props.state.icon
	return React.createElement(
		"Frame",
		themes.theme_solid {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.new(0, 200, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 2,
			ClipsDescendants = true,
		},
		{
			Corner = React.createElement(Corner),
			VerticalLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Container = React.createElement(
				"Frame",
				{
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
				},
				{
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingBottom = UDim.new(0, 10),
					}),
					VerticalLayout = React.createElement("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4),
					}),
					Title = React.createElement(
						"TextLabel",
						themes.theme_title {
							Text = props.state.name,
							TextXAlignment = Enum.TextXAlignment.Center,
							Size = UDim2.new(1, 0, 0, 30),
							LayoutOrder = 1,
						}
					),
					Description = React.createElement(
						"TextLabel",
						themes.theme_description {
							Text = formatting.format_text(props.state.description),
							Size = UDim2.new(1, 0, 0, 40),
							LayoutOrder = 2,
						}
					),
				},
				if props.state.status ~= "complete"
					then {
						Cost = React.createElement(Cost, {
							cost = props.state.cost,
							LayoutOrder = 3,
						}),
					}
					else {},
				if props.state.status == "complete" or props.state.status == "researching"
					then {
						CompletedLabel = React.createElement(
							"TextLabel",
							themes.theme_description {
								Text = if props.state.status == "complete" then "Complete" else "Researching",
								Size = UDim2.new(1, 0, 0, 40),
								LayoutOrder = 4,
							}
						),
					}
					else {}
			),
		},
		if props.state.status == "incomplete"
			then {
				AddButton = React.createElement(ActionButton, {
					Size = UDim2.new(1, 0, 0, 40),
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

local TRANSFORM_SIZE = 5000
function Node(props: { state: ResearchState, on_click: () -> () })
	local icon = props.state.icon
	local scale = 80
	local ratio = scale / 52 / TRANSFORM_SIZE
	-- local offset = { 1531 * ratio, 1598 * ratio }
	local offset = { 1531 * ratio, 1598 * ratio }
	local vec3 = hex_grid_mod.into_vec3(props.state.coord)
	local x = vec3.X
	local y = vec3.Z

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(offset[1] + y * scale / TRANSFORM_SIZE, offset[2] + x * scale / TRANSFORM_SIZE),
		Size = UDim2.fromScale(ratio * 100, ratio * 100),
		-- ScaleType = Enum.ScaleType.Fit,
	}, {
		Icon = React.createElement(Icon, {
			Size = UDim2.new(0.8, 0, 0.8, 0),
			icon = icon,
			ZIndex = 2,
		}),
		Image = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Rotation = 90,
			ImageTransparency = 0.5,
			ScaleType = Enum.ScaleType.Fit,
			ImageColor3 = if props.state.status == "complete"
				then Color3.fromRGB(0, 255, 0)
				else if props.state.status == "researching"
					then Color3.fromRGB(255, 254, 196)
					else Color3.fromRGB(255, 255, 255),
			Image = "http://www.roblox.com/asset/?id=245630713",
			ZIndex = 1,
		}),
		Hitbox = React.createElement("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.9),
			BackgroundTransparency = 0.9,
			Text = "",
			[React.Event.MouseButton1Click] = function()
				props.on_click()
			end,
			ZIndex = 3,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0.5, 0) }),
		}),
	})
end

function Research(props: { entity_id: EntityId, Visible: boolean, on_close: () -> () })
	local transform_ref = React.useRef(nil :: any)
	local transform_values = React.useRef {
		scale = 0.5,
		offset = { 0, 0 },
	}
	local selected_node, set_selected_node = React.useState(nil)
	local entity = hooks.use_synced_entity(props.entity_id)
	React.useEffect(function()
		local is_dragging = false
		local last_position
		local function reset_translation()
			if transform_ref.current then
				local scale = transform_values.current.scale
				local visible_extent = 1000 / scale
				transform_values.current.offset = {
					math.clamp(transform_values.current.offset[1], -2000 + visible_extent, 2000 - visible_extent),
					math.clamp(transform_values.current.offset[2], -2000 + visible_extent, 2000 - visible_extent),
				}
				TweenService:Create(transform_ref.current, TweenInfo.new(0.1), {
					Size = UDim2.fromOffset(
						TRANSFORM_SIZE * transform_values.current.scale,
						TRANSFORM_SIZE * transform_values.current.scale
					),
					Position = UDim2.new(
						0.5,
						transform_values.current.offset[1],
						0.43,
						transform_values.current.offset[2]
					),
				}):Play()
			end
		end
		reset_translation()

		local changed_connection = UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				if is_dragging then
					local delta = input.Position - last_position
					last_position = input.Position
					transform_values.current.offset = {
						transform_values.current.offset[1] + delta.X,
						transform_values.current.offset[2] + delta.Y,
					}
					reset_translation()
				end
			elseif input.UserInputType == Enum.UserInputType.MouseWheel then
				transform_values.current.scale = math.max(0.5, transform_values.current.scale + input.Position.Z * 0.1)
				reset_translation()
			end
		end)
		local began_connection = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				is_dragging = true
				last_position = input.Position
			end
		end)
		local ended_connection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				is_dragging = false
			end
		end)

		return function()
			changed_connection:Disconnect()
			began_connection:Disconnect()
			ended_connection:Disconnect()
		end
	end, {})
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		BackgroundTransparency = 0.05,
		BorderColor3 = Color3.fromRGB(27, 42, 53),
		LayoutOrder = 1,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Active = true,
	}, {
		Header = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, 40),
			ZIndex = 2,
		}, {
			VerticalLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),
			Title = React.createElement("TextLabel", {
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				FontFace = Font.new(
					"rbxasset://fonts/families/Oswald.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Size = UDim2.fromScale(1, 1),
				Text = "Research",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Center,
			}, {
				SidePad = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 15),
					PaddingRight = UDim.new(0, 15),
				}),
			}),
		}),

		Transform = React.createElement(
			"Frame",
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.4),
				BackgroundTransparency = 1,
				ref = transform_ref,
				Size = UDim2.fromOffset(TRANSFORM_SIZE, TRANSFORM_SIZE),
			},
			util.table_map({ { 0, 0 }, { -1, 0 }, { 1, 0 } }, function(pos)
				return React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=12685791118",
					ImageTransparency = 0.9,
					Position = UDim2.fromScale(pos[1], pos[2]),
					ScaleType = Enum.ScaleType.Tile,
					Size = UDim2.fromScale(1, 1),
					TileSize = UDim2.fromScale(0.139, 0.145),
				})
			end),
			util.table_map(util.table_keys(entity.researches.states), function(id)
				local state = entity.researches.states[id]
				return React.createElement(Node, {
					state = state,
					on_click = function()
						set_selected_node(id)
					end,
				})
			end)
		),
		Aside = selected_node and React.createElement(Aside, {
			state = entity.researches.states[selected_node],
			on_close = function()
				set_selected_node(nil)
			end,
			on_add = function()
				decision_remote:FireServer {
					{
						type = "add_research",
						entity_id = entity.id,
						research_id = selected_node,
					},
				}
			end,
			on_remove = function()
				decision_remote:FireServer {
					{
						type = "remove_research",
						entity_id = entity.id,
						research_id = selected_node,
					},
				}
			end,
		}),
		Bottom = React.createElement(
			"Frame",
			themes.theme_solid {
				Position = UDim2.new(0.5, 0, 1, 0),
				AnchorPoint = Vector2.new(0.5, 1),
				Size = UDim2.new(1, 0, 0, 150),
			},
			{
				Gradient = React.createElement("UIGradient", {
					Transparency = NumberSequence.new {
						NumberSequenceKeypoint.new(0, 1),
						NumberSequenceKeypoint.new(1, 0),
					},
					Rotation = 90,
				}),
				Container = React.createElement(
					"Frame",
					{
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 1, 0),
					},
					{
						HorizontalLayout = React.createElement("UIListLayout", {

							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						}),
					},
					util.table_map(entity.researches.queue, function(id)
						local state = entity.researches.states[id]
						return React.createElement(
							"Frame",
							{
								Size = UDim2.new(0, 150, 0, 150),
								BackgroundTransparency = 1,
							},
							{
								VerticalLayout = React.createElement("UIListLayout", {
									Padding = UDim.new(0, 4),
									SortOrder = Enum.SortOrder.LayoutOrder,
									FillDirection = Enum.FillDirection.Vertical,
									VerticalAlignment = Enum.VerticalAlignment.Center,
								}),
								Title = React.createElement("TextLabel", {
									BackgroundTransparency = 1,
									TextSize = 14,
									Size = UDim2.new(1, 0, 0, 30),
									TextColor3 = Color3.fromRGB(255, 255, 255),
									Text = state.name,
								}),
							},
							if state.cost_is_paid
								then {
									Progress = React.createElement(
										"TextLabel",
										themes.theme_description {
											Size = UDim2.new(1, 0, 0, 30),
											Text = `{state.time - state.progress} turns left`,
										}
									),
								}
								else {

									Cost = React.createElement(Cost, {
										cost = state.cost,
									}),
								}
						)
					end)
				),
				ExitButton = React.createElement("TextButton", {
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					BackgroundColor3 = Color3.fromRGB(12, 12, 12),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 14,
					Text = "Back",
					Size = UDim2.new(0, 100, 0, 30),
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, 0, 1, 0),
					[React.Event.MouseButton1Click] = function()
						props.on_close()
					end,
				}),
			}
		),
	})
end

return {
	Research = Research,
}
