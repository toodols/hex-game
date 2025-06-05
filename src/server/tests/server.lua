local HttpService = game:GetService "HttpService"
local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local world_mod = require(ReplicatedStorage.Shared.world)
local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)
local coords = require(ReplicatedStorage.Shared.coords)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)

local archive = require(ServerScriptService.Server.archive)
local presets = require(ServerScriptService.Server.presets)
local cleanup = require(ServerScriptService.Server.cleanup).cleanup
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local damage_mod = require(ServerScriptService.Server.damage)
local presence_mod = require(ServerScriptService.Server.presence)
local effect_mod = require(ServerScriptService.Server.effect)
local entity_mod = require(ServerScriptService.Server.entity)
local router = require(ServerScriptService.Server.router)
local visibility_mod = require(ServerScriptService.Server.visibility)
local influences_mod = require(ServerScriptService.Server.influences)
local turn_scheduler_init = require(ServerScriptService.Server.turn_scheduler_init)
local turn_scheduler = require(ServerScriptService.Server.turn_scheduler)

local assert_eq = util.assert_eq

type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type TeamData = types.TeamData

-- spawns an entity at the first empty cell
function spawn_entity(world: World, entity_ty: string, cell_ty: string?)
	local team = (util.table_find_pred(world.teams, function(candidate)
		return candidate.is_player_team
	end) :: TeamData).id

	local cell = util.table_find_pred(world.cells, function(candidate)
		return
			--can be anywhere if there are no entities yet otherwise build next to a vertex
			(
				next(world.entities) == nil
				or util.table_any(coords.neighbors_eq(candidate.coordinate, 1), function(neighbor)
					return #world:query_entity { coordinate = neighbor, type = "vertex", owner = team } > 0
				end)
			)
				-- must be on an empty cell		
				and next(candidate.entities) == nil
	end) :: HexCell

	local entity = entity_mod.new_entity({
		type = entity_ty,
		owner = team,
		primary_coordinate = cell.coordinate,
	}, world)

	if cell_ty then
		cell.type = cell_ty
	end

	return entity
end

local tests = {}
function tests.extractor_filling_stockpile()
	-- Build the map
	local world = presets.blank_map()
	world.global_configuration.decaying_enabled = false

	local extractor = spawn_entity(world, "extractor", "bar_deposit")
	local stockpile = spawn_entity(world, "stockpile")

	for i = 1, 2 do
		action_phase_mod.run_action_phase(world)
	end

	assert_eq(#stockpile.inventory.items, 1)

	for i = 1, 2 do
		action_phase_mod.run_action_phase(world)
	end

	assert_eq(#stockpile.inventory.items, 2)

	stockpile.inventory.items = {}

	for i = 1, 10 do
		action_phase_mod.run_action_phase(world)
	end

	assert_eq(#stockpile.inventory.items, stockpile.inventory.capacity)

	cleanup(world)
end

function tests.stockpile_filters()
	local world = presets.blank_map()
	world.global_configuration.decaying_enabled = false

	local stockpile = spawn_entity(world, "stockpile")
	action_phase_mod.run_action_phase(
		world,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "bar" },
		} }
	)

	assert_eq(stockpile.inventory.items, { "bar" })

	stockpile.inventory.items = {}

	stockpile.inventory.filter = {
		type = "whitelist",
		items = { ["bar"] = true },
	}
	action_phase_mod.run_action_phase(
		world,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "rad" },
		} }
	)

	assert_eq(stockpile.inventory.items, {})

	action_phase_mod.run_action_phase(
		world,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "bar" },
		} }
	)

	assert_eq(stockpile.inventory.items, { "bar" })

	action_phase_mod.run_action_phase(
		world,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "bar", "rad", "pow" },
		} }
	)

	assert_eq(stockpile.inventory.items, { "bar", "bar" })

	stockpile.inventory.items = {}
	stockpile.inventory.filter = {
		type = "blacklist",
		items = { ["bar"] = true },
	}
	action_phase_mod.run_action_phase(
		world,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "bar", "rad", "pow" },
		} }
	)

	assert_eq(stockpile.inventory.items, { "rad", "pow" })

	cleanup(world)
end

function tests.damage_scout_with_magic()
	local world = presets.blank_map()

	local scout = spawn_entity(world, "scout")

	damage_mod.damage_entity_destroying(world, scout, {
		amount = 1,
	})

	assert_eq(scout.health, scout.max_health - 1, "scout should have 1 less health")

	damage_mod.damage_entity_destroying(world, scout, {
		amount = 100,
		nonlethal = true,
	})

	assert(not scout.is_destroyed, "Nonlethal damage should not destroy the scout")

	damage_mod.damage_entity_destroying(world, scout, {
		amount = 100,
	})

	assert(scout.is_destroyed, "Lethal damage should destroy the scout")

	cleanup(world)
end

function tests.damage_shielded_scout_with_magic()
	local world = presets.blank_map()

	local scout = spawn_entity(world, "scout")
	local shield_effect = effect_mod.add_effect(world, scout, { type = "shield", health = 3 })
	damage_mod.damage_entity_destroying(world, scout, { amount = 1 })
	assert_eq(scout.health, scout.max_health, "scout should not have been damaged")
	assert_eq(shield_effect.health, 2, "shield should have 2 health")
	damage_mod.damage_entity_destroying(world, scout, { amount = 3 })
	assert(shield_effect.is_destroyed, "shield should have been destroyed")
	assert_eq(scout.health, scout.max_health - 1, "scout should have 3 less health")

	-- Reset scout hp to test with multiple shields
	scout.health = scout.max_health
	local shield_1 = effect_mod.add_effect(world, scout, { type = "shield", health = 3 })
	local shield_2 = effect_mod.add_effect(world, scout, { type = "shield", health = 3 })
	damage_mod.damage_entity_destroying(world, scout, { amount = 5 })

	assert(shield_1.is_destroyed, "shield 1 should have been destroyed")
	assert(not shield_2.is_destroyed, "shield 2 should not have been destroyed")
	assert_eq(scout.health, scout.max_health, "scout should not have been damaged")

	cleanup(world)
end

function tests.chatgpt_didnt_grift_me() -- (it did)
	local world = world_mod.new_world_from_extents {
		{ min = -5, max = 5 },
		{ min = -5, max = 5 },
		{ min = -5, max = 5 },
	}
	local team1 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) })
	team1.server_data.visibility = "perfect"

	local result = world_mod.line_of_sight(world, { -2, 0, 2 }, { 2, 0, -2 })
	assert(result, "no blockage: expected true")
	local barrier_at_origin = entity_mod.new_entity({
		type = "barrier",
		primary_coordinate = { 0, 0, 0 },
		owner = world.neutral_team,
	}, world)

	local result2 = world_mod.line_of_sight(world, { -2, 0, 2 }, { 2, 0, -2 })
	assert(not result2, "has blockage: expected false")

	local result3 = world_mod.line_of_sight(world, { 1, 0, -1 }, { 0, -1, 1 })
	assert(result3, "expected true")

	entity_mod.new_entity({
		type = "barrier",
		primary_coordinate = { 1, -1, 0 },
		owner = world.neutral_team,
	}, world)

	local result4 = world_mod.line_of_sight(world, { 1, 0, -1 }, { 0, -1, 1 })
	assert(not result4, "expected false")
	entity_mod.remove_entity(world, barrier_at_origin)

	local result5 = world_mod.line_of_sight(world, { 1, 0, -1 }, { 0, -1, 1 })
	assert(result5, "expected true")

	entity_mod.new_entity({
		type = "barrier",
		primary_coordinate = { 3, 0, -3 },
		owner = world.neutral_team,
	}, world)

	entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 1, 0, -1 },
		owner = team1.id,
	}, world)

	for _, cell in world.cells do
		local coord = cell.coordinate
		if not world_mod.line_of_sight(world, { 1, 0, -1 }, coord, team1.id) then
			cell.type = "rad_deposit"
		end
	end

	cleanup(world)
end

function tests.decaying()
	local world, teams = presets.my_map()

	local heart = (world:query_entity { type = "heart", query_global = true, owner = teams.team1.id })[1]
	table.insert(heart.queued_decisions, {
		type = "deconstruct",
	})
	local scout = world:query_entity({ type = "scout", query_global = true, owner = teams.team1.id })[1]

	for i = 1, 4 do
		action_phase_mod.run_action_phase(world)
	end

	assert(scout.owner == world.neutral_team, "scout should be neutral team after decaying")

	cleanup(world)
end

function tests.capture_extractor()
	local world = world_mod.new_world_from_extents {
		{ min = -1, max = 1 },
		{ min = -1, max = 1 },
		{ min = -1, max = 1 },
	}
	local team1 = world_mod.new_team(world, {}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) })
	local extractor = entity_mod.new_entity({
		type = "extractor",
		primary_coordinate = { 0, 0, 0 },
		owner = world.neutral_team,
	}, world)

	local infinite_source = entity_mod.new_entity({
		type = "infinite_source",
		primary_coordinate = { -1, 1, 0 },
		owner = team1.id,
	}, world)

	local vertex = entity_mod.new_entity({
		type = "vertex",
		primary_coordinate = { 0, 0, 0 },
		status = "blueprint",
		owner = team1.id,
	}, world)

	action_phase_mod.run_action_phase(world)
	assert_eq(extractor.owner, team1.id, "extractor was not captured")

	cleanup(world)
end

function tests.stockpile_blueprint_builds()
	local world = presets.blank_map()
	local team1 = world_mod.new_team(world)

	local extractor = entity_mod.new_entity({
		type = "extractor",
		status = "blueprint",
		primary_coordinate = { 0, 0, 0 },
		owner = team1.id,
	}, world)

	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		primary_coordinate = { -1, 0, 1 },
		owner = team1.id,
	}, world)
	stockpile.inventory.items = { "bar", "bar", "bar", "bar", "rad" }

	action_phase_mod.run_action_phase(world)
	assert_eq(extractor.status, "scaffold", "extractor blueprint did not become scaffold")

	action_phase_mod.run_action_phase(world)

	assert_eq((extractor :: any).status, "complete", "extractor scaffold was not completed")

	cleanup(world)
end

function tests.deconstruct_stockpile()
	local world = presets.blank_map()
	local stockpile = spawn_entity(world, "stockpile")

	table.insert(stockpile.queued_decisions, {
		type = "deconstruct",
	})

	action_phase_mod.run_action_phase(world)

	assert(stockpile.is_destroyed, "stockpile should be destroyed by deconstruction")

	cleanup(world)
end

function tests.factory_creates_items()
	local world = presets.blank_map()
	local factory = spawn_entity(world, "factory")
	local rad_stockpile = spawn_entity(world, "stockpile")
	rad_stockpile.inventory.items = { "rad", "rad", "rad", "rad", "rad" }
	rad_stockpile.inventory.filter = {
		type = "whitelist",
		items = { ["rad"] = true },
	}
	local bar_stockpile = spawn_entity(world, "stockpile")
	bar_stockpile.inventory.items = { "bar", "bar", "bar", "bar", "bar" }
	bar_stockpile.inventory.filter = {
		type = "whitelist",
		items = { ["bar"] = true },
	}
	local pow_stockpile = spawn_entity(world, "stockpile")
	pow_stockpile.inventory.items = { "pow" }
	pow_stockpile.inventory.filter = {
		type = "whitelist",
		items = { ["pow"] = true },
	}

	factory.current_recipe = "rad_to_pow"

	action_phase_mod.run_action_phase(world)

	assert_eq(#pow_stockpile.inventory.items, 3, "pow stockpile should have 3 item")
	assert_eq(pow_stockpile.inventory.items[1], "pow", "stockpile should have pow")
	assert_eq(#rad_stockpile.inventory.items, 4, "rad stockpile should have 4 items")
	assert_eq(#bar_stockpile.inventory.items, 4, "bar stockpile should have 4 items")

	action_phase_mod.run_action_phase(world)

	assert_eq(#pow_stockpile.inventory.items, 5, "pow stockpile should have 5 items")
	assert_eq(#rad_stockpile.inventory.items, 3, "rad stockpile should have 1 items")
	assert_eq(#bar_stockpile.inventory.items, 3, "bar stockpile should have 1 items")

	-- it is unfeasible to make factory *not* run when there is no room for the output.
	-- so rad+bar being consumed to make nothing is intended behavior
	-- maybe this will change in the future
	action_phase_mod.run_action_phase(world)

	assert_eq(#pow_stockpile.inventory.items, 5, "pow stockpile should have 5 items")
	assert_eq(#rad_stockpile.inventory.items, 2, "rad stockpile should have 1 items")
	assert_eq(#bar_stockpile.inventory.items, 2, "bar stockpile should have 1 items")
end

function tests.deposit_different_items_in_vault()
	local world = presets.blank_map()
	local vault = spawn_entity(world, "vault")

	action_phase_mod.run_action_phase(world, {
		{
			type = "exchange",
			entity_id = vault.id,
			output_items = { "rad", "bar" },
		},
	})

	assert_eq(#vault.inventory.items, 1, "Vault should only have 1 item")
	assert_eq(vault.inventory.items[1], "rad", "Vault should have rad")

	cleanup(world)
end

function tests.deconstruct_building_preserves_vertex()
	local world, teams = presets.blank_map()
	-- Create a scout "organically"
	local scout = entity_mod.new_entity({
		type = "scout",
		status = "blueprint",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
	}, world)

	-- Feed it some items
	for i = 1, 3 do
		action_phase_mod.run_action_phase(world, {
			{
				type = "exchange",
				entity_id = scout.id,
				output_items = { "bar" },
			},
		})
	end

	assert_eq(#world:query_entity { type = "vertex", coordinate = { 0, 0, 0 } }, 1, "vertex not generated")
	table.insert(scout.queued_decisions, {
		type = "deconstruct",
	})
	action_phase_mod.run_action_phase(world)
	assert_eq(#world:query_entity { type = "vertex", coordinate = { 0, 0, 0 } }, 1, "vertex not preserved")

	cleanup(world)
end

function tests.scout_attack_each_other()
	local world, teams = presets.blank_map()
	local team1 = teams.team1
	local team2 = teams.team2

	entity_mod.new_entity({
		type = "infinite_source",
		primary_coordinate = { -2, 2, 0 },
		owner = team1.id,
	}, world)
	local scout = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { -1, 1, 0 },
		owner = team1.id,
	}, world)
	entity_mod.new_entity({
		type = "infinite_source",
		primary_coordinate = { 2, -2, 0 },
		owner = team2.id,
	}, world)
	local scout2 = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 1, -1, 0 },
		owner = team2.id,
	}, world)

	table.insert(scout.queued_decisions, {
		type = "ability",
		ability_type = "attack",
		coordinate = { 1, -1, 0 },
	})

	action_phase_mod.run_action_phase(world)

	assert_eq(
		scout2.health,
		scout2.max_health - world.entity_configurations.scout.abilities.attack.damage.amount,
		"Scout 2 should have been damaged"
	)

	-- reset scout health to full
	scout2.health = scout2.max_health

	for i = 1, 3 do
		table.insert(scout.queued_decisions, {
			type = "ability",
			ability_type = "attack",
			coordinate = { 1, -1, 0 },
		})
		table.insert(scout2.queued_decisions, {
			type = "ability",
			ability_type = "attack",
			coordinate = { -1, 1, 0 },
		})
		action_phase_mod.run_action_phase(world)
	end

	assert(scout.is_destroyed, "scout 1 should have been destroyed")
	assert(scout2.is_destroyed, "scout 2 should have been destroyed")

	cleanup(world)
end

function tests.correct_phony_updates()
	local world, teams = presets.blank_map()
	world.global_configuration.decaying_enabled = false

	local phony =
		entity_mod.new_entity({ type = "phony", owner = teams.team2.id, primary_coordinate = { 0, 0, 0 } }, world)
	local disguise_target =
		entity_mod.new_entity({ type = "stockpile", owner = teams.team2.id, primary_coordinate = { 1, 0, -1 } }, world)

	local enemy =
		entity_mod.new_entity({ type = "scout", owner = teams.team1.id, primary_coordinate = { -2, 0, 2 } }, world)

	table.insert(phony.queued_decisions, {
		type = "ability",
		ability_type = "disguise",
		coordinate = disguise_target.primary_coordinate,
	})

	local result = action_phase_mod.run_action_phase(world)

	assert(
		util.table_any(result.updates[teams.team1.id], function(update)
			return update.type == "entity_update"
				and update.entity.id == phony.disguise
				and update.entity.active == true
		end),
		"Disguise should be visible to enemy team"
	)

	assert(not util.table_any(result.updates[teams.team1.id], function(update)
		return update.type == "entity_update" and update.entity.id == phony.id
	end), "Phony should not be visible to enemy team")

	assert(
		util.table_any(result.updates[teams.team2.id], function(update)
			return update.type == "entity_update"
				and update.entity.id == phony.disguise
				and update.entity.active == false
		end),
		"Disguise should be visible but not active to phony's team"
	)

	cleanup(world)
end

function tests.archive_world()
	-- todo
	local world = presets.my_map()
	local compressed = archive.serialize_world(world)
	local as_json = HttpService:JSONEncode(world)
	print("World saved as", #compressed, "bytes")
	print(("Is %d%% of JSON size"):format(math.floor(#compressed / #as_json * 100)))
	local decompressed = archive.deserialize_world(compressed)
	print(decompressed)
	cleanup(world)
end

-- a visible scout firing should be have its ability usage be visible to the team
function tests.correct_scout_updates()
	local world, teams = presets.blank_map()
	spawn_entity(world, "infinite_source")
	local scout = spawn_entity(world, "scout")
	table.insert(scout.queued_decisions, {
		type = "ability",
		ability_type = "attack",
		coordinate = { 1, -1, 0 },
	})

	local result = action_phase_mod.run_action_phase(world)
	assert(
		util.table_any(result.updates[teams.team1.id], function(update)
			return update.type == "ability"
		end),
		"Did not find ability in updates for team1"
	)

	cleanup(world)
end

function tests.deconstructing_heart_doesnt_produce_item()
	local world, teams = presets.my_map()
	local heart = world:query_entity({ type = "heart", query_global = true, owner = teams.team1.id })[1]
	table.insert(heart.queued_decisions, {
		type = "deconstruct",
	})

	local result = action_phase_mod.run_action_phase(world)
	local updates = result.updates[teams.team1.id]

	assert(not util.table_any(updates, function(update)
		return update.type == "entity_event" and update.entity_id == heart.id and update.event_type == "produced_items"
	end), "Heart should not produce item on deconstruction")
	cleanup(world)
end

function tests.no_blueprint_item_stealing()
	local world, teams = presets.blank_map()
	local cache = entity_mod.new_entity({
		type = "stockpile",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
	}, world)
	cache.inventory.items = { "vit", "vit", "vit", "vit", "vit" }

	local solution = entity_mod.new_entity({
		type = "solution",
		primary_coordinate = { 1, -1, 0 },
		owner = teams.team2.id,
		status = "blueprint",
	}, world)

	local _result = action_phase_mod.run_action_phase(world)
	-- local updates = result.updates[teams.team2.id]
	assert_eq(solution.status, "blueprint", "solution should not be built")
	cleanup(world)
end

function tests.deconstruct_scaffold_with_autogenerated_wires()
	local world, teams = presets.blank_map()
	local scout_behavior = shared_entity_mod.registry.scout
	entity_mod.new_entity({
		type = "infinite_source",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
	}, world)

	local scout = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 1, -1, 0 },
		owner = teams.team1.id,
		status = "blueprint",
	}, world)
	local vertex = world:query_entity({ coordinate = scout.primary_coordinate, type = "vertex" })[1]

	action_phase_mod.run_action_phase(world)
	assert_eq(scout.status, "scaffold", "scout should be scaffold")
	assert_eq(vertex.status, "complete", "vertex should be complete")

	for i = 1, scout_behavior.build_time do
		action_phase_mod.run_action_phase(world)
	end

	assert_eq(scout.status, "complete", "scout should be complete")
	cleanup(world)
end

function tests.proxy()
	local world, teams = presets.blank_map(5)
	world.global_configuration.decaying_enabled = false
	local laboratory = entity_mod.new_entity({
		type = "laboratory",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
	}, world)
	laboratory.researches.states.heart.status = "complete"

	local heart = entity_mod.new_entity({
		type = "heart",
		primary_coordinate = { 5, -5, 0 },
		owner = teams.team1.id,
		status = "blueprint",
	}, world)

	local _infinite_source = entity_mod.new_entity({
		type = "infinite_source",
		primary_coordinate = { 3, -3, 0 },
		owner = teams.team1.id,
	}, world)

	action_phase_mod.run_action_phase(world)
	assert_eq(heart.status, "blueprint", "heart should be blueprint")

	local _proxy = entity_mod.new_entity({
		type = "proxy",
		primary_coordinate = { 4, -4, 0 },
		owner = teams.team1.id,
	}, world)

	action_phase_mod.run_action_phase(world)
	assert_eq(heart.status, "scaffold", "heart should be scaffold")
	cleanup(world)
end

function tests.taunt_chain_reaction()
	local world, teams = presets.blank_map()
	local taunt1 = entity_mod.new_entity({
		type = "taunt",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
		health = 1,
	}, world)

	local taunt2 = entity_mod.new_entity({
		type = "taunt",
		primary_coordinate = { 1, -1, 0 },
		owner = teams.team1.id,
		health = 1,
	}, world)

	local taunt3 = entity_mod.new_entity({
		type = "taunt",
		primary_coordinate = { 2, -2, 0 },
		owner = teams.team1.id,
		health = 1,
	}, world)

	local scout = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { -1, 1, 0 },
		owner = teams.team2.id,
	}, world)

	local infinite_source = entity_mod.new_entity({
		type = "infinite_source",
		primary_coordinate = { -2, 2, 0 },
		owner = teams.team2.id,
	}, world)

	table.insert(scout.queued_decisions, {
		type = "ability",
		ability_type = "attack",
		coordinate = { 0, 0, 0 },
	})

	action_phase_mod.run_action_phase(world)
	assert_eq(taunt1.health, 0, "taunt1 should be dead")
	assert_eq(taunt2.health, 0, "taunt2 should be dead")
	assert_eq(taunt3.health, 0, "taunt3 should be dead")
	cleanup(world)
end

function tests.deconstruct_interaction_gives_destroy_events()
	local world, teams = presets.blank_map()
	local scout = entity_mod.new_entity({
		type = "scout",
		status = "blueprint",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
	}, world)
	local result = router.on_client_interaction(
		world,
		{ player_team = teams.team1, data = { {
			type = "deconstruct",
			entity_id = scout.id,
		} } }
	)
	assert_eq(
		util.table_any(result.updates[teams.team1.id], function(update)
			return update.type == "entity_event"
				and update.entity_id == scout.id
				and update.event_type == "destroy"
				and update.death_type == "deconstruct"
		end),
		true,
		"Scout should be destroyed"
	)
	cleanup(world)
end

function tests.phony_generates_tek_on_death()
	local world, teams = presets.blank_map()
	world.global_configuration.decaying_enabled = false
	local scout = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team2.id,
	}, world)

	local stockpile_ammo = entity_mod.new_entity({
		type = "stockpile",
		primary_coordinate = { -1, 1, 0 },
		owner = teams.team2.id,
	}, world)
	stockpile_ammo.inventory.items = { "bar" }

	local phony = entity_mod.new_entity({
		type = "phony",
		primary_coordinate = { 2, -2, 0 },
		owner = teams.team1.id,
	}, world)

	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		primary_coordinate = { 3, -3, 0 },
		owner = teams.team1.id,
	}, world)

	table.insert(phony.queued_decisions, {
		type = "ability",
		ability_type = "disguise",
		coordinate = scout.primary_coordinate,
	})

	action_phase_mod.run_action_phase(world)

	assert(phony.disguise ~= nil, "Phony should be disguised")

	table.insert(scout.queued_decisions, {
		type = "ability",
		ability_type = "attack",
		coordinate = phony.primary_coordinate,
	})

	action_phase_mod.run_action_phase(world)
	assert(phony.is_destroyed, "Phony should be destroyed")

	assert_eq(stockpile.inventory.items, { "tek" })
	cleanup(world)
end

function tests.visibility_change_gets_entity_update()
	local world, teams = presets.blank_map()
	world.global_configuration.decaying_enabled = false
	local scout = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
	}, world)

	action_phase_mod.run_action_phase(world)

	teams.team2.server_data.visibility = "fogless"
	local result = action_phase_mod.run_action_phase(world)
	assert(
		util.table_any(result.updates[teams.team2.id], function(update)
			return update.type == "entity_update" and update.entity.id == scout.id
		end),
		"Did not get an entity_update for scout"
	)
	cleanup(world)
end

function tests.lose_visibility_when_lose_entity()
	local world, teams = presets.blank_map()
	local entity = entity_mod.new_entity({
		type = "vertex",
		primary_coordinate = { 0, 0, 0 },
		owner = teams.team1.id,
	}, world)
	local cell = world:get_cell { 0, 0, 0 } :: HexCell

	action_phase_mod.run_action_phase(world)
	assert(visibility_mod.cell_visibility(cell.server_data.visibility[teams.team1.id]), "cell should be visible")

	entity_mod.remove_entity(world, entity)
	action_phase_mod.run_action_phase(world)
	assert(
		not visibility_mod.cell_visibility(cell.server_data.visibility[teams.team1.id]),
		"cell should not be visible"
	)
	cleanup(world)
end

function tests.weird_presence_after_load()
	local world, teams = presets.my_map()
	local bin = archive.serialize_world(world)
	local data = archive.deserialize_world(bin)
	turn_scheduler.turn_schedule_kill(world.turn_schedule)
	world_mod.apply_world_data(world, data)
	turn_scheduler_init.hydrate(world, world.turn_schedule)
	influences_mod.compute_influences(world)
	presence_mod.compute_presence(world)
	visibility_mod.compute_visibility(world)
	assert(next((world:get_cell { 0, 0, 0 }).server_data.presence) == nil, "There should be no presence on center tile")

	action_phase_mod.run_action_phase(world)
	cleanup(world)
end

function tests.heart_produces_rad()
	local world, teams = presets.blank_map()
	local heart = spawn_entity(world, "heart")
	local stockpile = spawn_entity(world, "stockpile")
	heart.researches.states.create_rad.status = "complete"
	assert_eq(#stockpile.inventory.items, 0)
	local result = action_phase_mod.run_action_phase(world)
	assert(
		util.table_any(stockpile.inventory.items, function(item)
			return item == "rad"
		end),
		"Stockpile should have rad"
	)
end

function tests.infected_effect()
	local world, teams = presets.blank_map()
	world.global_configuration.decaying_enabled = false

	local scout0 = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 0, 0, 0 },
	}, world)

	local scout1 = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 1, 0, -1 },
	}, world)

	local scout2 = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 2, 0, -2 },
	}, world)

	local scout3 = entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 3, 0, -3 },
	}, world)

	effect_mod.add_effect(world, scout0, { type = "infected", duration = 1 })
	assert_eq(scout0.health, 2)
	assert_eq(scout1.health, 3)

	action_phase_mod.run_action_phase(world)
	assert_eq(scout1.health, 2)
	assert_eq(scout2.health, 3)

	action_phase_mod.run_action_phase(world)
	assert_eq(scout2.health, 2)
	assert_eq(scout3.health, 3)

	action_phase_mod.run_action_phase(world)
	assert_eq(scout0.health, 2)
	assert_eq(scout1.health, 2)
	assert_eq(scout2.health, 2)
	assert_eq(scout3.health, 2)
	cleanup(world)
end

return tests
