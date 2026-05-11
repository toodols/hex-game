local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext

type TeamData = types.TeamData
type World = types.World

function TeamSection(props: {
	team: TeamData,
})
	return React.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(12, 12, 12),
		BackgroundTransparency = 0.2,
		BorderColor3 = Color3.fromRGB(27, 42, 53),
		Size = UDim2.new(1, 0, 0, 0),
	}, {
		VerticalLayout = React.createElement("UIListLayout", {
			Padding = UDim.new(0, 1),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		Body = React.createElement(
			"Frame",
			{
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 0),
			},
			{
				VerticalLayout3 = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			},
			util.table_map(props.team.players, function(user_id)
				local player = game.Players:GetPlayerByUserId(user_id)
				if player == nil then
					return
				end
				return React.createElement("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					FontFace = Font.new(
						"rbxasset://fonts/families/Michroma.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					LayoutOrder = 2,
					RichText = true,
					Size = UDim2.new(1, 0, 0, 0),
					Text = `{player.DisplayName} (<font color="#888"><i>@{player.Name}</i></font>)`,
					TextColor3 = Color3.fromRGB(170, 170, 170),
					TextSize = 15,
					TextWrapped = true,
					[React.Tag] = "text-l",
				}, {
					Padding = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 5),
						PaddingRight = UDim.new(0, 5),
					}),
				})
			end)
		),

		Frame = React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
		}, {
			Header = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Michroma.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 0),
				Text = props.team.name,
				TextColor3 = (props.team.color :: any).color,
				TextSize = 20,
				TextWrapped = true,
				[React.Tag] = "text-l",
			}, {
				Padding = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 5),
				}),

				UIStroke = React.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.8,
				}),
			}),

			-- Score = React.createElement("TextLabel", {
			-- 	AutomaticSize = Enum.AutomaticSize.Y,
			-- 	BackgroundTransparency = 1,
			-- 	BorderColor3 = Color3.fromRGB(0, 0, 0),
			-- 	BorderSizePixel = 0,
			-- 	FontFace = Font.new(
			-- 		"rbxasset://fonts/families/Michroma.json",
			-- 		Enum.FontWeight.Bold,
			-- 		Enum.FontStyle.Normal
			-- 	),
			-- 	LayoutOrder = 1,
			-- 	Size = UDim2.new(1, 0, 0, 0),
			-- 	Text = "21 Tiles",
			-- 	TextColor3 = Color3.fromRGB(170, 170, 170),
			-- 	TextSize = 20,
			-- 	TextWrapped = true,
			-- 	[React.Tag] = "text-r",
			-- }, {
			-- 	Padding = React.createElement("UIPadding", {
			-- 		PaddingLeft = UDim.new(0, 5),
			-- 		PaddingRight = UDim.new(0, 5),
			-- 	}),
			-- }),
		}),
	})
end

function PlayerList(props: { visible: boolean })
	local world: World = React.useContext(MainContext).world
	local teams, set_teams = React.useState(world.teams)

	React.useEffect(function()
		world.world_update_signal.listen(function(updates)
			for _, update in updates do
				if update.type == "teams" then
					set_teams(update.teams)
				end
			end
		end)
	end, {})

	return React.createElement("Frame", {
		LayoutOrder = 1,
		[React.Tag] = "align-cc background as-xy list-v list-pad-5",
		Visible = props.visible,
	}, {
		Header = React.createElement("Frame", {
			[React.Tag] = "header",
			LayoutOrder = 1,
		}, {
			Title = React.createElement("TextLabel", {
				Text = "Players",
				[React.Tag] = "title",
			}),
		}),
		Container = React.createElement("Frame", {
			LayoutOrder = 2,
			[React.Tag] = "container",
		}, {
			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			ItemsScrollingFrame = React.createElement("ScrollingFrame", {
				[React.Tag] = "container-v list-v list-pad-5",
			}, {
				UISizeConstraint = React.createElement("UISizeConstraint", {
					MinSize = Vector2.new(0, 200),
				}),
			}, (util.table_map(teams, function(team: TeamData)
				if team.is_player_team or team.is_spectator_team then
					return React.createElement(TeamSection, { team = team })
				else
					return React.createElement(React.Fragment)
				end
			end))),
		}),

		UISizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(600, math.huge),
		}),
	})
end

return {
	PlayerList = PlayerList,
}
