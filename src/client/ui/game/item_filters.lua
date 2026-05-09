local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local items_mod = require(ReplicatedStorage.Shared.items)
local util = require(ReplicatedStorage.Shared.util)
local team = require(ReplicatedStorage.Shared.team)

local themes = require(ReplicatedStorage.Client.ui.themes)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext

local Corner = util_components.Corner
local interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type EntityId = types.EntityId
type World = types.World
type TeamData = types.TeamData

function ItemFilters(props: { entity_id: EntityId })
	local entity = hooks.use_synced_entity(props.entity_id)
	local inventory = entity.inventory
	assert(inventory, "inventory nil")

	return React.createElement("Frame", {
		Size = UDim2.new(0, 300, 0, 0),
		[React.Tag] = "background as-y list-v pad-b-5",
	}, {
		Header = React.createElement("Frame", {
			LayoutOrder = 1,
			[React.Tag] = "header",
		}, {
			Title = React.createElement("TextLabel", {
				Text = "Filters",
				[React.Tag] = "title",
			}),
		}),
		BlacklistWhitelistToggles = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			LayoutOrder = 2,
			AutomaticSize = Enum.AutomaticSize.X,
			[React.Tag] = "pad-l-5 list-h list-pad-5",
		}, {
			Label = React.createElement("TextLabel", {
				LayoutOrder = 1,
				Text = "Filter with",
				[React.Tag] = "list-h",
			}),
			Container = React.createElement("Frame", {
				LayoutOrder = 2,
				[React.Tag] = "container-h list-h list-pad-5 list-cr",
			}, {
				BlacklistToggle = React.createElement("TextButton", {
					Size = UDim2.new(0, 80, 0, 30),
					LayoutOrder = 2,
					Text = "Blacklist",
					[React.Tag] = `option {if inventory.filter.type == "blacklist" then "active" else ""}`,
					[React.Event.MouseButton1Click] = function()
						interaction_remote:FireServer {
							{
								type = "set_inventory_filter",
								entity_id = props.entity_id,
								filter = {
									type = "blacklist",
									items = inventory.filter.items,
								},
							},
						}
					end,
				}),
				WhitelistToggle = React.createElement("TextButton", {
					Size = UDim2.new(0, 80, 0, 30),
					LayoutOrder = 3,
					Text = "Whitelist",
					[React.Tag] = `option pad-l-5 {if inventory.filter.type == "whitelist" then "active" else ""}`,
					[React.Event.MouseButton1Click] = function()
						interaction_remote:FireServer {
							{
								type = "set_inventory_filter",
								entity_id = props.entity_id,
								filter = {
									type = "whitelist",
									items = inventory.filter.items,
								},
							},
						}
					end,
				}),
			}),
		}),
		Items = React.createElement(
			"Frame",
			{
				[React.Tag] = "container-v grid-cc grid-pad-6 grid-cell-36",
				LayoutOrder = 3,
			},
			util.table_map(items_mod.item_names, function(item_name, item)
				local icon_ref = React.useRef(nil)
				local label_ref = React.useRef(nil)
				return React.createElement("TextButton", {
					BackgroundTransparency = if inventory.filter.items[item] then 0.2 else 0.8,
					FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
					Size = UDim2.new(1, 0, 0, 20),
					Text = "",
					TextSize = 14,
					[React.Tag] = "solid",
					[React.Event.MouseButton1Click] = function()
						inventory.filter.items[item] = not inventory.filter.items[item]
						interaction_remote:FireServer {
							{
								type = "set_inventory_filter",
								entity_id = props.entity_id,
								filter = inventory.filter,
							},
						}
					end,
					[React.Event.MouseEnter] = function()
						icon_ref.current.Visible = false
						label_ref.current.Visible = true
					end,
					[React.Event.MouseLeave] = function()
						icon_ref.current.Visible = true
						label_ref.current.Visible = false
					end,
				}, {
					HorizontalLayout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, 4),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					LabelRef = React.createElement("TextLabel", {
						ref = label_ref,
						TextColor3 = items_mod.item_colors[item],
						Visible = false,
						Text = item_name,
					}),
					Icon = React.createElement("Frame", {
						BackgroundTransparency = 1,
						Size = UDim2.new(0, 10, 0, 10),
						ref = icon_ref,
					}, {
						Inner = React.createElement("Frame", {
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = items_mod.item_colors[item],
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Position = UDim2.new(0.5, 0, 0.5, 0),
							Rotation = 45,
							Size = UDim2.new(0, 10, 0, 10),
						}),
					}),

					Corner = React.createElement("UICorner", {
						CornerRadius = UDim.new(0, 4),
					}),
				})
			end)
		),
	})
end

function ItemFiltersPreview(props: { LayoutOrder: number?, entity_id: EntityId, click: () -> () })
	local context = React.useContext(MainContext)
	local world: World = context.world
	local entity = hooks.use_synced_entity(props.entity_id)
	local inventory = entity.inventory
	assert(inventory, "inventory nil")
	local is_owner = entity.owner == (team.team_of(world, Players.LocalPlayer) :: TeamData).id

	local opened = context.submenu.type == "item_filters" and context.submenu.entity_id == props.entity_id

	return React.createElement("TextButton", {
		Text = "",
		Size = UDim2.new(0, 0, 0, 25),
		LayoutOrder = props.LayoutOrder,
		[React.Tag] = `background list-h pad-l-5 pad-r-5 item-filters-preview {if is_owner then "editable" else ""} {if opened
			then "active"
			else ""}`,
		[React.Event.MouseButton1Click] = props.click,
	}, {
		Text = React.createElement("TextLabel", {
			[React.Tag] = "title",
			Text = if is_owner then "Edit Filter" else "View Filter",
		}),
	})
end

return {
	ItemFilters = ItemFilters,
	ItemFiltersPreview = ItemFiltersPreview,
}
