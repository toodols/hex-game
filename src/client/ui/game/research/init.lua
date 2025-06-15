local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"
local UserInputService = game:GetService "UserInputService"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)
local researches_mod = require(ReplicatedStorage.Shared.researches)

local themes = require(ReplicatedStorage.Client.ui.themes)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local util_components = require(ReplicatedStorage.Client.ui.util_components)

local TextActionButton = require(script.Parent.action_button).TextActionButton
local Items = require(script.Parent.items).Items
local ResearchPreview = require(script.research_preview).ResearchPreview
local Icon = require(script.icon).Icon
local Aside = require(script.aside).Aside

local Corner = util_components.Corner
local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type Entity = types.Entity
type ResearchItem = types.ResearchItem
type World = types.World
type EntityId = types.EntityId
type Icon = types.Icon
type TeamData = types.TeamData
type ResearchState = types.ResearchState

local TRANSFORM_SIZE = 5000
function Node(props: { item: ResearchItem, state: ResearchState, on_click: () -> () })
	local icon = props.item.icon
	local scale = 80
	local ratio = scale / 52 / TRANSFORM_SIZE
	-- local offset = { 1531 * ratio, 1598 * ratio }
	local offset = { 1531 * ratio, 1598 * ratio }
	local vec3 = coords.into_vec3(props.item.coord)
	local x = vec3.X
	local y = vec3.Z

	local image_ref = React.useRef(nil :: any)

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(offset[1] + y * scale / TRANSFORM_SIZE, 0, offset[2] + x * scale / TRANSFORM_SIZE, 0),
		Size = UDim2.new(ratio * 100, 0, ratio * 100, 0),
		-- ScaleType = Enum.ScaleType.Fit,
	}, {
		Icon = React.createElement(Icon, {
			Size = UDim2.new(0.8, 0, 0.8, 0),
			icon = icon,
			ZIndex = 2,
		}),
		Image = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			Rotation = 90,
			ImageTransparency = 0.5,
			ScaleType = Enum.ScaleType.Fit,
			ref = image_ref,
			ImageColor3 = if not researches_mod.research_is_available(props.item, props.state)
				then Color3.fromRGB(80, 80, 80)
				elseif props.item.status == "complete" then Color3.fromRGB(0, 255, 0)
				elseif props.item.status == "researching" then Color3.fromRGB(255, 254, 196)
				else Color3.fromRGB(255, 255, 255),
			Image = "http://www.roblox.com/asset/?id=245630713",
			ZIndex = 1,
		}),
		Hitbox = React.createElement("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0.9, 0, 0.9, 0),
			BackgroundTransparency = 1,
			Text = "",
			[React.Event.MouseEnter] = function()
				image_ref.current.ImageTransparency = 0
			end,
			[React.Event.MouseLeave] = function()
				image_ref.current.ImageTransparency = 0.5
			end,
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
					Size = UDim2.new(
						0,
						TRANSFORM_SIZE * transform_values.current.scale,
						0,
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
				transform_values.current.scale =
					math.clamp(transform_values.current.scale + input.Position.Z * 0.1, 0.5, 2)
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
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 1, 0),
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
				Size = UDim2.new(1, 0, 1, 0),
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
				Position = UDim2.new(0.5, 0, 0.4, 0),
				BackgroundTransparency = 1,
				ref = transform_ref,
				Size = UDim2.new(0, TRANSFORM_SIZE, 0, TRANSFORM_SIZE),
			},
			util.table_map({ { 0, 0 }, { -1, 0 }, { 1, 0 } }, function(pos)
				return React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=12685791118",
					ImageTransparency = 0.9,
					Position = UDim2.new(pos[1], 0, pos[2], 0),
					ScaleType = Enum.ScaleType.Tile,
					Size = UDim2.new(1, 0, 1, 0),
					TileSize = UDim2.new(0.139, 0, 0.145, 0),
				})
			end),
			util.table_map(entity.researches.states, function(v, k)
				return React.createElement(Node, {
					item = v,
					state = entity.researches,
					on_click = function()
						set_selected_node(k)
					end,
				})
			end)
		),
		Aside = selected_node and React.createElement(Aside, {
			item = entity.researches.states[selected_node],
			state = entity.researches,
			on_close = function()
				set_selected_node(nil)
			end,
			on_add = function()
				client_interaction_remote:FireServer {
					{
						type = "add_research",
						entity_id = entity.id,
						research_id = selected_node,
					},
				}
			end,
			-- on_remove = function()
			-- 	client_interaction_remote:FireServer {
			-- 		{
			-- 			type = "remove_research",
			-- 			entity_id = entity.id,
			-- 			research_id = selected_node,
			-- 		},
			-- 	}
			-- end,
		}),
		Bottom = React.createElement(ResearchBottom, {
			on_close = props.on_close,
			entity = entity,
		}),
	})
end

function ResearchBottom(props: {
	on_close: () -> (),
	entity: Entity,
})
	local entity = props.entity
	local refs = React.useRef {}
	local tween_refs = React.useRef {}
	return React.createElement(
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
					PaddingBottom = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0, 10),
					}),
					HorizontalLayout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 10),
						FillDirection = Enum.FillDirection.Horizontal,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
					}),
				},
				util.table_map(entity.researches.queue, function(id, idx)
					local state = entity.researches.states[id]
					return React.createElement(
						"Frame",
						themes.theme_solid {
							Size = UDim2.new(0, 180, 0, 100),
							BackgroundTransparency = 1,
						},
						{
							Stroke = React.createElement("UIStroke", {
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
								Color = Color3.fromRGB(255, 255, 255),
								LineJoinMode = Enum.LineJoinMode.Round,
								Thickness = 1,
								Transparency = 0.9,
							}),
							Corner = React.createElement(Corner),

							Container = React.createElement(
								"Frame",
								themes.theme_container {
									LayoutOrder = 1,
								},
								{
									Padding = React.createElement("UIPadding", {
										PaddingLeft = UDim.new(0, 5),
										PaddingRight = UDim.new(0, 5),
										PaddingBottom = UDim.new(0, 5),
										PaddingTop = UDim.new(0, 5),
									}),
									Title = React.createElement(
										"TextLabel",
										themes.theme_title {
											BackgroundTransparency = 1,
											Size = UDim2.new(1, 0, 0, 30),
											TextColor3 = Color3.fromRGB(255, 255, 255),
											Text = state.name,
										},
										{
											Padding = React.createElement("UIPadding", {
												PaddingLeft = UDim.new(0, 5),
											}),
										}
									),
									VerticalLayout = React.createElement("UIListLayout", {
										Padding = UDim.new(0, 4),
										SortOrder = Enum.SortOrder.LayoutOrder,
										FillDirection = Enum.FillDirection.Vertical,
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
										Items = React.createElement(Items, {
											items = state.cost,
										}),
									}
							),
							RemoveButton = React.createElement(TextActionButton, {
								color = Color3.fromRGB(200, 0, 0),
								Size = UDim2.new(1, 0, 0, 20),
								LayoutOrder = 2,
								Text = "Remove",
								ref = function(ref)
									refs.current[idx] = ref
								end,
								[React.Event.MouseEnter] = function()
									for i = idx, #tween_refs.current do
										tween_refs.current[i]:Pause()
									end
									for i = idx, #refs.current do
										tween_refs.current[i] =
											TweenService:Create(refs.current[i], TweenInfo.new(0.2), {
												BackgroundTransparency = 0.8,
											})
										tween_refs.current[i]:Play()
									end
								end,
								[React.Event.MouseLeave] = function()
									for i = idx, #tween_refs.current do
										tween_refs.current[i]:Pause()
									end
									for i = idx, #refs.current do
										tween_refs.current[i] =
											TweenService:Create(refs.current[i], TweenInfo.new(0.2), {
												BackgroundTransparency = 1,
											})
										tween_refs.current[i]:Play()
									end
								end,
								Position = UDim2.new(0, 0, 1, 0),
								AnchorPoint = Vector2.new(0, 1),
								on_click = function()
									client_interaction_remote:FireServer {
										{
											type = "remove_research",
											entity_id = entity.id,
											research_id = id,
										},
									}
								end,
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
	)
end

return {
	Research = Research,
	ResearchPreview = ResearchPreview,
}
