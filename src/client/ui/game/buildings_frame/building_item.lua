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
local Items = require(ReplicatedStorage.Client.ui.game.items).Items
local util_components = require(ReplicatedStorage.Client.ui.util_components)

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

		LockedFrame = if props.locked
			then React.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				[React.Tag] = "solid",
			}, {
				UIPadding = React.createElement("UIPadding", {
					PaddingBottom = UDim.new(0, 5),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 5),
				}),
				LockedTitle = React.createElement("TextLabel", {
					Position = UDim2.new(0.5, 0, 0.5, -30),
					Size = UDim2.new(1, 0, 0, 30),
					Text = "Locked",
					[React.Tag] = "text-c align-tc title",
				}),
				RequiredLabel = if #entity_config.required_unlockable > 0
					then React.createElement("TextLabel", {
						LayoutOrder = 4,
						Position = UDim2.new(0.5, 0, 0.5, 15),
						Size = UDim2.new(0, 150, 0, 0),
						Text = "You haven't unlocked this building yet.",
						[React.Tag] = "text-c description align-cc as-y",
						TextWrapped = true,
					})
					else nil,
			})
			else nil,
		Content = React.createElement("TextButton", {
			Text = "",
			ref = item_ref,
			Size = UDim2.new(1, 0, 0, height),
			Position = if props.do_animation then UDim2.new(0, 0, 0, -30) else UDim2.new(0, 0, 0, 0),
			[React.Tag] = "solid pad-5",
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
		}, {

			ViewportFrame = React.createElement("ViewportFrame", {
				Size = UDim2.new(1, 0, 0, 150),
				[React.Tag] = "align-cc",
				ImageTransparency = 0.6,
				ref = viewport_ref,
			}),

			Top = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
			}, {

				ItemTitle = React.createElement("TextLabel", {
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 25),
					Text = entity_config.name,
					TextColor3 = if can_build then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(90, 90, 90),
					[React.Tag] = "text-l subtitle",
				}),

				Separator = React.createElement(Separator, {
					LayoutOrder = 2,
				}),
				Description = React.createElement("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = 3,
					Text = formatting.format_text(world, entity_config.short_description),
					[React.Tag] = "description",
				}, {
					SizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = Vector2.new(math.huge, 100),
					}),
				}),
				Items = React.createElement(Items, {
					items = entity_config.cost,
					LayoutOrder = 5,
				}),
				MustBeBuiltOn = if construction_condition_status and construction_condition_status.built_on
					then React.createElement("TextLabel", {
						LayoutOrder = 7,
						[React.Tag] = "description",
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
					})
					else nil,
				MustBeNearby = if construction_condition_status and construction_condition_status.nearby
					then React.createElement("TextLabel", {
						LayoutOrder = 8,
						[React.Tag] = "description",

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
					})
					else nil,
				MustNotBeNearby = if construction_condition_status
						and construction_condition_status.not_nearby
					then React.createElement("TextLabel", {
						LayoutOrder = 9,
						[React.Tag] = "description",
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
					})
					else nil,

				VerticalLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}),
		}),
	})
end)

return {
	BuildingItem = BuildingItem,
}
