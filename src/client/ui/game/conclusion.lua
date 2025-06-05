local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local themes = require(ReplicatedStorage.Client.ui.themes)
local ui_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local team_mod = require(ReplicatedStorage.Shared.team)

local Corner = ui_components.Corner

type Conclusion = types.Conclusion
type World = types.World

function Conclusion()
	local world: World = React.useContext(MainContext).world
	local conclusion, set_conclusion = React.useState(world.conclusion)

	React.useEffect(function()
		world.world_update_signal.listen(function(updates)
			for _, update in updates do
				if update.type == "conclusion" then
					set_conclusion(update.conclusion)
				end
			end
		end)
	end, {})

	if conclusion == nil then
		return
	end

	print(conclusion)

	local player_team = team_mod.team_of(world, Players.LocalPlayer)

	local player_team_id = player_team.id

	local winning_coalition = if conclusion.winning_coalition
		then world.coalitions[conclusion.winning_coalition]
		else nil

	local status: "victory" | "loss" | "draw"
	if winning_coalition == nil then
		status = "draw"
	else
		for _, team_id in winning_coalition.teams do
			if team_id == player_team_id then
				status = "victory"
				break
			end
		end

		if status == nil then
			status = "loss"
		end
	end

	return React.createElement(
		"Frame",
		themes.theme_solid {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 400, 0, 400),
			BackgroundTransparency = 1,
		},
		{
			Corner = React.createElement(Corner),
			VerticalLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Title = React.createElement(
				"TextLabel",
				themes.theme_title {
					Size = UDim2.new(1, 0, 0, 50),
					Text = "GAME ENDED: " .. status,
					TextSize = 40,
					TextXAlignment = Enum.TextXAlignment.Center,
				}
			),
		}
	)
end

return {
	Conclusion = Conclusion,
}
