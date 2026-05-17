local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local util = require(ReplicatedStorage.Shared.util)
local Corner = util_components.Corner
local Dropdown = util_components.Dropdown
local TeamDropdownItem = require(script.Parent.team_dropdown_item).TeamDropdownItem

local rooms_remote = ReplicatedStorage:FindFirstChild "Rooms" :: RemoteEvent

function ExpandedMember(props: {
	player: Player,
	teams: { [number]: {
		color: Color3,
		name: string,
	} },
	team: number,
	ZIndex: number,
})
	local is_local_player = props.player == Players.LocalPlayer
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 45),
		ZIndex = props.ZIndex,
	}, {
		Container = React.createElement("Frame", {
			ZIndex = 2,
			[React.Tag] = "container list-h list-pad-10 list-cl",
		}, {
			Headshot = React.createElement("ImageLabel", {
				LayoutOrder = 1,
				Image = Players:GetUserThumbnailAsync(
					props.player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				),
				Size = UDim2.new(0, 30, 0, 30),
				[React.Tag] = "align-cc background",
			}),
			PlayerNameLabel = React.createElement("TextLabel", {
				LayoutOrder = 2,
				Size = UDim2.new(0, 0, 1, 0),
				Text = `<font size="25">{props.player.DisplayName}</font>\n<i>@{props.player.Name}</i>`,
				TextSize = 12,
			}),
		}),
		Team = React.createElement(Dropdown, {
			Position = UDim2.new(1, -5, 0.5, 0),
			[React.Tag] = "align-cr",
			current = props.team,
			options = util.table_map(
				if is_local_player then props.teams else { [props.team] = props.teams[props.team] },
				function(team)
					return React.createElement(TeamDropdownItem, {
						icon_color = team.color,
						text = team.name,
					})
				end
			),
			on_change = function(team)
				rooms_remote:FireServer {
					type = "set_team",
					team = team,
				}
			end,
		}),
		Pattern = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://300134974",
			ImageTransparency = 0.77,
			Position = UDim2.new(0.00667, 0, 0.167, 0),
			ScaleType = Enum.ScaleType.Tile,
			Size = UDim2.new(0, 295, 0, 37),
			TileSize = UDim2.new(0, 90, 0, 90),
			ZIndex = 0,
		}, {
			UIGradient = React.createElement("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new {
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.524, 0.431),
					NumberSequenceKeypoint.new(1, 1),
				},
			}),
		}),
	})
end

return {
	ExpandedMember = ExpandedMember,
}
