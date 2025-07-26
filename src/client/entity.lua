local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Debris = game:GetService "Debris"
local coords = require(ReplicatedStorage.Shared.coords)
local types = require(ReplicatedStorage.Shared.types)

type Entity = types.Entity
type World = types.World
type HexCell = types.HexCell
type AnimationState = types.AnimationState
type EntityEvent = types.EntityEvent

local registry: { [string]: ClientEntityBehavior } = {}
type ClientEntityBehavior = {
	-- self is possibly nil so ui can create a model from entity type alone
	-- i don't like this behavior and i think a fake entity should be created instead
	model: Instance?,
	create_model: (self: Entity?, world: World) -> Instance,
	-- this happens before the model is parented to workspace
	init: (self: Entity, world: World) -> (),

	-- subset of `update`, override to replace the default built animation
	status_changed: (self: Entity, world: World, old: Entity) -> (),

	neighbor_changed: (self: Entity, world: World) -> (),

	-- called before `self` is replaced by `new` in `world`
	update: (self: Entity, world: World, old: Entity) -> (),

	on_destroy: (self: Entity, world: World, event: EntityEvent) -> (),
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
		create_model = t.create_model,
		init = t.init or function() end,
		neighbor_changed = t.neighbor_changed or function() end,

		status_changed = t.status_changed or function(self: Entity, world: World, old: Entity)
			local instance = world.entity_instance_map[self.id]
			if instance then
				for _, v in instance:GetDescendants() do
					if v:IsA "BasePart" and v.Name:find "^Hidden" == nil then
						v.Transparency = ENTITY_TRANSPARENCY[self.status]
					end
				end
			end
		end,
		on_destroy = t.on_destroy or function(self: Entity, world: World, event: EntityEvent)
			assert(event.event_type == "destroy", "Not death event")
			local instance: Instance = world.entity_instance_map[self.id]
			if instance == nil then
				warn("Can't do death for" .. self.id .. " (" .. self.type .. ") because instance not found ")
				return
			end
			world.entity_instance_map[self.id] = nil
			world.instance_entity_map[instance] = nil

			if event.death_type == "killed" then
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
			else
				instance:Destroy()
			end
		end,
		on_hidden = t.on_hidden or function(self: Entity, world: World)
			local instance: Instance = world.entity_instance_map[self.id]
			world.entity_instance_map[self.id] = nil
			if instance then
				world.instance_entity_map[instance] = nil
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

function recolor(world: World, entity: Entity, instance: Instance)
	if instance == nil then
		warn("No instance to recolor for entity " .. entity.id .. " of type " .. entity.type)
		return
	end
	local team_color = world.teams[entity.owner].color

	for _, part in instance:GetDescendants() do
		if part:IsA "BasePart" and part.Name == "Color" then
			local color: Color3 = team_color.color
			local h, s, v = color:ToHSV()
			local less_saturated = Color3.fromHSV(h, s * 0.7, v)
			part.Color = less_saturated
		end
	end
end
function create_model_from_entity(world: World, entity: Entity): Model
	local client_behavior = registry[entity.type]
	local instance
	if entity.type == "grave" then
		print "ITS A GRAVE"
	end
	if client_behavior.create_model ~= nil then
		instance = client_behavior.create_model(entity, world)
		world.entity_instance_map[entity.id] = instance
		world.instance_entity_map[instance] = entity.id
	elseif client_behavior.model ~= nil then
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
			if v:IsA "BasePart" and v.Name:find "^Hidden" == nil then
				v.Transparency = ENTITY_TRANSPARENCY[entity.status]
			end
		end
	else
		print(
			"Client entity behavior must either have .model or .create_model defined for entity type: " .. entity.type
		)
	end

	if instance ~= nil then
		recolor(world, entity, instance)
	else
		warn("No instance created for entity " .. entity.id .. " of type " .. entity.type)
	end

	return instance
end

function create_model_from_type(world: World, entity_type: string): Model
	local client_behavior = registry[entity_type]
	if not client_behavior then
		error("Unknown entity type: " .. entity_type)
	end
	if client_behavior.create_model ~= nil then
		return client_behavior.create_model(nil, world)
	elseif client_behavior.model ~= nil then
		return client_behavior.model:Clone()
	else
		error(
			"Client entity behavior must either have .model or .create_model defined for entity type: " .. entity_type
		)
	end
end

function update_entity_client(world: World, old: Entity?, new: Entity)
	local client_behavior = registry[new.type]
	if not client_behavior then
		error("Unknown entity type: " .. new.type)
	end
	-- if new.is_destroyed then
	-- 	return
	-- end
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

		if instance ~= nil then
			recolor(world, new, instance)
			instance:PivotTo(
				(cell_instance.Base.CFrame + Vector3.new(0, cell_instance.Base.Size.Y / 2, 0))
					* CFrame.Angles(0, math.pi / 3 * new.rotation, 0)
			)
		end

		if old.status ~= new.status and not new.is_destroyed then
			registry[old.type].status_changed(new, world, old)
		end
	else
		local instance: Model = create_model_from_entity(world, new)
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

return {
	registry = registry,
	ENTITY_TRANSPARENCY = ENTITY_TRANSPARENCY,
	update_entity_client = update_entity_client,
	create_model_from_entity = create_model_from_entity,
	create_model_from_type = create_model_from_type,
	with_defaults = with_defaults,
}
