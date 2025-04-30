local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Debris = game:GetService "Debris"
local coords = require(ReplicatedStorage.Shared.coords)
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type AnimationState = types.AnimationState

local registry: { [string]: ClientEntityBehavior } = {}
type ClientEntityBehavior = {
	-- self is possibly nil so ui can create a model from entity type alone
	-- i don't like this behavior and i think a fake entity should be created instead
	model: Instance | (self: Entity?, world: World) -> Instance,

	-- this happens before the model is parented to workspace
	init: (self: Entity, world: World) -> (),

	-- subset of `update`, override to replace the default built animation
	status_changed: (self: Entity, world: World, old: Entity) -> (),

	neighbor_changed: (self: Entity, world: World) -> (),

	-- called before `self` is replaced by `new` in `world`
	update: (self: Entity, world: World, old: Entity) -> (),

	on_destroy: (self: Entity, world: World) -> (),
	on_hidden: (self: Entity, world: World) -> (),

	animate: ((self: Entity, world: World, animation_state: AnimationState) -> ())?,

	-- turn_start: (self: Entity, world: World, cell: HexCell) -> (),
}

local ENTITY_TRANSPARENCY = {
	blueprint = 0.7,
	scaffold = 0.3,
	complete = 0,
}

function with_defaults(t: any)
	return {
		model = t.model,
		init = t.init or function() end,
		neighbor_changed = t.neighbor_changed or function() end,

		status_changed = t.status_changed or function(self: Entity, world: World, old: Entity)
			local instance = world.entity_instance_map[self.id]
			if instance then
				for _, v in instance:GetDescendants() do
					if v:IsA "BasePart" then
						v.Transparency = ENTITY_TRANSPARENCY[self.status]
					end
				end
			end
		end,
		on_destroy = t.on_destroy or function(self: Entity, world: World)
			local instance: Instance = world.entity_instance_map[self.id]
			if instance then
				world.entity_instance_map[self.id] = nil
				for _, part in instance:GetDescendants() do
					if not part:IsA "BasePart" then
						continue
					end
					part.Anchored = false
					part.CanCollide = false
					part:ApplyImpulse(part:GetMass() * Vector3.new(math.random(-30, 30), 60, math.random(-30, 30)))
					Debris:AddItem(part, 1)
					task.wait(0.1)
				end
				instance:Destroy()
			end
		end,
		on_hidden = t.on_hidden or function(self: Entity, world: World)
			local instance: Instance = world.entity_instance_map[self.id]
			world.entity_instance_map[self.id] = nil
			if instance then
				instance:Destroy()
			end
		end,
		animate = t.animate,
		update = t.update or function(self: Entity, world: World, old: Entity)
			if self.type ~= self.type then
				-- oh no
			end
			-- if not util.deep_equal(self.queued_decisions, self.queued_decisions) then
			-- 	if
			-- 		util.table_find_pred(self.queued_decisions, function(action)
			-- 			return action.type == "deconstruct"
			-- 		end)
			-- 	then
			-- 	end
			-- end
		end,
	}
end

function create_model_from_entity(world: World, entity: Entity): Model
	local client_behavior = registry[entity.type]
	local instance
	if type(client_behavior.model) == "function" then
		instance = client_behavior.model(entity, world)
	else
		instance = client_behavior.model:Clone()
		local cell_instance = world.cell_instance_map[coords.encode_coord(entity.primary_coordinate)]
		instance:PivotTo(
			(cell_instance.Base.CFrame + Vector3.new(0, cell_instance.Base.Size.Y / 2, 0))
				* CFrame.Angles(0, math.pi / 3 * entity.rotation, 0)
		)
		world.entity_instance_map[entity.id] = instance
		world.instance_entity_map[instance] = entity.id
		if instance:IsA "BasePart" then
			instance.Transparency = ENTITY_TRANSPARENCY[entity.status]
		end
		for _, v in instance:GetDescendants() do
			if v:IsA "BasePart" then
				v.Transparency = ENTITY_TRANSPARENCY[entity.status]
			end
		end
	end

	return instance
end

function create_model_from_type(world: World, entity_type: string): Model
	local client_behavior = registry[entity_type]
	if not client_behavior then
		error("Unknown entity type: " .. entity_type)
	end
	if type(client_behavior.model) == "function" then
		return client_behavior.model(nil, world)
	else
		return client_behavior.model:Clone()
	end
end

function update_entity_client(world: World, old: Entity?, new: Entity)
	print("begin update_entity_client", new.type, "instance", world.entity_instance_map[new.id])
	local client_behavior = registry[new.type]
	if not client_behavior then
		error("Unknown entity type: " .. new.type)
	end
	if new.is_destroyed then
		client_behavior.on_destroy(new, world)
		for _, coord in new.coordinates do
			local cell = world:get_cell(coord)
			cell.entities[new.id] = nil
		end
	else
		if old then
			local instance = world.entity_instance_map[new.id]
			local cell_instance = world.cell_instance_map[coords.encode_coord(new.primary_coordinate)]
			-- type changed. destroy old one and swap in with new
			if old.type ~= new.type then
				instance:Destroy()
				instance = create_model_from_entity(world, new)
				client_behavior.init(new, world)
				instance.Parent = world.entity_instance_root
			end
			client_behavior.update(new, world, old)
			instance:PivotTo(
				(cell_instance.Base.CFrame + Vector3.new(0, cell_instance.Base.Size.Y / 2, 0))
					* CFrame.Angles(0, math.pi / 3 * new.rotation, 0)
			)
			if old.status ~= new.status and not new.is_destroyed and instance then
				registry[old.type].status_changed(new, world, old)
			end
		else
			local instance: Model
			if client_behavior.model then
				instance = create_model_from_entity(world, new)
			end
			for _, coord in new.coordinates do
				local cell = world:get_cell(coord)
				if cell.entities[new.id] == nil then
					cell.entities[new.id] = true
				end
			end
			client_behavior.init(new, world)

			if instance then
				instance.Parent = world.entity_instance_root
			end
		end
	end
	print("end update_entity_client", new.type)
end

return {
	registry = registry,
	ENTITY_TRANSPARENCY = ENTITY_TRANSPARENCY,
	update_entity_client = update_entity_client,
	create_model_from_entity = create_model_from_entity,
	create_model_from_type = create_model_from_type,
	with_defaults = with_defaults,
}
