local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local ui_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local team_mod = require(ReplicatedStorage.Shared.team)

local teleport_remote = ReplicatedStorage:FindFirstChild "TeleportRemote" :: RemoteEvent

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

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 400, 0, 400),
		BackgroundTransparency = 1,
	}, {
		Corner = React.createElement(Corner),
		Top = React.createElement("Frame", {
			[React.Tag] = "container",
		}, {
			VerticalLayout = React.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			Title = React.createElement("TextLabel", {
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 50),
				Text = "GAME ENDED: " .. status,
				TextSize = 40,
				[React.Tag] = "text-c",
			}),
			Label = React.createElement("TextLabel", {
				LayoutOrder = 2,
				Text = "Archive data:",
				TextSize = 20,
				[React.Tag] = "text-c",
				Size = UDim2.new(1, 0, 0, 30),
			}),
			WorldArchive = React.createElement("ScrollingFrame", {
				Size = UDim2.new(1, -20, 0, 100),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				LayoutOrder = 3,
				[React.Tag] = "solid",
			}, {
				TextBox = React.createElement("TextBox", {
					ClipsDescendants = true,
					BackgroundTransparency = 1,
					Text = conclusion.world_archive,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextYAlignment = Enum.TextYAlignment.Top,
					TextSize = 10,
					TextWrapped = true,
					ClearTextOnFocus = false,
					Size = UDim2.new(1, 0, 0, 5000),
				}),
			}),
		}),
		Bottom = React.createElement("Frame", {
			Position = UDim2.new(0, 0, 1, 0),
			Size = UDim2.new(1, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 1),
			[React.Tag] = "container",
		}, {

			LobbyButton = React.createElement("TextButton", {
				LayoutOrder = 2,
				Text = "Return to Lobby",
				TextSize = 20,
				Size = UDim2.new(0, 200, 0, 40),
				[React.Tag] = "align-bc",
				Position = UDim2.new(0.5, 0, 1, -10),
				[React.Event.Activated] = function()
					teleport_remote:FireServer "lobby"
				end,
			}),
		}),
	})
end

return {
	Conclusion = Conclusion,
}
