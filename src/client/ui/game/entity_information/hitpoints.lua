local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local shared_entity_mod = require(ReplicatedStorage.Shared.entity)
local util = require(ReplicatedStorage.Shared.util)
local hooks = require(ReplicatedStorage.Client.ui.hooks)

type EntityId = types.EntityId

function Hitpoints(props: { entity_id: EntityId })
	local entity = hooks.use_synced_entity(props.entity_id)
	local total_health = shared_entity_mod.get_effective_health(entity)
	local shield_health = total_health - entity.health

	return React.createElement(
		"Frame",
		{
			AnchorPoint = Vector2.new(1, 0),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.new(0, 100, 1, 0),
		},
		{
			GridLayout = React.createElement("UIGridLayout", {
				CellPadding = UDim2.new(0, 7, 0, 7),
				CellSize = UDim2.new(0, 6, 0, 6),
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			AllPad = React.createElement("UIPadding", {
				PaddingBottom = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingTop = UDim.new(0, 8),
			}),
		},
		if entity.max_health > 20 or entity.status == "blueprint"
			-- freak bug that occurs if I don't have { } around these special hitpoint renders
			-- jsdotlua/react-lua #42 ??
			then {
				React.createElement("TextLabel", {
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.new(0, 100, 0, 100),
					TextSize = 12,
					[React.Tag] = "text-r",
					Text = if entity.max_health ~= math.huge and entity.status ~= "blueprint"
						then `{entity.health} / {entity.max_health} {if shield_health > 0
							then ` +{shield_health}`
							else ""}`
						else "--",
				}),
			}
			elseif total_health == 0 then {
				React.createElement("Frame", {
					BorderSizePixel = 1,
					BorderColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundColor3 = Color3.new(0, 0, 0),
					Size = UDim2.new(0, 100, 0, 100),
				}),
			}
			else util.table_map((util.range(math.max(entity.max_health, shield_health))), function(i)
				local color
				if i <= shield_health then
					if i <= entity.health then
						color = Color3.fromHSV(0.55, 0.6, 1.000000)
					elseif i <= entity.max_health then
						color = Color3.fromHSV(0.55, 0.6, 0.5)
					else
						color = Color3.fromHSV(0.55, 0.6, 0.3)
					end
				else
					if i <= entity.health then
						color = Color3.fromRGB(255, 255, 255)
					else
						color = Color3.fromRGB(120, 120, 120)
					end
				end
				return React.createElement("Frame", {
					BackgroundColor3 = color,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 100, 0, 100),
				})
			end)
	)
end

return {
	Hitpoints = Hitpoints,
}
