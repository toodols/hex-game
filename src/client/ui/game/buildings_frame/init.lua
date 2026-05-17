local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local React = require(ReplicatedStorage.Packages.react)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local researches_mod = require(ReplicatedStorage.Shared.researches)
local team = require(ReplicatedStorage.Shared.team)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local unlockable_mod = require(ReplicatedStorage.Shared.unlockable)

local BuildingItem = require(script.building_item).BuildingItem

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
				type = "terminal",
			},
			{
				type = "turret",
			},
			{
				type = "fountain",
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
				type = "anima",
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
				type = "heart",
			},
			{
				type = "ragnarok",
			},
			{
				type = "necromancer",
			},
			{
				type = "rash",
			},
			{
				type = "big",
			},
		},
	},
}

local HEIGHT = 250

local BuildingPage = React.forwardRef(function(
	props: {
		page: { name: string, items: { type: string } },
		cell: CubicCoordinate,
		researches: { [ResearchId]: boolean },
	},
	ref
)
	local world: World = React.useContext(MainContext).world
	local player_data = world.player_data[tostring(Players.LocalPlayer.UserId)]

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
				height = HEIGHT,
				locked = not unlockable_mod.player_has_unlockable(
					player_data,
					world.entity_configurations[item.type].required_unlockable
				),
				mouse_enter = function() end,
				mouse_leave = function() end,
			})
		end)
	)
end)

function BuildingsFrame(props: { Visible: boolean, cell: CubicCoordinate })
	local world: World = React.useContext(MainContext).world
	local player_team = team.team_of(world, Players.LocalPlayer)
	local player_data = world.player_data[tostring(Players.LocalPlayer.UserId)]
	local current_page, set_current_page = React.useState(1)
	local is_expanded, set_is_expanded = React.useState(false)
	local page_layout_ref = React.useRef(nil :: any)
	local page_refs = React.useRef({} :: any)
	local ref = React.useRef(nil :: any)
	local expanded_content_ref = React.useRef(nil :: any)
	local cell = world:get_cell(props.cell)
	assert(cell, "cell is nil")
	local researches = researches_mod.get_cells_researches(world, { cell }, player_team.id)
	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)

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

	React.useEffect(function()
		world.world_update_signal.listen(function(updates)
			for _, update in updates do
				if update.type == "entity_update" then
					force_update(nil)
					return
				end
			end
		end)
	end)

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
					key = "page-" .. page_idx,
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
			LayoutOrder = 2,
			[React.Tag] = "header",
		}, {
			Left2 = React.createElement("Frame", {
				[React.Tag] = "container pad-l-10",
				Visible = is_expanded,
			}, {
				Title = React.createElement("TextLabel", {
					Text = "Buildings",
					[React.Tag] = "title",
				}),
			}),
			Left = React.createElement(
				"Frame",
				{
					[React.Tag] = "container pages-nav list-h list-pad-5 list-bl",
					Visible = not is_expanded,
				},
				util.table_map(util.range(#PAGES), function(i)
					local page = PAGES[i]
					return React.createElement("TextButton", {
						[React.Tag] = `tab {if i == current_page then "active" else ""} title pad-h-10`,
						BackgroundTransparency = 1,
						Text = if i == current_page then `<b>{page.name}</b>` else page.name,
						[React.Event.MouseButton1Click] = function()
							page_layout_ref.current:JumpToIndex(i - 1)
							set_current_page(i)
						end,
					})
				end)
			),
			Right = React.createElement("Frame", { [React.Tag] = "container list-h list-pad-5 list-cr" }, {
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
				ref = expanded_content_ref,
				[React.Tag] = "background pad-h-10 pad-v-5 list-v list-pad-5",
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 0),
			},
			{},
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
							height = HEIGHT,
							locked = not unlockable_mod.player_has_unlockable(
								player_data,
								world.entity_configurations[item.type].required_unlockable
							),
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
