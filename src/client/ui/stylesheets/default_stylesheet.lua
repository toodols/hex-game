local style_sheet = Instance.new "StyleSheet"

local style_rule_0 = Instance.new "StyleRule"
style_rule_0.Parent = style_sheet
style_rule_0.Selector = ".align-cl"
style_rule_0:SetProperties{
	["AnchorPoint"] = Vector2.new(0, 0.5), 
	["Position"] = UDim2.new(0, 0, 0.5, 0)
}

local style_rule_1 = Instance.new "StyleRule"
style_rule_1.Parent = style_sheet
style_rule_1.Selector = ".align-cr"
style_rule_1:SetProperties{
	["AnchorPoint"] = Vector2.new(1, 0.5), 
	["Position"] = UDim2.new(1, 0, 0.5, 0)
}

local style_rule_2 = Instance.new "StyleRule"
style_rule_2.Parent = style_sheet
style_rule_2.Selector = ".align-cc"
style_rule_2:SetProperties{
	["AnchorPoint"] = Vector2.new(0.5, 0.5), 
	["Position"] = UDim2.new(0.5, 0, 0.5, 0)
}

local style_rule_3 = Instance.new "StyleRule"
style_rule_3.Parent = style_sheet
style_rule_3.Selector = ".align-tl"
style_rule_3:SetProperties{
	["AnchorPoint"] = Vector2.new(0, 0), 
	["Position"] = UDim2.new(0, 0, 0, 0)
}

local style_rule_4 = Instance.new "StyleRule"
style_rule_4.Parent = style_sheet
style_rule_4.Selector = ".align-tr"
style_rule_4:SetProperties{
	["AnchorPoint"] = Vector2.new(1, 0), 
	["Position"] = UDim2.new(1, 0, 0, 0)
}

local style_rule_5 = Instance.new "StyleRule"
style_rule_5.Parent = style_sheet
style_rule_5.Selector = ".align-tc"
style_rule_5:SetProperties{
	["AnchorPoint"] = Vector2.new(0.5, 0), 
	["Position"] = UDim2.new(0.5, 0, 0, 0)
}

local style_rule_6 = Instance.new "StyleRule"
style_rule_6.Parent = style_sheet
style_rule_6.Selector = ".align-bl"
style_rule_6:SetProperties{
	["AnchorPoint"] = Vector2.new(0, 1), 
	["Position"] = UDim2.new(0, 0, 1, 0)
}

local style_rule_7 = Instance.new "StyleRule"
style_rule_7.Parent = style_sheet
style_rule_7.Selector = ".align-br"
style_rule_7:SetProperties{
	["AnchorPoint"] = Vector2.new(1, 1), 
	["Position"] = UDim2.new(1, 0, 1, 0)
}

local style_rule_8 = Instance.new "StyleRule"
style_rule_8.Parent = style_sheet
style_rule_8.Selector = ".align-bc"
style_rule_8:SetProperties{
	["AnchorPoint"] = Vector2.new(0.5, 1), 
	["Position"] = UDim2.new(0.5, 0, 1, 0)
}

local style_rule_9 = Instance.new "StyleRule"
style_rule_9.Parent = style_sheet
style_rule_9.Selector = ".as-y"
style_rule_9.Priority = 10
style_rule_9:SetProperties{
	["AutomaticSize"] = Enum.AutomaticSize.Y
}

local style_rule_10 = Instance.new "StyleRule"
style_rule_10.Parent = style_sheet
style_rule_10.Selector = ".as-x"
style_rule_10.Priority = 10
style_rule_10:SetProperties{
	["AutomaticSize"] = Enum.AutomaticSize.X
}

local style_rule_11 = Instance.new "StyleRule"
style_rule_11.Parent = style_sheet
style_rule_11.Selector = ".as-xy"
style_rule_11.Priority = 10
style_rule_11:SetProperties{
	["AutomaticSize"] = Enum.AutomaticSize.XY
}

local style_rule_12 = Instance.new "StyleRule"
style_rule_12.Parent = style_sheet
style_rule_12.Selector = ".as-none"
style_rule_12.Priority = 10
style_rule_12:SetProperties{
	["AutomaticSize"] = Enum.AutomaticSize.None
}

local style_rule_13 = Instance.new "StyleRule"
style_rule_13.Parent = style_sheet
style_rule_13.Selector = ".list-v::UIListLayout"
style_rule_13:SetProperties{
	["SortOrder"] = Enum.SortOrder.LayoutOrder, 
	["FillDirection"] = Enum.FillDirection.Vertical
}

local style_rule_14 = Instance.new "StyleRule"
style_rule_14.Parent = style_sheet
style_rule_14.Selector = ".list-h::UIListLayout"
style_rule_14:SetProperties{
	["SortOrder"] = Enum.SortOrder.LayoutOrder, 
	["FillDirection"] = Enum.FillDirection.Horizontal
}

local style_rule_15 = Instance.new "StyleRule"
style_rule_15.Parent = style_sheet
style_rule_15.Selector = ".list-cc::UIListLayout"
style_rule_15:SetProperties{
	["VerticalAlignment"] = Enum.VerticalAlignment.Center, 
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Center
}

local style_rule_16 = Instance.new "StyleRule"
style_rule_16.Parent = style_sheet
style_rule_16.Selector = ".list-cl::UIListLayout"
style_rule_16:SetProperties{
	["VerticalAlignment"] = Enum.VerticalAlignment.Center, 
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Left
}

local style_rule_17 = Instance.new "StyleRule"
style_rule_17.Parent = style_sheet
style_rule_17.Selector = ".list-cr::UIListLayout"
style_rule_17:SetProperties{
	["VerticalAlignment"] = Enum.VerticalAlignment.Center, 
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Right
}

local style_rule_18 = Instance.new "StyleRule"
style_rule_18.Parent = style_sheet
style_rule_18.Selector = ".list-br::UIListLayout"
style_rule_18:SetProperties{
	["VerticalAlignment"] = Enum.VerticalAlignment.Bottom, 
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Right
}

local style_rule_19 = Instance.new "StyleRule"
style_rule_19.Parent = style_sheet
style_rule_19.Selector = ".list-bl::UIListLayout"
style_rule_19:SetProperties{
	["VerticalAlignment"] = Enum.VerticalAlignment.Bottom, 
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Left
}

local style_rule_20 = Instance.new "StyleRule"
style_rule_20.Parent = style_sheet
style_rule_20.Selector = ".list-bc::UIListLayout"
style_rule_20:SetProperties{
	["VerticalAlignment"] = Enum.VerticalAlignment.Bottom, 
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Center
}

local style_rule_21 = Instance.new "StyleRule"
style_rule_21.Parent = style_sheet
style_rule_21.Selector = ".list-pad-5::UIListLayout"
style_rule_21:SetProperties{
	["Padding"] = UDim.new(0, 5)
}

local style_rule_22 = Instance.new "StyleRule"
style_rule_22.Parent = style_sheet
style_rule_22.Selector = ".list-pad-2::UIListLayout"
style_rule_22:SetProperties{
	["Padding"] = UDim.new(0, 2)
}

local style_rule_23 = Instance.new "StyleRule"
style_rule_23.Parent = style_sheet
style_rule_23.Selector = ".grid-cc::UIGridLayout"
style_rule_23:SetProperties{
	["SortOrder"] = Enum.SortOrder.LayoutOrder, 
	["HorizontalAlignment"] = Enum.HorizontalAlignment.Center, 
	["VerticalAlignment"] = Enum.VerticalAlignment.Center
}

local style_rule_24 = Instance.new "StyleRule"
style_rule_24.Parent = style_sheet
style_rule_24.Selector = ".grid-cell-36::UIGridLayout"
style_rule_24:SetProperties{
	["CellSize"] = UDim2.new(0, 36, 0, 36)
}

local style_rule_25 = Instance.new "StyleRule"
style_rule_25.Parent = style_sheet
style_rule_25.Selector = ".grid-pad-6::UIGridLayout"
style_rule_25:SetProperties{
	["Padding"] = UDim.new(0, 6)
}

local style_rule_26 = Instance.new "StyleRule"
style_rule_26.Parent = style_sheet
style_rule_26.Selector = "Frame, TextButton, TextLabel, ScrollingFrame"
style_rule_26:SetProperties{
	["BorderSizePixel"] = 0, 
	["BackgroundColor3"] = Color3.fromRGB(0, 0, 0)
}

local style_rule_27 = Instance.new "StyleRule"
style_rule_27.Parent = style_sheet
style_rule_27.Selector = "ImageLabel, TextLabel, ViewportFrame"
style_rule_27:SetProperties{
	["BackgroundTransparency"] = 1
}

local style_rule_28 = Instance.new "StyleRule"
style_rule_28.Parent = style_sheet
style_rule_28.Selector = "TextButton, TextLabel"
style_rule_28:SetProperties{
	["AutomaticSize"] = Enum.AutomaticSize.X, 
	["RichText"] = true, 
	["TextColor3"] = Color3.fromRGB(255, 255, 255), 
	["TextSize"] = 20, 
	["BorderSizePixel"] = 0, 
	["Size"] = UDim2.new(0, 0, 1, 0), 
	["Text"] = ""
}

local style_rule_29 = Instance.new "StyleRule"
style_rule_29.Parent = style_sheet
style_rule_29.Selector = "TextLabel"
style_rule_29:SetProperties{
	["FontFace"] = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal), 
	["TextXAlignment"] = Enum.TextXAlignment.Left
}

local style_rule_30 = Instance.new "StyleRule"
style_rule_30.Parent = style_sheet
style_rule_30.Selector = "TextButton"
style_rule_30:SetProperties{
	["FontFace"] = Font.fromName("Oswald", Enum.FontWeight.Regular, Enum.FontStyle.Normal), 
	["TextXAlignment"] = Enum.TextXAlignment.Center
}

local style_rule_31 = Instance.new "StyleRule"
style_rule_31.Parent = style_sheet
style_rule_31.Selector = ".option"
style_rule_31:SetProperties{
	["BackgroundTransparency"] = 0.8
}

local style_rule_32 = Instance.new "StyleRule"
style_rule_32.Parent = style_sheet
style_rule_32.Selector = ".pages-nav > .tab.active"
style_rule_32.Priority = 2
style_rule_32:SetProperties{
	["TextColor3"] = Color3.fromRGB(255, 120, 120)
}

local style_rule_33 = Instance.new "StyleRule"
style_rule_33.Parent = style_sheet
style_rule_33.Selector = ".option.active"
style_rule_33.Priority = 1
style_rule_33:SetProperties{
	["BackgroundTransparency"] = 0.2, 
	["FontFace"] = Font.fromName("Oswald", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
}

local style_rule_34 = Instance.new "StyleRule"
style_rule_34.Parent = style_sheet
style_rule_34.Selector = ".solid"
style_rule_34:SetProperties{
	["BackgroundTransparency"] = 0.2
}

local style_rule_35 = Instance.new "StyleRule"
style_rule_35.Parent = style_sheet
style_rule_35.Selector = ".bg-2"
style_rule_35:SetProperties{
	["BackgroundTransparency"] = 0.5
}

local style_rule_36 = Instance.new "StyleRule"
style_rule_36.Parent = style_sheet
style_rule_36.Selector = ".bg-3"
style_rule_36:SetProperties{
	["BackgroundTransparency"] = 0.7
}

local style_rule_37 = Instance.new "StyleRule"
style_rule_37.Parent = style_sheet
style_rule_37.Selector = "ScrollingFrame"
style_rule_37:SetProperties{
	["AutomaticCanvasSize"] = Enum.AutomaticSize.Y, 
	["ScrollBarImageColor3"] = Color3.fromRGB(0, 0, 0), 
	["ScrollBarThickness"] = 2, 
	["CanvasSize"] = UDim2.new(0, 0, 0, 0)
}

local style_rule_38 = Instance.new "StyleRule"
style_rule_38.Parent = style_sheet
style_rule_38.Selector = ".header::UICorner, .solid::UICorner, .background::UICorner, .option::UICorner"
style_rule_38.Priority = 1
style_rule_38:SetProperties{
	["CornerRadius"] = UDim.new(0, 4)
}

local style_rule_39 = Instance.new "StyleRule"
style_rule_39.Parent = style_sheet
style_rule_39.Selector = ".container"
style_rule_39.Priority = 1
style_rule_39:SetProperties{
	["AutomaticSize"] = Enum.AutomaticSize.XY, 
	["BackgroundTransparency"] = 1, 
	["Size"] = UDim2.new(1, 0, 1, 0)
}

local style_rule_40 = Instance.new "StyleRule"
style_rule_40.Parent = style_sheet
style_rule_40.Selector = ".square-action-button"
style_rule_40.Priority = 1
style_rule_40:SetProperties{
	["Size"] = UDim2.new(0, 40, 0, 40)
}

local style_rule_41 = Instance.new "StyleRule"
style_rule_41.Parent = style_sheet
style_rule_41.Selector = ".stroke::UIStroke, .research-preview.editable::UIStroke, .item-filters-preview.editable::UIStroke, .square-action-button::UIStroke, .recipes::UIStroke"
style_rule_41.Priority = 1
style_rule_41:SetProperties{
	["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border, 
	["LineJoinMode"] = Enum.LineJoinMode.Round, 
	["Thickness"] = 1, 
	["Transparency"] = 0.9, 
	["Color"] = Color3.fromRGB(255, 255, 255)
}

local style_rule_42 = Instance.new "StyleRule"
style_rule_42.Parent = style_sheet
style_rule_42.Selector = ".item-filters-preview.editable.active::UIStroke"
style_rule_42:SetProperties{
	["Color"] = Color3.fromRGB(255, 120, 120)
}

local style_rule_43 = Instance.new "StyleRule"
style_rule_43.Parent = style_sheet
style_rule_43.Selector = ".container-v"
style_rule_43.Priority = 1
style_rule_43:SetProperties{
	["BackgroundTransparency"] = 1, 
	["Size"] = UDim2.new(1, 0, 0, 0), 
	["AutomaticSize"] = Enum.AutomaticSize.Y
}

local style_rule_44 = Instance.new "StyleRule"
style_rule_44.Parent = style_sheet
style_rule_44.Selector = ".container-h"
style_rule_44.Priority = 1
style_rule_44:SetProperties{
	["BackgroundTransparency"] = 1, 
	["Size"] = UDim2.new(0, 0, 1, 0), 
	["AutomaticSize"] = Enum.AutomaticSize.X
}

local style_rule_45 = Instance.new "StyleRule"
style_rule_45.Parent = style_sheet
style_rule_45.Selector = ".container-scroll-v"
style_rule_45.Priority = 1
style_rule_45:SetProperties{
	["BackgroundTransparency"] = 1
}

local style_rule_46 = Instance.new "StyleRule"
style_rule_46.Parent = style_sheet
style_rule_46.Selector = ".description"
style_rule_46.Priority = 1
style_rule_46:SetProperties{
	["AutomaticSize"] = Enum.AutomaticSize.Y, 
	["TextWrapped"] = true, 
	["TextColor3"] = Color3.fromRGB(200, 200, 200), 
	["TextTruncate"] = Enum.TextTruncate.AtEnd, 
	["Size"] = UDim2.new(1, 0, 0, 0), 
	["TextSize"] = 13
}

local style_rule_47 = Instance.new "StyleRule"
style_rule_47.Parent = style_sheet
style_rule_47.Selector = ".header"
style_rule_47:SetProperties{
	["BackgroundTransparency"] = 0.2, 
	["Size"] = UDim2.new(1, 0, 0, 40)
}

local style_rule_48 = Instance.new "StyleRule"
style_rule_48.Parent = style_sheet
style_rule_48.Selector = ".subtitle"
style_rule_48.Priority = 1
style_rule_48:SetProperties{
	["Size"] = UDim2.new(0, 0, 1, 0), 
	["TextSize"] = 16
}

local style_rule_49 = Instance.new "StyleRule"
style_rule_49.Parent = style_sheet
style_rule_49.Selector = ".title"
style_rule_49:SetProperties{
	["TextSize"] = 20, 
	["Size"] = UDim2.new(0, 0, 1, 0)
}

local style_rule_50 = Instance.new "StyleRule"
style_rule_50.Parent = style_sheet
style_rule_50.Selector = ".header >> .title::UIPadding"
style_rule_50:SetProperties{
	["PaddingLeft"] = UDim.new(0, 10), 
	["PaddingRight"] = UDim.new(0, 10)
}

local style_rule_51 = Instance.new "StyleRule"
style_rule_51.Parent = style_sheet
style_rule_51.Selector = ".background"
style_rule_51.Priority = 1
style_rule_51:SetProperties{
	["BackgroundTransparency"] = 0.9
}

local style_rule_52 = Instance.new "StyleRule"
style_rule_52.Parent = style_sheet
style_rule_52.Selector = ".pad-t-2::UIPadding"
style_rule_52:SetProperties{
	["PaddingTop"] = UDim.new(0, 2)
}

local style_rule_53 = Instance.new "StyleRule"
style_rule_53.Parent = style_sheet
style_rule_53.Selector = ".pad-l-5::UIPadding"
style_rule_53:SetProperties{
	["PaddingLeft"] = UDim.new(0, 5)
}

local style_rule_54 = Instance.new "StyleRule"
style_rule_54.Parent = style_sheet
style_rule_54.Selector = ".pad-r-5::UIPadding"
style_rule_54:SetProperties{
	["PaddingRight"] = UDim.new(0, 5)
}

local style_rule_55 = Instance.new "StyleRule"
style_rule_55.Parent = style_sheet
style_rule_55.Selector = ".pad-t-5::UIPadding"
style_rule_55:SetProperties{
	["PaddingTop"] = UDim.new(0, 5)
}

local style_rule_56 = Instance.new "StyleRule"
style_rule_56.Parent = style_sheet
style_rule_56.Selector = ".pad-b-5::UIPadding"
style_rule_56:SetProperties{
	["PaddingBottom"] = UDim.new(0, 5)
}

local style_rule_57 = Instance.new "StyleRule"
style_rule_57.Parent = style_sheet
style_rule_57.Selector = ".pad-l-10::UIPadding"
style_rule_57:SetProperties{
	["PaddingLeft"] = UDim.new(0, 10)
}

local style_rule_58 = Instance.new "StyleRule"
style_rule_58.Parent = style_sheet
style_rule_58.Selector = ".pad-r-10::UIPadding"
style_rule_58:SetProperties{
	["PaddingRight"] = UDim.new(0, 10)
}

local style_rule_59 = Instance.new "StyleRule"
style_rule_59.Parent = style_sheet
style_rule_59.Selector = ".pad-t-10::UIPadding"
style_rule_59:SetProperties{
	["PaddingTop"] = UDim.new(0, 10)
}

local style_rule_60 = Instance.new "StyleRule"
style_rule_60.Parent = style_sheet
style_rule_60.Selector = ".pad-b-10::UIPadding"
style_rule_60:SetProperties{
	["PaddingBottom"] = UDim.new(0, 10)
}

local style_rule_61 = Instance.new "StyleRule"
style_rule_61.Parent = style_sheet
style_rule_61.Selector = ".pad-l-30::UIPadding"
style_rule_61:SetProperties{
	["PaddingLeft"] = UDim.new(0, 30)
}

local style_rule_62 = Instance.new "StyleRule"
style_rule_62.Parent = style_sheet
style_rule_62.Selector = ".pad-r-30::UIPadding"
style_rule_62:SetProperties{
	["PaddingRight"] = UDim.new(0, 30)
}

local style_rule_63 = Instance.new "StyleRule"
style_rule_63.Parent = style_sheet
style_rule_63.Selector = ".pad-5::UIPadding"
style_rule_63:SetProperties{
	["PaddingLeft"] = UDim.new(0, 5), 
	["PaddingRight"] = UDim.new(0, 5), 
	["PaddingTop"] = UDim.new(0, 5), 
	["PaddingBottom"] = UDim.new(0, 5)
}

local style_rule_64 = Instance.new "StyleRule"
style_rule_64.Parent = style_sheet
style_rule_64.Selector = ".text-c"
style_rule_64:SetProperties{
	["TextXAlignment"] = Enum.TextXAlignment.Center
}

local style_rule_65 = Instance.new "StyleRule"
style_rule_65.Parent = style_sheet
style_rule_65.Selector = ".text-l"
style_rule_65:SetProperties{
	["TextXAlignment"] = Enum.TextXAlignment.Left
}

local style_rule_66 = Instance.new "StyleRule"
style_rule_66.Parent = style_sheet
style_rule_66.Selector = ".text-r"
style_rule_66:SetProperties{
	["TextXAlignment"] = Enum.TextXAlignment.Right
}

local style_rule_67 = Instance.new "StyleRule"
style_rule_67.Parent = style_sheet
style_rule_67.Selector = ".ty-t"
style_rule_67:SetProperties{
	["TextYAlignment"] = Enum.TextYAlignment.Top
}

local style_rule_68 = Instance.new "StyleRule"
style_rule_68.Parent = style_sheet
style_rule_68.Selector = ".ty-c"
style_rule_68:SetProperties{
	["TextYAlignment"] = Enum.TextYAlignment.Center
}

local style_rule_69 = Instance.new "StyleRule"
style_rule_69.Parent = style_sheet
style_rule_69.Selector = ".ty-b"
style_rule_69:SetProperties{
	["TextYAlignment"] = Enum.TextYAlignment.Bottom
}

return style_sheet