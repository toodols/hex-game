local registry = {}

registry.shield = {
	name = "Shield",
	-- description intentionally omitted, add if needed
}

registry.regeneration = {
	name = "Regeneration",
	description = "Gains +1 hitpoint at the start of every turn",
	desirability = "positive",
}

registry.infected = {
	name = "Infected",
	desirability = "negative",
	-- description intentionally omitted, add if needed
}

registry.hidden = {
	name = "Hidden",
	description = "This entity is hidden from the enemy",
	desirability = "positive",
}

registry.inventory_lock = {
	name = "Inventory Lock",
	description = "This entity cannot use its inventory",
	desirability = "negative",
}

registry.taunt_immunity = {
	name = "Taunt Immunity",
	description = "This entity cannot be taunted",
	desirability = "positive",
}

registry.increase_damage = {
	name = "Increase Damage",
	description = "This entity does more damage",
	desirability = "positive",
}

return {}
