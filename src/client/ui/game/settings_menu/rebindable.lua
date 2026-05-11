local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"

local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Separator = util_components.Separator

type KeybindId = types.KeybindId

function Rebindable(props: {
	id: KeybindId,
	label: string?,
	LayoutOrder: number?,
	default: Enum.KeyCode?,
	value: Enum.KeyCode,
	on_changed: (Enum.KeyCode) -> (),
})
	local input_ref = React.useRef(nil)
	local connection_ref = React.useRef(nil)
	local button_ref = React.useRef(nil)

	return React.createElement("Frame", {
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 0.7,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	}, {
		Left = React.createElement("TextLabel", {
			Size = UDim2.new(0, 200, 0, 30),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Text = props.label,
			LayoutOrder = 1,
		}),
		Right = React.createElement("TextButton", {
			Text = if props.value == Enum.KeyCode.Unknown
				then "None"
				else UserInputService:GetStringForKeyCode(props.value),
			Position = UDim2.new(1, -10, 0, 0),
			Size = UDim2.new(0, 60, 0, 30),
			[React.Tag] = "solid align-tr bg-3",
			LayoutOrder = 2,
			ref = button_ref,
			[React.Event.MouseButton1Click] = function(button)
				input_ref.current:CaptureFocus()
				button.Text = "..."
			end,
		}, {
			SneakyInput = React.createElement("TextBox", {
				TextScaled = true,
				Visible = false,
				ref = input_ref,
				[React.Event.Focused] = function(box)
					if connection_ref.current then
						connection_ref.current:Disconnect()
					end
					connection_ref.current = UserInputService.InputBegan:Connect(function(input, gameProcessed)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							if input.KeyCode == Enum.KeyCode.Escape then
								props.on_changed(Enum.KeyCode.Unknown)
								box:ReleaseFocus()
								return
							end

							props.on_changed(input.KeyCode)
							box:ReleaseFocus()
						end
					end)
				end,
				[React.Event.FocusLost] = function(enter_pressed)
					button_ref.current.Text = if props.value == Enum.KeyCode.Unknown then "None" else props.value.Name

					connection_ref.current:Disconnect()
				end,
			}),
		}),
	})
end

return {
	Rebindable = Rebindable,
}
