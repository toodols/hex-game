local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)

local ui_types = require(ReplicatedStorage.Client.ui.types)
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local Building = require(script.building).Building

type EntityId = types.EntityId
type WorldUpdate = types.WorldUpdate
type World = types.World
type Entity = types.Entity
type CubicCoordinate = types.CubicCoordinate
type EncodedCoordinate = types.EncodedCoordinate
type SelectionMode = ui_types.SelectionMode
type HexCell = types.HexCell

function EntityInformation(props: {
	entity_id: EntityId,
	compressed: boolean,
	LayoutOrder: number?,
	on_compress: () -> (),
	on_select: () -> (),
	is_next: boolean,
	is_previous: boolean,
})
	local entity = hooks.use_synced_entity(props.entity_id)
	local ref = React.useRef(nil :: any)
	local header_ref = React.useRef(nil :: any)
	local inner_ref = React.useRef(nil :: any)

	local is_initial_render = React.useRef(true)
	React.useEffect(function()
		if is_initial_render.current then
			is_initial_render.current = false
			return
		end
		TweenService:Create(ref.current, TweenInfo.new(0.2), {
			Size = UDim2.new(
				1,
				0,
				0,
				if props.compressed then header_ref.current.AbsoluteSize.Y else inner_ref.current.AbsoluteSize.Y
			),
		}):Play()
	end, { props.compressed })

	-- renders once for each entity
	React.useEffect(function()
		if inner_ref.current.AbsoluteSize.Y == 0 then
			inner_ref.current:GetPropertyChangedSignal("AbsoluteSize"):Wait()
		end
		ref.current.Size = UDim2.new(
			1,
			0,
			0,
			if props.compressed then header_ref.current.AbsoluteSize.Y else inner_ref.current.AbsoluteSize.Y
		)
	end, {})

	return React.createElement(
		"Frame",
		{
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			LayoutOrder = props.LayoutOrder,
			Position = UDim2.new(0, 0, 0, 0),
			[React.Tag] = "solid",
			ZIndex = 2,
			ClipsDescendants = true,
			ref = ref,
			[React.Change.AbsoluteSize] = function()
				print("entity frame absolute size changed to", ref.current.AbsoluteSize.X, ref.current.AbsoluteSize.Y)
			end,
		},
		React.createElement(Building, {
			entity = entity,
			ref = inner_ref,
			header_ref = header_ref,
			active = not props.compressed,
			on_select = props.on_select,
		})
	)
end

return {
	EntityInformation = EntityInformation,
}
