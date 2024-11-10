local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local items_mod = require(ReplicatedStorage.Shared.items)
local util = require(ReplicatedStorage.Shared.util)

local themes = require(ReplicatedStorage.Client.ui.themes)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local Items = require(script.Parent.items).Items

local Corner = util_components.Corner
local interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type EntityId = types.EntityId
type HexGrid = types.HexGrid

function ItemFilters(props: { entity_id: EntityId })
	local grid = React.useContext(MainContext).grid
	local entity = hooks.use_synced_entity(props.entity_id)
	local inventory = entity.inventory
	assert(inventory, "inventory nil")

	return React.createElement(
		"Frame",
		themes.theme_background {
			Size = UDim2.new(0, 300, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
		},
		{
			Corner = React.createElement(Corner),
			BottomPad = React.createElement("UIPadding", {
				PaddingBottom = UDim.new(0, 5),
			}),
			VerticalLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			SizeConstraint = React.createElement("UISizeConstraint", {}),

			Header = React.createElement(
				"Frame",
				themes.theme_solid {
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 40),
				},
				{
					Corner = React.createElement(Corner),
					Title = React.createElement(
						"TextLabel",
						themes.theme_title {
							Size = UDim2.new(0, 0, 1, 0),
							Text = "Filters",
						},
						{
							SidePad = React.createElement("UIPadding", {
								PaddingLeft = UDim.new(0, 10),
							}),
						}
					),
				}
			),
			BlacklistWhitelistToggles = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.X,
			}, {
				Label = React.createElement(
					"TextLabel",
					themes.theme_label {
						LayoutOrder = 1,
						Size = UDim2.new(0, 0, 1, 0),
						Text = "Filter with:",
						AutomaticSize = Enum.AutomaticSize.X,
					},
					{
						Padding = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 5),
						}),
					}
				),
				Container = React.createElement("Frame", themes.theme_container {}, {
					HorizontalLayout = React.createElement("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						Padding = UDim.new(0, 8),
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					Padding = React.createElement("UIPadding", {
						PaddingRight = UDim.new(0, 5),
					}),
					BlacklistToggle = React.createElement(
						"TextButton",
						themes.theme_button {
							BackgroundColor3 = Color3.fromRGB(12, 12, 12),
							BackgroundTransparency = if inventory.filter.type == "blacklist" then 0.2 else 0.8,
							FontFace = if inventory.filter.type == "blacklist"
								then Font.fromName("Oswald", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
								else Font.fromName("Oswald", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
							Size = UDim2.new(0, 80, 0, 30),
							LayoutOrder = 2,
							Text = "Blacklist",
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
						},
						{
							Corner = React.createElement(Corner),
							SidePad = React.createElement("UIPadding", {
								PaddingLeft = UDim.new(0, 5),
								PaddingRight = UDim.new(0, 5),
							}),
						}
					),
					WhitelistToggle = React.createElement(
						"TextButton",
						themes.theme_button {
							Size = UDim2.new(0, 80, 0, 30),
							BackgroundColor3 = Color3.fromRGB(12, 12, 12),
							BackgroundTransparency = if inventory.filter.type == "whitelist" then 0.2 else 0.8,
							FontFace = if inventory.filter.type == "whitelist"
								then Font.fromName("Oswald", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
								else Font.fromName("Oswald", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
							LayoutOrder = 3,
							Text = "Whitelist",
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
						},
						{
							Corner = React.createElement(Corner),
							SidePad = React.createElement("UIPadding", {
								PaddingLeft = UDim.new(0, 5),
								PaddingRight = UDim.new(0, 5),
							}),
						}
					),
				}),
			}),
			Items = React.createElement(
				"Frame",
				themes.theme_vertical_container {
					LayoutOrder = 3,
				},
				{
					GridLayout = React.createElement("UIGridLayout", {
						CellPadding = UDim2.new(0, 6, 0, 6),
						CellSize = UDim2.new(0, 36, 0, 36),
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					Padding = React.createElement("UIPadding", {}),
				},
				util.table_map(items_mod.item_names, function(item_name, item)
					local icon_ref = React.useRef(nil)
					local label_ref = React.useRef(nil)
					return React.createElement("TextButton", {
						BackgroundColor3 = Color3.fromRGB(12, 12, 12),
						BackgroundTransparency = if inventory.filter.items[item] then 0.2 else 0.8,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
						Size = UDim2.new(1, 0, 0, 20),
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14,
						[React.Event.MouseButton1Click] = function()
							inventory.filter.items[item] = not inventory.filter.items[item]
							print(inventory.filter)
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
						LabelRef = React.createElement(
							"TextLabel",
							themes.theme_label {
								ref = label_ref,
								TextColor3 = items_mod.item_colors[item],
								TextSize = 12,
								Visible = false,
								Text = item_name,
							}
						),
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
		}
	)
end

function ItemFiltersPreview(props: { LayoutOrder: number?, entity_id: EntityId, click: () -> () })
	local grid = React.useContext(MainContext).grid
	local entity = hooks.use_synced_entity(props.entity_id)
	local inventory = entity.inventory
	assert(inventory, "inventory nil")
	local is_owner = entity.owner == grid:get_player_team(Players.LocalPlayer).id

	return React.createElement("TextButton", {
		BackgroundTransparency = 0.9,
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "",
		Size = UDim2.new(0, 0, 0, 25),
		LayoutOrder = props.LayoutOrder,
		[React.Event.MouseButton1Click] = props.click,
	}, {
		Corner = React.createElement(Corner),
		SidePad = React.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),
		Stroke = if is_owner
			then React.createElement("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(255, 255, 255),
				LineJoinMode = Enum.LineJoinMode.Round,
				Thickness = 1,
				Transparency = 0.7,
			})
			else nil,
		HorizontalLayout = React.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
		}),
		Text = React.createElement(
			"TextLabel",
			themes.theme_description {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 0, 1, 0),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Text = "Edit Filter",
			}
		),
	})
end

return {
	ItemFilters = ItemFilters,
	ItemFiltersPreview = ItemFiltersPreview,
}
