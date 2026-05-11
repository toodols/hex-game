local ContextActionService = game:GetService "ContextActionService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"
local UserInputService = game:GetService "UserInputService"
local React = require(ReplicatedStorage.Packages.react)
local SettingsContext = require(ReplicatedStorage.Client.ui.context).SettingsContext
local get_keybind = require(ReplicatedStorage.Client.settings).get_keybind
function KeybindLabel(props: {
	action_id: string,
	Position: UDim2,
	AnchorPoint: Vector2,
	action: (action_name: string, input_state: Enum.UserInputState, input_object: InputObject) -> (),
})
	if not RunService:IsClient() then
		return nil
	end
	local player_settings = React.useContext(SettingsContext)
	local ref = React.useRef(nil :: any)
	local keycode = get_keybind(player_settings, props.action_id)
	if keycode == Enum.KeyCode.Unknown then
		warn("unknown keybind " .. props.action_id)
	end
	React.useEffect(function()
		ContextActionService:BindAction(props.action_id, function(action_name, input_state, input_object)
			if input_state == Enum.UserInputState.Begin then
				(ref.current :: TextLabel):AddTag "active"
			elseif input_state == Enum.UserInputState.End then
				(ref.current :: TextLabel):RemoveTag "active"
			end
			props.action(action_name, input_state, input_object)
		end, false, keycode)
		return function()
			ContextActionService:UnbindAction(props.action_id)
		end
	end, { props.action })
	local text = UserInputService:GetStringForKeyCode(keycode)
	if keycode == Enum.KeyCode.Backspace then
		text = "←"
	end
	return React.createElement("TextLabel", {
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		ref = ref,
		[React.Tag] = `stroke solid text-c ty-c`,
		Size = UDim2.new(0, 15, 0, 15),
		TextSize = 10,
		Text = text,
	})
end

return {
	KeybindLabel = KeybindLabel,
}
