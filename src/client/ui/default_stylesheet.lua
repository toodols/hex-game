local style_sheet = Instance.new "StyleSheet"
local style_rules = {}

local style_rule_0 = Instance.new "StyleRule"
style_rule_0.Parent = style_sheet
table.insert(style_rules, style_rule_0)
style_rule_0.Selector = ".aln-cl"
style_rule_0:SetProperties{
	["AnchorPoint"] = Vector2.new(0, 0.5), 
	["Position"] = UDim2.new(0, 0, 0.5, 0)
}

local style_rule_1 = Instance.new "StyleRule"
style_rule_1.Parent = style_sheet
table.insert(style_rules, style_rule_1)
style_rule_1.Selector = ".aln-cr"
style_rule_1:SetProperties{
	["AnchorPoint"] = Vector2.new(1, 0.5), 
	["Position"] = UDim2.new(1, 0, 0.5, 0)
}

local style_rule_2 = Instance.new "StyleRule"
style_rule_2.Parent = style_sheet
table.insert(style_rules, style_rule_2)
style_rule_2.Selector = ".aln-cc"
style_rule_2:SetProperties{
	["AnchorPoint"] = Vector2.new(0.5, 0.5), 
	["Position"] = UDim2.new(0.5, 0, 0.5, 0)
}

local style_rule_3 = Instance.new "StyleRule"
style_rule_3.Parent = style_sheet
table.insert(style_rules, style_rule_3)
style_rule_3.Selector = ".aln-tl"
style_rule_3:SetProperties{
	["AnchorPoint"] = Vector2.new(0, 0), 
	["Position"] = UDim2.new(0, 0, 0, 0)
}

local style_rule_4 = Instance.new "StyleRule"
style_rule_4.Parent = style_sheet
table.insert(style_rules, style_rule_4)
style_rule_4.Selector = ".aln-tr"
style_rule_4:SetProperties{
	["AnchorPoint"] = Vector2.new(1, 0), 
	["Position"] = UDim2.new(1, 0, 0, 0)
}

local style_rule_5 = Instance.new "StyleRule"
style_rule_5.Parent = style_sheet
table.insert(style_rules, style_rule_5)
style_rule_5.Selector = ".aln-tc"
style_rule_5:SetProperties{
	["AnchorPoint"] = Vector2.new(0.5, 0), 
	["Position"] = UDim2.new(0.5, 0, 0, 0)
}

local style_rule_6 = Instance.new "StyleRule"
style_rule_6.Parent = style_sheet
table.insert(style_rules, style_rule_6)
style_rule_6.Selector = ".aln-bl"
style_rule_6:SetProperties{
	["AnchorPoint"] = Vector2.new(0, 1), 
	["Position"] = UDim2.new(0, 0, 1, 0)
}

local style_rule_7 = Instance.new "StyleRule"
style_rule_7.Parent = style_sheet
table.insert(style_rules, style_rule_7)
style_rule_7.Selector = ".aln-br"
style_rule_7:SetProperties{
	["AnchorPoint"] = Vector2.new(1, 1), 
	["Position"] = UDim2.new(1, 0, 1, 0)
}

local style_rule_8 = Instance.new "StyleRule"
style_rule_8.Parent = style_sheet
table.insert(style_rules, style_rule_8)
style_rule_8.Selector = ".aln-bc"
style_rule_8:SetProperties{
	["AnchorPoint"] = Vector2.new(0.5, 1), 
	["Position"] = UDim2.new(0.5, 0, 1, 0)
}

local style_rule_9 = Instance.new "StyleRule"
style_rule_9.Parent = style_sheet
table.insert(style_rules, style_rule_9)
style_rule_9.Selector = "TextButton, TextLabel"
style_rule_9.Priority = 10
style_rule_9:SetProperties{
	["TextXAlignment"] = Enum.TextXAlignment.Left, 
	["AutomaticSize"] = Enum.AutomaticSize.X, 
	["RichText"] = true, 
	["TextColor3"] = Color3.fromRGB(255, 255, 255), 
	["TextSize"] = 20, 
	["FontFace"] = Font.new "rbxasset://fonts/families/SourceSansPro.json", 
	["BorderSizePixel"] = 0
}

local style_rule_10 = Instance.new "StyleRule"
style_rule_10.Parent = style_sheet
table.insert(style_rules, style_rule_10)
style_rule_10.Selector = "TextButton::UICorner, .solid::UICorner"
style_rule_10:SetProperties{
	["CornerRadius"] = UDim.new(0, 4)
}

local style_rule_11 = Instance.new "StyleRule"
style_rule_11.Parent = style_sheet
table.insert(style_rules, style_rule_11)
style_rule_11.Selector = "Frame"
style_rule_11:SetProperties{
	["BorderSizePixel"] = 0, 
	["BackgroundTransparency"] = 1
}

local style_rule_12 = Instance.new "StyleRule"
style_rule_12.Parent = style_sheet
table.insert(style_rules, style_rule_12)
style_rule_12.Selector = ".solid"
style_rule_12:SetProperties{
	["BackgroundColor3"] = Color3.fromRGB(0, 0, 0), 
	["BackgroundTransparency"] = 0.2
}
style_sheet:SetStyleRules(style_rules)

return style_sheet