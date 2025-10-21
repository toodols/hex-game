local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RunService = game:GetService "RunService"

function new_default_stylesheet(): StyleSheet
	local stylesheet = Instance.new "StyleSheet"
	stylesheet.Name = "DefaultStylesheet"

	local button_rule = Instance.new "StyleRule"
	button_rule.Selector = "TextButton"
	button_rule:SetProperties {
		AutomaticSize = Enum.AutomaticSize.X,
		RichText = true,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 20,
		FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
		BorderSizePixel = 0,
	}

	local solid_rule = Instance.new "StyleRule"
	solid_rule.Selector = ".solid"
	solid_rule:SetProperties {
		BorderSizePixel = 0,
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.2,
	}

	local corner_rule = Instance.new "StyleRule"
	corner_rule.Selector = ".corner::UICorner"
	corner_rule:SetProperties {
		CornerRadius = UDim.new(0, 4),
	}

	local skip_rule = Instance.new "StyleRule"
	skip_rule.Selector = ".skip"
	skip_rule:SetProperties {
		BackgorundColor3 = Color3.fromRGB(255, 0, 0),
	}

	stylesheet:SetStyleRules { button_rule, solid_rule, skip_rule, corner_rule }
	return stylesheet
end

if RunService:IsClient() then
	local stylesheets_folder = ReplicatedStorage:FindFirstChild "Stylesheets"
	if stylesheets_folder ~= nil then
		return {
			default_stylesheet = stylesheets_folder:FindFirstChild "DefaultStylesheet",
		}
	end
end

local stylesheets_folder = Instance.new "Folder"
stylesheets_folder.Name = "Stylesheets"
stylesheets_folder.Parent = ReplicatedStorage

local default_stylesheet = new_default_stylesheet()
default_stylesheet.Parent = stylesheets_folder
return { default_stylesheet = default_stylesheet }
