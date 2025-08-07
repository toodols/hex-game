for _, child in script:GetChildren() do
	assert(child:IsA "ModuleScript", "Expected child to be a ModuleScript")
	require(child)
end

return {}
