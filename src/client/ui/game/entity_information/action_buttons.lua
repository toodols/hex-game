local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local team_mod = require(ReplicatedStorage.Shared.team)
local util = require(ReplicatedStorage.Shared.util)
local world_mod = require(ReplicatedStorage.Shared.world)
local coords_mod = require(ReplicatedStorage.Shared.coords)

local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local ui_types = require(ReplicatedStorage.Client.ui.types)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local SquareActionButton = require(ReplicatedStorage.Client.ui.game.action_button).SquareActionButton

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type SelectionMode = ui_types.SelectionMode
type EntityId = types.EntityId
type EncodedCoordinate = types.EncodedCoordinate
type World = types.World
type HexCell = types.HexCell
type Entity = types.Entity

function AttackButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local context = React.useContext(MainContext)
	local world: World = context.world
	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	local entity = hooks.use_synced_entity(props.entity_id)
	local shared_behavior = shared_entity_mod.registry[entity.type]
	local player_team = team_mod.team_of(world, Players.LocalPlayer)

	local ability_name = if entity.type == "scout"
		then "scout_attack"
		else if entity.type == "turret" then "turret_attack" else error "unreachable"

	local is_attacking = util.table_any(entity.queued_decisions, function(v)
		return v.type == "ability" and v.ability_type == ability_name
	end)

	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://10734975486",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 120, 120),
		ImageColor3 = if is_attacking then Color3.fromRGB(255, 120, 120) else Color3.fromRGB(200, 200, 200),
		on_click = function()
			if is_attacking then
				client_interaction_remote:FireServer {
					{
						type = "cancel_decision",
						decision_type = "ability",
						entity_id = entity.id,
					},
				}
				return
			end
			local ability = shared_behavior.abilities[ability_name]

			local candidates: { [EncodedCoordinate]: true } = {}
			for _, coord in
				world_mod.coords_filter(world, coords_mod.neighbors_leq(entity.primary_coordinate, ability.range))
			do
				if not world_mod.line_of_sight(world, entity.primary_coordinate, coord, player_team.id) then
					continue
				end

				candidates[coords_mod.encode_coord(coord)] = true
			end

			local taunts_on_cell: { [EntityId]: Entity } = util.table_filter_map(
				(world:get_cell(entity.primary_coordinate) :: HexCell).influences,
				function(_, taunt_id)
					local taunt = world.entities[taunt_id]
					if
						taunt.type == "taunt"
						and candidates[coords_mod.encode_coord(taunt.primary_coordinate)]
						and not team_mod.is_allied(world, taunt.owner, player_team.id)
						and taunt.owner ~= world.neutral_team
					then
						return taunt
					end
					return nil
				end
			)

			if next(taunts_on_cell) ~= nil then
				candidates = {}
				for _, taunt in taunts_on_cell do
					candidates[coords_mod.encode_coord(taunt.primary_coordinate)] = true
				end
			end

			table.insert(selection_mode_stack, {
				type = "select_some_cell",
				candidates = candidates,
				on_selected = function(coord)
					client_interaction_remote:FireServer {
						{
							type = "ability",
							ability_type = ability_name,
							entity_id = entity.id,
							coordinate = coord,
						},
					}
				end,
			})
		end,
	})
end

function DeconstructButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local entity = hooks.use_synced_entity(props.entity_id)

	local is_deconstructing = util.table_any(entity.queued_decisions, function(v)
		return v.type == "deconstruct"
	end)

	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://11768918600",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 0, 0),
		ImageColor3 = if is_deconstructing then Color3.fromRGB(255, 0, 0) else Color3.fromRGB(200, 200, 200),
		on_click = function()
			if is_deconstructing then
				client_interaction_remote:FireServer {
					{
						type = "cancel_decision",
						entity_id = entity.id,
						decision_type = "deconstruct",
					},
				}
			else
				client_interaction_remote:FireServer {
					{
						type = "deconstruct",
						entity_id = entity.id,
					},
				}
			end
		end,
	})
end

function DisguiseButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local entity = hooks.use_synced_entity(props.entity_id)
	local shared_behavior = shared_entity_mod.registry[entity.type]
	local context = React.useContext(MainContext)
	local world: World = context.world
	local selection_mode_stack: { SelectionMode } = context.selection_mode_stack
	local is_disguising = util.table_any(entity.queued_decisions, function(v)
		return v.type == "ability" and v.ability_type == "disguise"
	end)
	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://6034467796",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(255, 0, 0),
		ImageColor3 = if is_disguising then Color3.fromRGB(113, 172, 196) else Color3.fromRGB(200, 200, 200),
		on_click = function()
			local ability = shared_behavior.abilities.disguise
			local candidates: { [EncodedCoordinate]: true } = {}
			for _, coord in coords_mod.neighbors_leq(entity.primary_coordinate, ability.range) do
				local cell = world:get_cell(coord)
				if cell == nil or next(cell.entities) == nil then
					continue
				end
				local encoded_coord = coords_mod.encode_coord(coord)
				candidates[encoded_coord] = true
			end
			table.insert(selection_mode_stack, {
				type = "select_some_cell",
				candidates = candidates,
				on_selected = function(coord)
					client_interaction_remote:FireServer {
						{
							type = "ability",
							ability_type = "disguise",
							entity_id = entity.id,
							coordinate = coord,
						},
					}
				end,
			})
		end,
	})
end

function FilterButton(props: { entity_id: EntityId, LayoutOrder: number? })
	local entity = hooks.use_synced_entity(props.entity_id)
	local context = React.useContext(MainContext)

	local toggle_submenu = function(menu)
		context.set_submenu(function(current)
			return if util.deep_equal(current, menu) then {} else menu
		end)
	end

	local opened = context.submenu.type == "item_filters" and context.submenu.entity_id == props.entity_id

	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://6023426984",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(163, 255, 150),
		ImageColor3 = if opened then Color3.fromRGB(163, 255, 150) else Color3.fromRGB(200, 200, 200),
		on_click = function()
			toggle_submenu {
				type = "item_filters",
				entity_id = entity.id,
			}
		end,
	})
end

function RotateButton(props: { entity_id: EntityId, LayoutOrder: number? })
	return React.createElement(SquareActionButton, {
		Image = "rbxassetid://6031763429",
		LayoutOrder = props.LayoutOrder,
		color = Color3.fromRGB(232, 255, 26),
		on_click = function()
			client_interaction_remote:FireServer {
				{
					type = "rotate",
					entity_id = props.entity_id,
				},
			}
		end,
	})
end

return {
	AttackButton = AttackButton,
	DisguiseButton = DisguiseButton,
	FilterButton = FilterButton,
	RotateButton = RotateButton,
	DeconstructButton = DeconstructButton,
}