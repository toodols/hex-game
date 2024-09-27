local tutorial_stages = {
	init = {
		messages = {
			"Welcome to the tutorial.",
			"Before you are two buildings, a {entity.extractor} and a {entity.stockpile}.",
			"The {entity.extractor} creates items while the {entity.stockpile} stores items",
			"You can connect them with a {entity.wires}.",
			"Select (0, 0, 0) by clicking on the tile.",
		},
		next = "build_wires_on_tile",
		effects = {
			{ type = "highlight_cell", coordinate = { 0, 0, 0 } },
		},
	},
	build_wires_on_tile = {
		messages = {
			"Press the build button, and select {entity.wires}.",
		},
		effects = {
			{ type = "highlight_build_button" },
			{ type = "highlight_buildable", entity_type = "wires" },
		},
		next = "complete_wires_blueprint",
	},
	complete_wires_blueprint = {
		messages = {
			"Right now, the {entity.wires} is a blueprint. Let's advance forward 1 turn",
		},
		can_advance = true,
		next = "build_wires_blueprint",
	},
	build_wires_blueprint = {
		next = "entities_are_connected",
	},
	entities_are_connected = {
		messages = {
			"The buildings are now connected. Every turn this extractor will generate one item.",
			"Let's advance a few turns so the stockpile fills up.",
		},
		can_advance = true,
		next = "resource_is_bar",
	},
	resource_is_bar = {
		messages = {
			"This gray resource is called {item.bar}.",
			"But it isn't the only resource. Let's obtain {item.rad}",
		},
	},
}

return {
	tutorial_stages = tutorial_stages,
}
