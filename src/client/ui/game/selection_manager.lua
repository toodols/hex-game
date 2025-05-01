local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"
local ContextActionService = game:GetService "ContextActionService"

local util = require(ReplicatedStorage.Shared.util)
local coords = require(ReplicatedStorage.Shared.coords)
local types = require(ReplicatedStorage.Shared.types)
local ui_types = require(ReplicatedStorage.Client.ui.types)

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type World = types.World
type EncodedCoordinate = types.EncodedCoordinate
type SelectionMode = ui_types.SelectionMode

type SelectionManager = {
	cursor_instance: Instance?,
	shift_select_type: "drag_include" | "drag_exclude" | "drag_unknown" | "off",
	cell_instances_select: Model,
	cell_instances_hover: Model,
	hover_highlight: Highlight,
	selected_highlight: Highlight,
	selection_mode_stack: { SelectionMode },
	cursor_coordinate: EncodedCoordinate?,
}

function new_selection_manager(world: World): SelectionManager
	local cell_instances_select = Instance.new "Model"
	cell_instances_select.Parent = world.cell_instance_root
	cell_instances_select.Name = "Highlights"

	local cell_instances_hover = Instance.new "Model"
	cell_instances_hover.Parent = world.cell_instance_root
	cell_instances_hover.Name = "HighlightsHover"

	local hover_highlight: Highlight = Instance.new "Highlight"
	hover_highlight.Parent = cell_instances_hover
	hover_highlight.Adornee = cell_instances_hover
	hover_highlight.FillTransparency = 1
	hover_highlight.FillColor = Color3.fromRGB(0, 255, 0)

	local selected_highlight: Highlight = Instance.new "Highlight"
	selected_highlight.Adornee = cell_instances_select
	selected_highlight.Parent = cell_instances_select
	selected_highlight.FillTransparency = 0.9
	selected_highlight.OutlineTransparency = 0.5
	selected_highlight.FillColor = Color3.fromRGB(0, 255, 0)

	local selection_mode_stack: { SelectionMode } = {
		{
			type = "select_cells",
			selected = {},
		},
	}

	return {
		cursor_instance = nil,
		shift_select_type = "off",
		cursor_coordinate = nil,
		cell_instances_select = cell_instances_select,
		cell_instances_hover = cell_instances_hover,
		hover_highlight = hover_highlight,
		selected_highlight = selected_highlight,
		selection_mode_stack = selection_mode_stack,
	}
end

function refresh_highlight(world: World, highlight: Highlight, selected: { [EncodedCoordinate]: true })
	highlight.Adornee = nil :: any
	for _, instance in (highlight.Parent :: any):GetChildren() do
		if instance:IsA "Highlight" then
			continue
		end
		local encoded_coord = world.instance_cell_map[instance]
		assert(encoded_coord, "can't find coord for instance")
		if not selected[encoded_coord] then
			instance.Parent = world.cell_instance_root
		end
	end

	for coord in selected do
		local instance = world.cell_instance_map[coord]
		instance.Parent = highlight.Parent
	end
	highlight.Adornee = highlight.Parent
end

function render_stepped(world: World, selection_manager: SelectionManager, update: () -> ())
	local mouse = Players.LocalPlayer:GetMouse()

	return RunService.RenderStepped:Connect(function()
		local raycast_params = RaycastParams.new()
		raycast_params.FilterType = Enum.RaycastFilterType.Include
		raycast_params.FilterDescendantsInstances = { world.cell_instance_root }
		local unit_ray = mouse.UnitRay

		local raycast_result = workspace:Raycast(unit_ray.Origin, unit_ray.Direction * 1000, raycast_params)

		-- Some freak roblox behavior requires the adornee to reset in order to function properly /shrug
		selection_manager.hover_highlight.Adornee = nil :: any

		local old_cursor_instance = selection_manager.cursor_instance
		local cursor_instance = nil
		if raycast_result then
			cursor_instance = raycast_result.Instance
			while cursor_instance and not world.instance_cell_map[cursor_instance] do
				cursor_instance = cursor_instance.Parent
			end
		end

		selection_manager.cursor_instance = cursor_instance

		if cursor_instance then
			selection_manager.cursor_coordinate = world.instance_cell_map[cursor_instance]
		else
			selection_manager.cursor_coordinate = nil
		end

		local cursor_coordinate = selection_manager.cursor_coordinate
		local shift_select_type = selection_manager.shift_select_type
		local hover_highlight = selection_manager.hover_highlight
		local selected_highlight = selection_manager.selected_highlight
		local selection_mode_stack = selection_manager.selection_mode_stack

		refresh_highlight(world, hover_highlight, {})
		local selection_mode = selection_mode_stack[#selection_mode_stack]
		if selection_mode.type == "select_cells" then
			-- update selected_highlight again
			refresh_highlight(world, selected_highlight, selection_mode.selected)
			if
				shift_select_type ~= "off"
				and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				and cursor_instance ~= old_cursor_instance
				and cursor_instance ~= nil
			then
				if shift_select_type == "drag_unknown" then
					if selection_mode.selected[cursor_coordinate] then
						shift_select_type = "drag_exclude"
					else
						shift_select_type = "drag_include"
					end
				end
				if shift_select_type == "drag_include" then
					selection_mode.selected[cursor_coordinate] = true
				elseif shift_select_type == "drag_exclude" then
					selection_mode.selected[cursor_coordinate] = nil
				end
				-- this updates regardless of if any of the cells were changed
				-- surprisingly rerendering the tree many times each second doesn't cause extreme lag
				-- so i'm not going to bother changing it
				update()
				refresh_highlight(world, selected_highlight, selection_mode.selected)
			end

			if cursor_instance then
				refresh_highlight(world, hover_highlight, { [cursor_coordinate] = true })
			end

			if selection_mode.selected[cursor_coordinate] then
				hover_highlight.FillTransparency = 0.92
			else
				hover_highlight.FillTransparency = 1
			end
		elseif selection_mode.type == "select_some_cell" then
			refresh_highlight(world, selected_highlight, selection_mode.candidates :: any)
			if cursor_instance and selection_mode.candidates[cursor_coordinate] then
				hover_highlight.FillTransparency = 0.92
				refresh_highlight(world, hover_highlight, { [cursor_coordinate] = true })
			end
			update()
		elseif selection_mode.type == "show_cells" then
			refresh_highlight(world, selected_highlight, selection_mode.cells :: any)
		end
	end)
end

function bind_select_cell(world: World, selection_manager: SelectionManager, update: () -> ())
	ContextActionService:BindAction("select_cell", function(_action_name, input_state, _input_object)
		local cursor_coordinate = selection_manager.cursor_coordinate
		local selection_mode_stack = selection_manager.selection_mode_stack
		if input_state == Enum.UserInputState.Begin then
			local selection_mode = selection_mode_stack[#selection_mode_stack]
			if selection_mode.type == "select_cells" then
				selection_manager.shift_select_type = "drag_unknown"
				if cursor_coordinate then
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
						if selection_mode.selected[cursor_coordinate] then
							selection_manager.shift_select_type = "drag_exclude"
						else
							selection_manager.shift_select_type = "drag_include"
						end
						if selection_mode.selected[cursor_coordinate] then
							selection_mode.selected[cursor_coordinate] = nil
						else
							selection_mode.selected[cursor_coordinate] = true
						end
					else
						selection_mode.selected = { [cursor_coordinate] = true }
					end
					-- update selected
					update()
					refresh_highlight(world, selection_manager.selected_highlight, selection_mode.selected)
					client_interaction_remote:FireServer {
						{
							type = "tutorial_report_selection",
							selected = util.table_map(util.table_keys(selection_mode.selected), function(encoded_coord)
								return coords.decode_coord(encoded_coord)
							end),
						},
					}
				end
			elseif selection_mode.type == "select_some_cell" then
				if selection_mode.candidates[cursor_coordinate] then
					selection_mode.on_selected(coords.decode_coord(cursor_coordinate))
					selection_mode_stack[#selection_mode_stack] = nil
				end
				update()
			end
		elseif input_state == Enum.UserInputState.End then
			selection_manager.shift_select_type = "off"
		end
	end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
end

return {
	new_selection_manager = new_selection_manager,
	render_stepped = render_stepped,
	bind_select_cell = bind_select_cell,
}
