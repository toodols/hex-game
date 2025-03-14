function theme_solid(props)
	props.BackgroundTransparency = 0.2
	props.BorderSizePixel = 0
	props.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
	return props
end

function theme_background(props)
	props.BackgroundTransparency = 0.9
	props.BorderSizePixel = 0
	props.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
	return props
end

function theme_title(props)
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255)
	props.FontFace = Font.fromName("Oswald", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	props.TextSize = props.TextSize or 18
	props.TextXAlignment = Enum.TextXAlignment.Left
	props.AutomaticSize = Enum.AutomaticSize.X
	props.BackgroundTransparency = 1
	props.RichText = true
	return props
end

function theme_description(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.BorderColor3 = props.BorderColor3 or Color3.fromRGB(0, 0, 0)
	props.BorderSizePixel = props.BorderSizePixel or 0
	props.FontFace = props.FontFace
		or Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(170, 170, 170)
	props.TextSize = props.TextSize or 13
	props.TextWrapped = props.TextWrapped or true
	props.AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.X
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	props.RichText = props.RichText or true
	return props
end

function theme_label(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.TextSize = props.TextSize or 16
	props.FontFace = props.FontFace
		or Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	props.AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.X
	props.RichText = props.RichText or true
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255)
	return props
end

function theme_button(props)
	props.FontFace = props.FontFace or Font.fromName("Oswald", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255)
	props.RichText = props.RichText or true
	props.AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.X
	props.TextSize = props.TextSize or 18
	return props
end

function theme_vertical_container(props)
	props.Size = props.Size or UDim2.new(1, 0, 0, 0)
	props.AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.Y
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	return props
end

function theme_container(props)
	props.Size = props.Size or UDim2.new(1, 0, 1, 0)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	return props
end

return {
	theme_solid = theme_solid,
	theme_background = theme_background,
	theme_title = theme_title,
	theme_description = theme_description,
	theme_button = theme_button,
	theme_container = theme_container,
	theme_vertical_container = theme_vertical_container,
	theme_label = theme_label,
}
