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
	local offset = 0

	local reader = {}
	local types = {
		read_f64 = "d",
		read_u8 = "I1",
		read_i8 = "i1",
		read_u16 = "I2",
		read_i32 = "i4",
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

type Writer = typeof(write())
type Reader = typeof(read "")
export type Schema<T> = {
	write: (writer: Writer, data: T) -> (),
	read: (reader: Reader) -> T,
}

local f64 = {
	write = function(writer, data)
		writer.write_f64(data)
	end,
	read = function(reader)
		return reader.read_f64()
	end,
}

local str = {
	write = function(writer, data)
		writer.write_string(data)
	end,
	read = function(reader)
		return reader.read_string()
	end,
}

local i32 = {
	write = function(writer, data)
		writer.write_i32(data)
	end,
	read = function(reader)
		return reader.read_i32()
	end,
}

local u8 = {
	write = function(writer, data)
		writer.write_u8(data)
	end,
	read = function(reader)
		return reader.read_u8()
	end,
}

local boolean = {
	write = function(writer, data)
		if data == true then
			writer.write_u8(1)
		elseif data == false then
			writer.write_u8(0)
		else
			error "invalid boolean"
		end
	end,
	read = function(reader)
		return reader.read_u8() == 1
	end,
}

local array = function<T>(schema: Schema<T>): Schema<{ T }>
	return {
		write = function(writer, data)
			local count = 0
			for _ in data do
				count += 1
			end
			writer.write_u16(count)
			for _, v in data do
				schema.write(writer, v)
			end
		end,
		read = function(reader)
			local count = reader.read_u16()
			local data = {}
			for i = 1, count do
				data[i] = schema.read(reader)
			end
			return data
		end,
	}
end

local map = function<K, V>(key_schema: Schema<K>, value_schema: Schema<V>): Schema<{ [K]: V }>
	return {
		write = function(writer, data)
			local count = 0
			for _ in data do
				count += 1
			end
			writer.write_u16(count)
			for k, v in data do
				key_schema.write(writer, k)
				value_schema.write(writer, v)
			end
		end,
		read = function(reader)
			local count = reader.read_u16()
			local data = {}
			for i = 1, count do
				local k = key_schema.read(reader)
				local v = value_schema.read(reader)
				data[k] = v
			end
			return data
		end,
	}
end

local option = function<T>(schema: Schema<T>): Schema<T?>
	return {
		write = function(writer, data)
			if data == nil then
				writer.write_u8(0)
				return
			end
			-- microoptimization so option(boolean) uses 1 byte only
			if schema == boolean then
				if data == false then
					writer.write_u8(1)
				elseif data == true then
					writer.write_u8(2)
				else
					error "erm"
				end
				return
			end
			writer.write_u8(1)
			schema.write(writer, data)
		end,
		read = function(reader)
			local value = reader.read_u8()
			if value == 0 then
				return nil
			end
			if schema == boolean then
				if value == 1 then
					return false
				elseif value == 2 then
					return true
				else
					error "erm"
				end
			end
			return schema.read(reader)
		end,
	}
end

local enum = function<T>(values: { T }): Schema<T>
	local value_to_index = {}
	for i, value in values do
		value_to_index[value] = i
	end

	return {
		write = function(writer, data)
			writer.write_u8(value_to_index[data])
		end,
		read = function(reader)
			return values[reader.read_u8()]
		end,
	}
end

local struct = function<T>(object: { [string]: Schema<any> | any }): Schema<T>
	local keys = {}
	for k in object do
		table.insert(keys, k)
	end

	return {
		write = function(writer, data)
			for _, key in keys do
				local value = data[key]
				local schema = object[key]
				schema.write(writer, value)
			end
		end,
		read = function(reader)
			local data = {}
			for _, key in keys do
				local schema = object[key]
				data[key] = schema.read(reader)
			end
			return data
		end,
	}
end

local function deep_clone(original)
	local clone = table.clone(original)
	for key, value in original do
		if type(value) == "table" then
			clone[key] = deep_clone(value)
		end
	end
	return clone
end

local const = function<T>(value: T): Schema<T>
	return {
		write = function(writer, data)
			-- do nothing
		end,
		read = function(reader)
			if type(value) == "table" then
				return deep_clone(value)
			else
				return value
			end
		end,
	}
end

local tuple = function<T>(schemas: { Schema<any> }): Schema<{ T }>
	return {
		write = function(writer, data)
			for i, schema in schemas do
				schema.write(writer, data[i])
			end
		end,
		read = function(reader)
			local data = {}
			for i, schema in schemas do
				data[i] = schema.read(reader)
			end
			return data
		end,
	}
end

local debug_size = function(label, schema)
	return {
		write = function(writer, data)
			writer.begin_record_size()
			schema.write(writer, data)
			print(label, "is", writer.end_record_size(), "bytes")
		end,

		read = function(reader)
			return schema.read(reader)
		end,
	}
end

-- Compactly stores {[Id]: {[key]: Id, ...}} as an array by only storing Id once per entry
local collect_by_key = function(schema, key)
	return {
		write = function(writer, data)
			local count = 0
			for _ in data do
				count += 1
			end
			writer.write_u16(count)
			for _, entry in data do
				schema.write(writer, entry)
			end
		end,
		read = function(reader)
			local count = reader.read_u16()
			local data = {}
			for i = 1, count do
				local entry = schema.read(reader)
				data[entry[key]] = entry
			end
			return data
		end,
	}
end

local tagged_union = function<T>(cases: { [string]: Schema<T> }, tag_key: string): Schema<T>
	local cases_keys = {}
	for k in cases do
		table.insert(cases_keys, k)
	end
	local discriminant_schema = enum(cases_keys)
	return {
		write = function(writer, data)
			local tag = data[tag_key]
			discriminant_schema.write(writer, tag)
			cases[tag].write(writer, data)
		end,
		read = function(reader)
			local tag = discriminant_schema.read(reader)
			return cases[tag].read(reader)
		end,
	}
end

local roblox_types = enum {
	"string",
	"number",
	"boolean",
	"Vector3",
	"Vector2",
	"Color3",
	"UDim2",
	"BrickColor",
	"table",
}

local dynamic_table

local dynamic = {
	write = function(writer, data)
		local t = typeof(data)
		if t == "number" then
			roblox_types.write(writer, t)
			writer.write_f64(data)
		elseif t == "string" then
			roblox_types.write(writer, t)
			writer.write_string(data)
		elseif t == "boolean" then
			roblox_types.write(writer, t)
			boolean.write(writer, data)
		elseif t == "table" then
			roblox_types.write(writer, t)
			dynamic_table.write(writer, data)
		end
	end,
	read = function(reader)
		local t = roblox_types.read(reader)
		if t == "number" then
			return reader.read_f64()
		elseif t == "string" then
			return reader.read_string()
		elseif t == "boolean" then
			return boolean.read(reader)
		elseif t == "table" then
			return dynamic_table.read(reader)
		end
		return nil
	end,
}

dynamic_table = map(dynamic, dynamic)

function test()
	local person = struct {
		type = const "person",
		name = str,
		age = i32,
		alive = boolean,
	}
	local writer = write()
	i32.write(writer, 30)
	local sample = {
		type = "person",
		name = "John Doe",
		age = 30,
		alive = true,
	}
	person.write(writer, sample)
	dynamic_table.write(writer, sample)
	local text = writer.to_string()
	local reader = read(text)
	assert(i32.read(reader) == 30, "number")
	local data = person.read(reader)
	assert(data.type == "person", "type")
	assert(data.name == "John Doe", "name")
	assert(data.age == 30, "age")
	assert(data.alive == true, "alive")
	local data2 = dynamic_table.read(reader)
	assert(data2.type == "person", "type")
	assert(data2.name == "John Doe", "name")
	assert(data2.age == 30, "age")
	assert(data2.alive == true, "alive")
end

test()

return {
	f64 = f64,
	i32 = i32,
	u8 = u8,
	str = str,
	array = array,
	boolean = boolean,
	dynamic = dynamic,
	const = const,
	tuple = tuple,
	enum = enum,
	struct = struct,
	option = option,
	write = write,
	read = read,
	map = map,
	test = test,
	debug_size = debug_size,
	collect_by_key = collect_by_key,
	tagged_union = tagged_union,
}
