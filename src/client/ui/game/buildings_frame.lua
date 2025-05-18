local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local React = require(ReplicatedStorage.Packages.react)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local formatting = require(ReplicatedStorage.Shared.formatting)
local researches_mod = require(ReplicatedStorage.Shared.researches)
local team = require(ReplicatedStorage.Shared.team)
local themes = require(ReplicatedStorage.Client.ui.themes)
local Items = require(script.Parent.items).Items
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local client_entity_mod = require(ReplicatedStorage.Client.ui.Parent.entity)
local util_components = require(ReplicatedStorage.Client.ui.util_components)

local Corner = util_components.Corner
local Separator = util_components.Separator

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type CubicCoordinate = types.CubicCoordinate
type Item = types.Item
type World = types.World
type ResearchId = types.ResearchId
local PAGES = {
	{
		name = "Page 1",
		items = {
			{ type = "vertex" },
			{
				type = "stockpile",
			},
			{
				type = "extractor",
			},
			{
				type = "scout",
			},
			{
				type = "solution",
			},
			{
				type = "obelisk",
			},
		},
	},
	{
		name = "Page 2",
		items = {
			{
				type = "factory",
			},
			{
				type = "laboratory",
			},
			{
				type = "turret",
			},
			{
				type = "witness",
			},
			{
				type = "impression",
			},
			{
				type = "suggestion",
			},
		},
	},
	{
		name = "Page 3",
		items = {
			{
				type = "vault",
			},

			{
				type = "proxy",
			},
			{
				type = "heart",
			},
			{
				type = "taunt",
			},
			{
				type = "phony",
			},
			{
				type = "torch",
			},
		},
	},
	{
		name = "Page 4",
		items = {
			{
				type = "fountain",
			},
		},
	},
}

local HEIGHT = 220
local BuildingItem = React.forwardRef(function(
	props: {
		do_animation: boolean,
		type: string,
		cell: CubicCoordinate,
		researches: { [ResearchId]: boolean },
		mouse_enter: () -> (),
		mouse_leave: () -> (),
	},
	ref
)
	local world: World = React.useContext(MainContext).world
	local entity_config = world.entity_configurations[props.type]
	local button_ref = React.useRef(nil :: any)
	local viewport_ref = React.useRef(nil :: any)
	React.useEffect(function()
		local model = client_entity_mod.create_model_from_type(world, props.type)
		model.Parent = viewport_ref.current
		model:PivotTo(CFrame.new(0, -2, -4))
	end, { props.type })

	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		ref = ref,
		Size = UDim2.new(0, 160, 0, if props.do_animation then 0 else HEIGHT),
	}, {
		TextButton = React.createElement(
			"TextButton",
			themes.theme_solid {
				Position = if props.do_animation then UDim2.new(0, 0, 0, -30) else UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, HEIGHT),
				Text = "",
				TextSize = 14,
				ref = button_ref,
				[React.Event.MouseButton1Click] = function()
					client_interaction_remote:FireServer {
						{
							type = "construct",
							entity_type = props.type,
							coordinate = props.cell,
						},
					}
				end,
				[React.Event.MouseEnter] = function()
					props.mouse_enter()
					if props.do_animation then
						TweenService:Create(button_ref.current, TweenInfo.new(0.3), {
							Position = UDim2.new(0, 0, 0, -HEIGHT),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						}):Play()
					end
				end,
				[React.Event.MouseLeave] = function()
					props.mouse_leave()
					if props.do_animation then
						TweenService:Create(button_ref.current, TweenInfo.new(0.3), {
							Position = UDim2.new(0, 0, 0, -30),
							BackgroundColor3 = Color3.fromRGB(13, 13, 13),
						}):Play()
					end
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
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),

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
							Text = formatting.format_text(world, entity_config.description),
							TextWrapped = true,
							TextSize = 13,
							TextTruncate = Enum.TextTruncate.AtEnd,
						},
						{
							SizeConstraint = React.createElement("UISizeConstraint", {
								MaxSize = Vector2.new(math.huge, 80),
							}),
						}
					),
					RequiredResearch = entity_config.required_research
						and #entity_config.required_research > 0
						and React.createElement(
							"TextLabel",
							themes.theme_description {
								BackgroundTransparency = 1,
								LayoutOrder = 4,
								AutomaticSize = Enum.AutomaticSize.Y,
								Size = UDim2.new(1, 0, 0, 0),
								Text = "Requires Research: " .. table.concat(
									util.table_map(entity_config.required_research, function(research_id)
										local research = researches_mod.researches[research_id]
										if props.researches[research_id] then
											return `<font color="rgb(50, 155, 50)">{research.name}</font>`
										else
											return `<font color="rgb(155, 50, 50)">{research.name}</font>`
										end
									end),
									", "
								),
								TextSize = 13,
							}
						),
					Items = React.createElement(Items, {
						items = entity_config.cost,
						LayoutOrder = 5,
					}),
					VerticalLayout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),
			}
		),
	})
end)

local BuildingPage = function(
	props: {
		page: { name: string, items: { type: string } },
		cell: CubicCoordinate,
		researches: { [ResearchId]: boolean },
	},
	ref
)
	return React.createElement(
		"Frame",
		{
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			Size = UDim2.new(1, 0, 0, 30),
			ref = ref,
		},
		{
			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Padding = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
			}),
		},
		util.table_map(props.page.items, function(item)
			return React.createElement(BuildingItem, {
				do_animation = true,
				type = item.type,
				cell = props.cell,
				researches = props.researches,
				mouse_enter = function() end,
				mouse_leave = function() end,
			})
		end)
	)
end

function BuildingsFrame(props: { Visible: boolean, cell: CubicCoordinate })
	local world: World = React.useContext(MainContext).world
	local player_team = team.team_of(world, Players.LocalPlayer)
	local current_page, set_current_page = React.useState(1)
	local is_expanded, set_is_expanded = React.useState(false)
	local page_layout_ref = React.useRef(nil :: any)
	local page_refs = React.useRef({} :: any)
	local ref = React.useRef(nil :: any)
	local expanded_content_ref = React.useRef(nil :: any)

	local cell = world:get_cell(props.cell)
	assert(cell, "cell is nil")
	local researches = researches_mod.get_cells_researches(world, { cell }, player_team.id)

	React.useEffect(function()
		page_layout_ref.current:GetPropertyChangedSignal("CurrentPage"):Connect(function()
			set_current_page(page_refs.current[page_layout_ref.current.CurrentPage])
		end)
	end, {})

	local props_ref = React.useRef(nil)
	if not util.deep_equal(props_ref.current, props) then
		props_ref.current = props
	end
	React.useEffect(function()
		ref.current.Position = UDim2.new(0.5, 0, 1, HEIGHT)
		TweenService:Create(ref.current, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 1, 0),
		}):Play()
	end, { props_ref.current })

	React.useEffect(function()
		if is_expanded then
			TweenService:Create(expanded_content_ref.current, TweenInfo.new(0.3), {
				Size = UDim2.new(1, 0, 1, 0),
				ScrollBarImageTransparency = 0,
			}):Play()
		else
			TweenService:Create(expanded_content_ref.current, TweenInfo.new(0.3), {
				Size = UDim2.new(1, 0, 0, 0),
				ScrollBarImageTransparency = 1,
			}):Play()
		end
	end, { is_expanded })

	return React.createElement("Frame", {
		Visible = props.Visible,
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(27, 42, 53),
		LayoutOrder = 2,
		Position = UDim2.new(0.5, 0, 1, HEIGHT),
		Size = UDim2.new(0, 1000, 0.8, 0),
		ref = ref,
	}, {
		VerticalLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 1),
		}),
	}, {
		SizeConstraint = React.createElement("UISizeConstraint", {
			MinSize = Vector2.new(0, 300),
		}),
		Content = React.createElement(
			"Frame",
			{
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				ClipsDescendants = true,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 1, -20),
				Size = UDim2.new(1, 0, 0, if is_expanded then 0 else 300),
			},
			{
				UIPageLayout = React.createElement("UIPageLayout", {
					EasingStyle = Enum.EasingStyle.Exponential,
					SortOrder = Enum.SortOrder.LayoutOrder,
					TweenTime = 0.5,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					ref = page_layout_ref,
				}),
			},
			util.table_map(util.range(#PAGES), function(page_idx)
				local page = PAGES[page_idx]
				return React.createElement(BuildingPage, {
					ref = function(s)
						if s then
							page_refs.current[s] = page_idx
						end
					end,
					researches = researches,
					page = page,
					cell = props.cell,
				})
			end)
		),
		Navigation = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(12, 12, 12),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 40),
		}, {
			Corner = React.createElement(Corner),
			Left2 = React.createElement(
				"Frame",
				themes.theme_container {
					Visible = is_expanded,
				},
				{
					LeftPad = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 10),
					}),
					Title = React.createElement(
						"TextLabel",
						themes.theme_title {
							Text = "Buildings",
							Size = UDim2.new(0, 0, 1, 0),
						}
					),
				}
			),
			Left = React.createElement(
				"Frame",
				themes.theme_container {
					Visible = not is_expanded,
				},
				{
					HorizontalLayout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Left,
						Padding = UDim.new(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Bottom,
					}),
				},
				util.table_map(util.range(#PAGES), function(i)
					local page = PAGES[i]
					return React.createElement("TextButton", {
						RichText = true,
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundColor3 = Color3.fromRGB(12, 12, 12),
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/Oswald.json",
							Enum.FontWeight.Regular,
							Enum.FontStyle.Normal
						),
						Size = UDim2.new(0, 0, 1, 0),
						Text = if i == current_page then `<b>{page.name}</b>` else page.name,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 18,
						[React.Event.MouseButton1Click] = function()
							set_current_page(i)
							page_layout_ref.current:JumpToIndex(i - 1)
						end,
					}, {
						UIPadding = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 10),
							PaddingRight = UDim.new(0, 10),
						}),
					})
				end)
			),
			Right = React.createElement("Frame", themes.theme_container {}, {
				HorizontalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				ExpandButton = React.createElement("ImageButton", {
					BackgroundTransparency = 1,
					Image = if is_expanded then "rbxassetid://6034818372" else "rbxassetid://6034818379",
					Size = UDim2.new(0, 40, 0, 40),
					[React.Event.MouseButton1Click] = function()
						set_is_expanded(not is_expanded)
					end,
				}),
			}),
		}),
		ExpandedContent = React.createElement(
			"ScrollingFrame",
			{
				BackgroundColor3 = Color3.fromRGB(12, 12, 12),
				ref = expanded_content_ref,
				BackgroundTransparency = 0.2,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 3,
				ScrollBarImageTransparency = 1,
				ScrollBarThickness = 2,
				Size = UDim2.new(1, 0, 0, 0),
				CanvasSize = UDim2.new(1, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
			},
			{
				UIPadding = React.createElement("UIPadding", {
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 5),
				}),
				VerticalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Top,
				}),
			},
			util.table_map(util.range(#PAGES), function(page_idx)
				local page = PAGES[page_idx]
				local inst = {}
				local cur
				return React.createElement(
					"Frame",
					{
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, HEIGHT),
					},
					{
						HorizontalLayout = React.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = UDim.new(0, 4),
							VerticalAlignment = Enum.VerticalAlignment.Bottom,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					},
					util.table_map(page.items, function(item, col)
						return React.createElement(BuildingItem, {
							type = item.type,
							researches = researches,
							cell = props.cell,
							ref = function(v)
								inst[col] = v
							end,
							mouse_enter = function()
								cur = col
								for i, v in inst do
									if col == i then
										TweenService:Create(v, TweenInfo.new(0.1), {
											Size = UDim2.new(0, 160 + 20 * 5, 0, HEIGHT),
										}):Play()
									else
										TweenService:Create(v, TweenInfo.new(0.1), {
											Size = UDim2.new(0, 160 - 20, 0, HEIGHT),
										}):Play()
									end
								end
							end,
							mouse_leave = function()
								if cur == col then
									cur = nil
									for i, v in inst do
										TweenService:Create(v, TweenInfo.new(0.1), {
											Size = UDim2.new(0, 160, 0, HEIGHT),
										}):Play()
									end
								end
							end,
						})
					end)
				)
			end)
		),
	})
end

return {
	BuildingsFrame = BuildingsFrame,
}
