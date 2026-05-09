local Players = game:GetService "Players"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local TweenService = game:GetService "TweenService"

local React = require(ReplicatedStorage.Packages.react)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local util = require(ReplicatedStorage.Shared.util)
local QuestDialogue = require(script.Parent.quest_dialogue).QuestDialogue
local types = require(ReplicatedStorage.Shared.types)

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type World = types.World

local local_player = Players.LocalPlayer

function TopCenter()
	local world: World = React.useContext(MainContext).world
	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)
	local bar_ref = React.useRef(nil)
	local display_ref = React.useRef(nil)
	local timer_ref = React.useRef(nil)
	local do_animation = React.useRef(false)
	local skip_btn_ref = React.useRef(nil)
	local did_skip = React.useRef(false)
	local old_skips = React.useRef(world.current_skips)
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
					or update.type == "turn_skipped"
				then
					if update.type == "turn_completed" then
						do_animation.current = true
					end
					if update.type == "turn_skipped" then
						did_skip.current = true
					end
					if old_skips.current ~= world.current_skips then
						old_skips.current = world.current_skips
						if world.current_skips > 0 then
							did_skip.current = true
						end
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
		if did_skip.current then
			did_skip.current = false
			local tween = TweenService:Create(skip_btn_ref.current.Stroke, TweenInfo.new(0.3), {
				Transparency = 0.4,
			})
			tween:Play()
			tween.Completed:Connect(function()
				local tween2 = TweenService:Create(skip_btn_ref.current.Stroke, TweenInfo.new(0.3), {
					Transparency = 1,
				})
				tween2:Play()
			end)
		end
	end)

	React.useEffect(function()
		if do_animation.current then
			do_animation.current = false
			if timer_ref.current then
				timer_ref.current.BackgroundColor3 = Color3.fromRGB(57, 57, 57)
				local tween = TweenService:Create(
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
		Position = UDim2.new(0.5, 0, 0, 20),
	}, {
		Top = React.createElement("Frame", {
			Size = UDim2.new(0, 0, 0, 40),
			[React.Tag] = "list-h list-pad-5 list-cc",
		}, {
			TurnIndicator = React.createElement("Frame", {
				LayoutOrder = 1,
				Size = UDim2.new(0, 120, 0, 40),
				[React.Tag] = "solid",
			}, {
				Turns = React.createElement("TextLabel", {
					Size = UDim2.new(0.6, 0, 0, 30),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Text = `{world.turn} <font color="#00FF00" size="30"></font>`,
					TextSize = 25,
				}),
				Title = React.createElement("TextLabel", {
					Text = "Turn",
					[React.Tag] = "title align-cl pad-l-5 ty-c as-xy",
				}),
			}),
			Timer = React.createElement("Frame", {
				ref = timer_ref,
				ClipsDescendants = true,
				LayoutOrder = 2,
				Size = UDim2.new(0, 500, 0, 40),
				[React.Tag] = "solid",
			}, {
				Bar = React.createElement("Frame", {
					BackgroundColor3 = Color3.fromRGB(57, 57, 57),
					[React.Tag] = "solid",
					Size = UDim2.new(0, 0, 1, 0),
					ref = bar_ref,
				}),
				Display = React.createElement("TextLabel", {
					ref = display_ref,
					Size = UDim2.new(0, 0, 0, 20),
					Text = "Next Turn: 0.0s",
					ZIndex = 2,
					[React.Tag] = "align-cc",
				}),
			}),
			SkipButton = React.createElement("TextButton", {
				LayoutOrder = 3,
				Size = UDim2.new(0, 70, 0, 40),
				Text = "",
				ref = skip_btn_ref,
				[React.Tag] = `.skip-button solid {if local_player
						and table.find(world.skipped, local_player.UserId)
					then "active"
					else ""}`,
				[React.Event.MouseButton1Click] = function()
					client_interaction_remote:FireServer { {
						type = "skip",
					} }
				end,
			}, {
				ImageLabel = React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=6026667005",
					LayoutOrder = 1,
					[React.Tag] = "align-cl",
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
				Stroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(159, 255, 103),
					LineJoinMode = Enum.LineJoinMode.Round,
					Thickness = 1,
					Transparency = 1,
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
