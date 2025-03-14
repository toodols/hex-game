local HttpService = game:GetService "HttpService"
local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local hex_grid_mod = require(ReplicatedStorage.Shared.hex_grid)
local util = require(ReplicatedStorage.Shared.util)
local formatting = require(ReplicatedStorage.Shared.formatting)
local types = require(ReplicatedStorage.Shared.types)

local archive = require(ServerScriptService.Server.archive)
local presets = require(ServerScriptService.Server.presets)
local cleanup = require(ServerScriptService.Server.cleanup).cleanup
local action_phase_mod = require(ServerScriptService.Server.action_phase)
local entity_mod = require(ServerScriptService.Server.entity)
local damage_mod = require(ServerScriptService.Server.damage)
local effect_mod = require(ServerScriptService.Server.effect)

local assert_eq = util.assert_eq

type Entity = types.Entity
type HexGrid = types.HexGrid
type HexCell = types.HexCell
type TeamData = types.TeamData

-- spawns an entity at the first empty cell
function spawn_entity(grid: HexGrid, entity_ty: string, cell_ty: string?)
	local team = (util.table_find_pred(grid.teams, function(candidate)
		return candidate.is_player_team
	end) :: TeamData).id

	local cell = util.table_find_pred(grid.cells, function(candidate)
		return
			--can be anywhere if there are no entities yet otherwise build next to a vertex
			(
				next(grid.entities) == nil
				or util.table_any(hex_grid_mod.neighbors_eq(candidate.coordinate, 1), function(neighbor)
					return #grid:query_entity { coordinate = neighbor, type = "vertex", owner = team } > 0
				end)
			)
				-- must be on an empty cell		
				and next(candidate.entities) == nil
	end) :: HexCell

	local entity = entity_mod.new_entity({
		type = entity_ty,
		owner = team,
		primary_coordinate = cell.coordinate,
		status = "complete",
	}, grid)

	if cell_ty then
		cell.type = cell_ty
	end

	return entity
end

local tests = {}
function tests.extractor_filling_stockpile()
	-- Build the map
	local grid = presets.blank_map()
	grid.global_configuration.decaying_enabled = false

	local extractor = spawn_entity(grid, "extractor", "bar_deposit")
	local stockpile = spawn_entity(grid, "stockpile")

	for i = 1, 2 do
		action_phase_mod.run_action_phase(grid)
	end

	assert_eq(#stockpile.inventory.items, 1)

	for i = 1, 2 do
		action_phase_mod.run_action_phase(grid)
	end

	assert_eq(#stockpile.inventory.items, 2)

	stockpile.inventory.items = {}

	for i = 1, 10 do
		action_phase_mod.run_action_phase(grid)
	end

	assert_eq(#stockpile.inventory.items, stockpile.inventory.capacity)

	cleanup(grid)
end

function tests.stockpile_filters()
	local grid = presets.blank_map()
	grid.global_configuration.decaying_enabled = false

	local stockpile = spawn_entity(grid, "stockpile")
	action_phase_mod.run_action_phase(
		grid,
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
		grid,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "rad" },
		} }
	)

	assert_eq(stockpile.inventory.items, {})

	action_phase_mod.run_action_phase(
		grid,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "bar" },
		} }
	)

	assert_eq(stockpile.inventory.items, { "bar" })

	action_phase_mod.run_action_phase(
		grid,
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
		grid,
		{ {
			type = "exchange",
			entity_id = stockpile.id,
			output_items = { "bar", "rad", "pow" },
		} }
	)

	assert_eq(stockpile.inventory.items, { "rad", "pow" })

	cleanup(grid)
end

function tests.damage_scout_with_magic()
	local grid = presets.blank_map()

	local scout = spawn_entity(grid, "scout")

	damage_mod.damage_entity_destroying(grid, scout, {
		type = "physical",
		amount = 1,
	})

	assert_eq(scout.health, scout.max_health - 1, "scout should have 1 less health")

	damage_mod.damage_entity_destroying(grid, scout, {
		type = "physical",
		amount = 100,
		nonlethal = true,
	})

	assert(not scout.is_destroyed, "Nonlethal damage should not destroy the scout")

	damage_mod.damage_entity_destroying(grid, scout, {
		type = "physical",
		amount = 100,
	})

	assert(scout.is_destroyed, "Lethal damage should destroy the scout")

	cleanup(grid)
end

function tests.damage_shielded_scout_with_magic()
	local grid = presets.blank_map()

	local scout = spawn_entity(grid, "scout")
	local shield_effect = effect_mod.add_effect(scout, { type = "shield", health = 3 })
	damage_mod.damage_entity_destroying(grid, scout, { type = "physical", amount = 1 })
	assert_eq(scout.health, scout.max_health, "scout should not have been damaged")
	assert_eq(shield_effect.health, 2, "shield should have 2 health")
	damage_mod.damage_entity_destroying(grid, scout, { type = "physical", amount = 3 })
	assert(shield_effect.is_destroyed, "shield should have been destroyed")
	assert_eq(scout.health, scout.max_health - 1, "scout should have 3 less health")

	-- Reset scout hp to test with multiple shields
	scout.health = scout.max_health
	local shield_1 = effect_mod.add_effect(scout, { type = "shield", health = 3 })
	local shield_2 = effect_mod.add_effect(scout, { type = "shield", health = 3 })
	damage_mod.damage_entity_destroying(grid, scout, { type = "physical", amount = 5 })

	assert(shield_1.is_destroyed, "shield 1 should have been destroyed")
	assert(not shield_2.is_destroyed, "shield 2 should not have been destroyed")
	assert_eq(scout.health, scout.max_health, "scout should not have been damaged")

	cleanup(grid)
end

function tests.chatgpt_didnt_grift_me() -- (it did)
	local grid = hex_grid_mod.new_grid_from_extents {
		{ min = -5, max = 5 },
		{ min = -5, max = 5 },
		{ min = -5, max = 5 },
	}
	local team1 = grid:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) })
	team1.server_data.visibility = "full"

	local result = hex_grid_mod.line_of_sight(grid, { -2, 0, 2 }, { 2, 0, -2 })
	assert(result, "no blockage: expected true")
	local barrier_at_origin = entity_mod.new_entity({
		type = "barrier",
		primary_coordinate = { 0, 0, 0 },
		status = "complete",
		owner = grid.neutral_team,
	}, grid)

	local result2 = hex_grid_mod.line_of_sight(grid, { -2, 0, 2 }, { 2, 0, -2 })
	assert(not result2, "has blockage: expected false")

	local result3 = hex_grid_mod.line_of_sight(grid, { 1, 0, -1 }, { 0, -1, 1 })
	assert(result3, "expected true")

	entity_mod.new_entity({
		type = "barrier",
		primary_coordinate = { 1, -1, 0 },
		status = "complete",
		owner = grid.neutral_team,
	}, grid)

	local result4 = hex_grid_mod.line_of_sight(grid, { 1, 0, -1 }, { 0, -1, 1 })
	assert(not result4, "expected false")
	entity_mod.remove_entity(grid, barrier_at_origin)

	local result5 = hex_grid_mod.line_of_sight(grid, { 1, 0, -1 }, { 0, -1, 1 })
	assert(result5, "expected true")

	entity_mod.new_entity({
		type = "barrier",
		primary_coordinate = { 3, 0, -3 },
		status = "complete",
		owner = grid.neutral_team,
	}, grid)

	entity_mod.new_entity({
		type = "scout",
		primary_coordinate = { 1, 0, -1 },
		status = "complete",
		owner = team1.id,
	}, grid)

	for _, cell in grid.cells do
		local coord = cell.coordinate
		if not hex_grid_mod.line_of_sight(grid, { 1, 0, -1 }, coord, team1.id) then
			cell.type = "rad_deposit"
		end
	end

	cleanup(grid)
end

function tests.capture_extractor()
	local grid = hex_grid_mod.new_grid_from_extents {
		{ min = -1, max = 1 },
		{ min = -1, max = 1 },
		{ min = -1, max = 1 },
	}
	local team1 = grid:new_team({}, { type = "color3", color = Color3.new(1, 0.392156, 0.392156) })
	local extractor = entity_mod.new_entity({
		type = "extractor",
		primary_coordinate = { 0, 0, 0 },
		status = "complete",
		owner = grid.neutral_team,
	}, grid)

	local infinite_source = entity_mod.new_entity({
		type = "infinite_source",
		status = "complete",
		primary_coordinate = { -1, 1, 0 },
		owner = team1.id,
	}, grid)

	local vertex = entity_mod.new_entity({
		type = "vertex",
		primary_coordinate = { 0, 0, 0 },
		status = "blueprint",
		owner = team1.id,
	}, grid)

	action_phase_mod.run_action_phase(grid)
	assert_eq(extractor.owner, team1.id, "extractor was not captured")

	cleanup(grid)
end

function tests.stockpile_blueprint_builds()
	local grid = presets.blank_map()
	local team1 = grid:new_team()

	local extractor = entity_mod.new_entity({
		type = "extractor",
		status = "blueprint",
		primary_coordinate = { 0, 0, 0 },
		owner = team1.id,
	}, grid)

	local stockpile = entity_mod.new_entity({
		type = "stockpile",
		status = "complete",
		primary_coordinate = { -1, 0, 1 },
		owner = team1.id,
	}, grid)
	stockpile.inventory.items = { "bar", "bar", "bar", "bar", "bar" }

	action_phase_mod.run_action_phase(grid)
	assert_eq(extractor.status, "scaffold", "extractor blueprint did not become scaffold")

	action_phase_mod.run_action_phase(grid)

	assert_eq((extractor :: any).status, "complete", "extractor scaffold was not completed")

	cleanup(grid)
end

function tests.deconstruct_stockpile()
	local grid = presets.blank_map()
	local stockpile = spawn_entity(grid, "stockpile")

	table.insert(stockpile.queued_decisions, {
		type = "deconstruct",
		entity_id = stockpile.id,
	})

	action_phase_mod.run_action_phase(grid)

	assert(stockpile.is_destroyed, "stockpile should be destroyed by deconstruction")

	cleanup(grid)
end

function tests.deposit_different_items_in_vault()
	local grid = presets.blank_map()
	local vault = spawn_entity(grid, "vault")

	action_phase_mod.run_action_phase(grid, {
		{
			type = "exchange",
			entity_id = vault.id,
			output_items = { "rad", "bar" },
		},
	})

	assert_eq(#vault.inventory.items, 1, "Vault should only have 1 item")

	cleanup(grid)
end

function tests.deconstruct_building_preserves_vertex()
	local grid = presets.blank_map()
	-- Create a scout "organically"
	local scout = entity_mod.new_entity({
		type = "scout",
		status = "blueprint",
		primary_coordinate = { 0, 0, 0 },
		owner = grid.teams[3].id,
	}, grid)

	-- Feed it some items
	for i = 1, 3 do
		action_phase_mod.run_action_phase(grid, {
			{
				type = "exchange",
				entity_id = scout.id,
				output_items = { "bar" },
			},
		})
	end

	assert_eq(#grid:query_entity { type = "vertex" }, 1, "vertex not generated")
	table.insert(scout.queued_decisions, {
		type = "deconstruct",
		entity_id = scout.id,
	})
	action_phase_mod.run_action_phase(grid)
	assert_eq(#grid:query_entity { type = "vertex" }, 1, "vertex not preserved")

	cleanup(grid)
end

function tests.scout_attack_each_other()
	local grid, teams = presets.blank_map()
	local team1 = teams.team1
	local team2 = teams.team2

	entity_mod.new_entity({
		type = "infinite_source",
		status = "complete",
		primary_coordinate = { -2, 2, 0 },
		owner = team1.id,
	}, grid)
	local scout = entity_mod.new_entity({
		type = "scout",
		status = "complete",
		primary_coordinate = { -1, 1, 0 },
		owner = team1.id,
	}, grid)
	entity_mod.new_entity({
		type = "infinite_source",
		status = "complete",
		primary_coordinate = { 2, -2, 0 },
		owner = team2.id,
	}, grid)
	local scout2 = entity_mod.new_entity({
		type = "scout",
		status = "complete",
		primary_coordinate = { 1, -1, 0 },
		owner = team2.id,
	}, grid)

	table.insert(scout.queued_decisions, {
		type = "ability",
		ability_type = "scout_attack",
		coordinate = { 1, -1, 0 },
		entity_id = scout.id,
	})

	action_phase_mod.run_action_phase(grid)

	assert_eq(
		scout2.health,
		scout2.max_health - grid.entity_configurations.scout.abilities.scout_attack.damage,
		"Scout 2 should have been damaged"
	)

	-- reset scout health to full
	scout2.health = scout2.max_health

	for i = 1, 3 do
		table.insert(scout.queued_decisions, {
			type = "ability",
			ability_type = "scout_attack",
			coordinate = { 1, -1, 0 },
			entity_id = scout.id,
		})
		table.insert(scout2.queued_decisions, {
			type = "ability",
			ability_type = "scout_attack",
			coordinate = { -1, 1, 0 },
			entity_id = scout2.id,
		})
		action_phase_mod.run_action_phase(grid)
	end

	assert(scout.is_destroyed, "scout 1 should have been destroyed")
	assert(scout2.is_destroyed, "scout 2 should have been destroyed")

	cleanup(grid)
end

function tests.archive_grid()
	-- todo
	local grid = presets.my_map()
	local compressed = archive.compress_grid(grid)
	local original = HttpService:JSONEncode(grid)
	local decompressed = archive.decompress_grid(compressed)

	cleanup(grid)
end

function tests.formatting()
	assert_eq(
		formatting.format_text_raw(
			"I am {state.mood.value} because my hunger is {state.hunger}.",
			{ state = { hunger = 90, mood = { value = "unhappy" } } }
		),
		"I am unhappy because my hunger is 90."
	)
	assert_eq(
		formatting.format_text_raw("I am {condition?value}happy.", { condition = true, value = "NOT " }),
		"I am NOT happy."
	)
	assert_eq(
		formatting.format_text_raw("I am {condition?value}happy.", { condition = false, value = "NOT " }),
		"I am happy."
	)
	assert_eq(
		formatting.format_text_raw(
			"The sky is {condition?then_val:else_val}",
			{ condition = true, then_val = "blue", else_val = "red" }
		),
		"The sky is blue"
	)
	assert_eq(
		formatting.format_text_raw(
			"The sky is {condition?then_val:else_val}",
			{ condition = false, then_val = "blue", else_val = "red" }
		),
		"The sky is red"
	)
end

return tests
