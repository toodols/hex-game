local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ServerStorage = game:GetService "ServerStorage"

function load<T>(path: string): T
	local segments = path:split "/"
	local current_instance = game:GetService("RunService"):IsClient()
			and ReplicatedStorage:FindFirstChild "ReplicatedAssets"
		or ServerStorage:FindFirstChild "Assets"

	for _, segment in segments do
		current_instance = current_instance:FindFirstChild(segment)
		if not current_instance then
			error("Instance not found in path: " .. path)
		end
	end

	return (current_instance :: any) :: T
end

function clone(filter: table, source: Instance, destination: Instance): ()
	for k, v in filter do
		if v == true then
			source[k]:Clone().Parent = destination
		elseif type(v) == "table" then
			local dest = Instance.new "Folder"
			dest.Parent = destination
			dest.Name = k
			clone(v, source[k], dest)
		end
	end
end

return { load = load, clone = clone }
