local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

local React = require(ReplicatedStorage.Packages.react)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local util = require(ReplicatedStorage.Shared.util)
local QuestDialogue = require(script.Parent.quest_dialogue).QuestDialogue
local types = require(ReplicatedStorage.Shared.types)

local Corner = util_components.Corner
local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type World = types.World

function TopCenter()
	local world: World = React.useContext(MainContext).world
	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)
	local bar_ref = React.useRef(nil)
	local display_ref = React.useRef(nil)
	local timer_ref = React.useRef(nil)
	local do_animation = React.useRef(false)

	React.useEffect(function()
		local cleanup = world.world_update_signal.listen(function(updates)
			for _, update in updates do
				local do_update = false
				if
					update.type == "turn_timer"
					or update.type == "turn"
					or update.type == "turn_skips"
					or update.type == "quest_update"
					or update.type == "turn_completed"
				then
					if update.type == "turn_completed" then
						do_animation.current = true
					end
					do_update = true
				end
				if do_update then
					force_update(nil)
				end
			end
		end)
		local connection = RunService.Heartbeat:Connect(function()
			if not bar_ref.current then
				return
			end

			local schedule = world.turn_schedule
			if schedule and schedule.end_time ~= math.huge and schedule.end_time ~= 0 then
				if not schedule.running then
					display_ref.current.Text = "--"
					return
				end
				local current_time = workspace:GetServerTimeNow()
				local diff = schedule.end_time - schedule.start_time
				local end_time_sync = schedule.start_time_sync + diff
				bar_ref.current.Size = UDim2.new((current_time - schedule.start_time_sync) / diff, 0, 1, 0)
				local t = end_time_sync - current_time
				t = math.max(0, t)
				display_ref.current.Text = `Next turn: {("%.1f"):format(t)}s`
			else
				bar_ref.current.Size = UDim2.new(0, 0, 1, 0)
				display_ref.current.Text = "--"
			end
		end)

		return function()
			cleanup()
			connection:Disconnect()
		end
	end, {})

	React.useEffect(function()
		if do_animation.current then
			do_animation.current = false
			if timer_ref.current then
				timer_ref.current.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
				local tween = game:GetService("TweenService"):Create(
					timer_ref.current,
					TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundColor3 = Color3.fromRGB(13, 13, 13) }
				)
				tween:Play()
			end
		end
	end)

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 20),
	}, {
		Top = React.createElement("Frame", {
			Size = UDim2.new(0, 0, 0, 40),
			BackgroundTransparency = 1,
		}, {
			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			TurnIndicator = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(13, 13, 13),
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Size = UDim2.new(0, 120, 0, 40),
			}, {
				Turns = React.createElement("TextLabel", {
					RichText = true,
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/SourceSansPro.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 0, 30),
					Text = tostring(world.turn) .. '<font color="#00FF00" size="30"></font>',
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 50,
				}),
				Title = React.createElement(
					"TextLabel",
					themes.theme_title {
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/Oswald.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Position = UDim2.new(0, 0, 0, 5),
						Size = UDim2.new(1, 0, 0, 25),
						Text = "Turn",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 18,
						TextXAlignment = Enum.TextXAlignment.Left,
					},
					{
						PaddingLeft = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 10),
						}),
					}
				),
				Corner = React.createElement(Corner),
			}),
			Timer = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(13, 13, 13),
				BackgroundTransparency = 0.2,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ref = timer_ref,
				ClipsDescendants = true,
				LayoutOrder = 2,
				Size = UDim2.new(0, 500, 0, 40),
			}, {
				Bar = React.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(57, 57, 57),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 0, 1, 0),
					ref = bar_ref,
				}, {
					Corner = React.createElement(Corner),
				}),
				Display = React.createElement("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					ref = display_ref,
					FontFace = Font.new(
						"rbxasset://fonts/families/SourceSansPro.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 0, 0, 20),
					Text = "Next Turn: 0.0s",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 20,
					ZIndex = 2,
				}),
			}),
			SkipButton = React.createElement("TextButton", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Color3.fromRGB(13, 13, 13),
				BackgroundTransparency = 0.2,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
				LayoutOrder = 3,
				Size = UDim2.new(0, 70, 0, 40),
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				[React.Event.MouseButton1Click] = function()
					client_interaction_remote:FireServer { {
						type = "skip",
					} }
				end,
			}, {
				Corner = React.createElement(Corner),
				ImageLabel = React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=6026667005",
					LayoutOrder = 1,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0, 20, 0, 20),
				}),
				SkipLabel = React.createElement("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
					LayoutOrder = 2,
					Size = UDim2.new(0, 0, 1, 0),
					Text = "Skip",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 20,
				}),
				HorizontalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 5),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				SidePad = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 5),
					PaddingRight = UDim.new(0, 10),
				}),
				AmountLabel = React.createElement("TextLabel", {
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
					LayoutOrder = 2,
					Size = UDim2.new(0, 0, 1, 0),
					Text = `{world.current_skips}/{world.needed_skips}`,
					TextColor3 = Color3.fromRGB(190, 190, 190),
					TextSize = 15,
				}),
			}),
		}),

		DialogueContainer = React.createElement(
			"Frame",
			{
				Position = UDim2.new(0.5, 0, 0, 50),
				BackgroundTransparency = 1,
			},
			{
				VerticalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			},
			util.table_map(world.quests, function(quest)
				return quest.current_stage_data.messages
					and React.createElement(
						React.Fragment,
						{
							key = quest.current_stage,
						},
						React.createElement(QuestDialogue, {
							quest = quest,
						})
					)
			end)
		),
	})
end

return {
	TopCenter = TopCenter,
}
