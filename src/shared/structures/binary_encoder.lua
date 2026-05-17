local function write()
	local record_size = {}
	local text_buffer = {}
	local writer = {}

	function writer.begin_record_size()
		table.insert(record_size, #text_buffer)
	end
	function writer.end_record_size()
		local slice = {}
		local start = table.remove(record_size)
		for i = start, #text_buffer do
			table.insert(slice, text_buffer[i])
		end
		return table.concat(slice):len()
	end

	local types = {
		write_f64 = "d",
		write_u8 = "I1",
		write_u16 = "I2",
		write_i8 = "i1",
		write_string = "s2",
		write_usize = "I4",
		write_i32 = "i4",
		write_i64 = "i8",
	}

	for k, v in types do
		writer[k] = function(data)
			if data == nil or type(data) == "table" then
				error "erm"
			end
			if v[1] == "s" and type(data) ~= "string" then
				error(data .. " is not a string")
			end
			table.insert(text_buffer, string.pack(v, data))
		end
	end
	function writer.to_string()
		return table.concat(text_buffer)
	end
	return writer
end

local function read(data)
	if type(data) ~= "string" then
		error(data .. " is not a string")
	end
	local offset = 0

	local reader = {}
	local types = {
		read_f64 = "d",
		read_u8 = "I1",
		read_i8 = "i1",
		read_u16 = "I2",
		read_i32 = "i4",
		read_i64 = "i8",
		read_string = "s2",
		read_usize = "T",
	}
	for k, v in types do
		reader[k] = function()
			local val, n = string.unpack(v, data, offset)
			offset = n
			return val
		end
	end
	return reader
end

return {
	read = read,
	write = write,
}
