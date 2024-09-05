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
	props.BackgroundTransparency = 1
	props.BorderColor3 = Color3.fromRGB(0, 0, 0)
	props.BorderSizePixel = 0
	props.FontFace = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	props.TextColor3 = Color3.fromRGB(170, 170, 170)
	props.TextSize = props.TextSize or 13
	props.TextWrapped = true
	props.AutomaticSize = props.AutomaticSize or Enum.AutomaticSize.X
	props.TextXAlignment = Enum.TextXAlignment.Left
	props.RichText = true
	return props
end

function theme_button(props)
	props.FontFace = Font.fromName("Oswald", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
	return props
end

return {
	theme_solid = theme_solid,
	theme_background = theme_background,
	theme_title = theme_title,
	theme_description = theme_description,
	theme_button = theme_button,
}
