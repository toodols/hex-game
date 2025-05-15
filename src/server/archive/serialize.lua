local function write()
	local format = {}
	local buffer: { any } = {}
	local record_size = {}

	local writer = {}
	function writer.begin_record_size()
		table.insert(record_size, #buffer)
	end
	function writer.end_record_size()
		local slice = {}
		local format_slice = {}
		local start = table.remove(record_size)
		for i = start, #buffer do
			table.insert(format_slice, format[i])
			table.insert(slice, buffer[i])
		end
		return #string.pack(table.concat(format_slice), table.unpack(slice))
	end
	function writer.write_f64(n: number)
		table.insert(format, "d")
		table.insert(buffer, n)
	end
	function writer.write_u8(n: number)
		table.insert(format, "I1")
		table.insert(buffer, n)
	end
	function writer.write_i8(n: number)
		table.insert(format, "i1")
		table.insert(buffer, n)
	end
	function writer.write_string(s: string)
		table.insert(format, "s")
		table.insert(buffer, s)
	end
	function writer.write_usize(n: number)
		table.insert(format, "T")
		table.insert(buffer, n)
	end
	function writer.write_i32(n: number)
		table.insert(format, "i4")
		table.insert(buffer, n)
	end
	function writer.to_string()
		return string.pack(table.concat(format), table.unpack(buffer))
	end
	return writer
end

local function read(data)
	local offset = 0

	local reader = {}
	function reader.read_f64()
		local val, n = string.unpack("d", data, offset)
		offset = n
		return val
	end
	function reader.read_u8()
		local val, n = string.unpack("I1", data, offset)
		offset = n
		return val
	end
	function reader.read_i8()
		local val, n = string.unpack("i1", data, offset)
		offset = n
		return val
	end
	function reader.read_i32()
		local val, n = string.unpack("i4", data, offset)
		offset = n
		return val
	end
	function reader.read_string()
		local val, n = string.unpack("s", data, offset)
		offset = n
		return val
	end
	function reader.read_usize()
		local val, n = string.unpack("T", data, offset)
		offset = n
		return val
	end
	return reader
end

type Writer = typeof(write())
type Reader = typeof(read "")
export type Schema<T> = {
	write: (writer: Writer, data: T) -> (),
	read: (reader: Reader) -> T,
}

local double = {
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

local integer = {
	write = function(writer, data)
		writer.write_i32(data)
	end,
	read = function(reader)
		return reader.read_i32()
	end,
}

local boolean = {
	write = function(writer, data)
		if data then
			writer.write_u8(1)
		else
			writer.write_u8(0)
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
			writer.write_usize(count)
			for _, v in data do
				schema.write(writer, v)
			end
		end,
		read = function(reader)
			local count = reader.read_usize()
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
			writer.write_usize(count)
			for k, v in data do
				key_schema.write(writer, k)
				value_schema.write(writer, v)
			end
		end,
		read = function(reader)
			local count = reader.read_usize()
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
			writer.write_u8(1)
			schema.write(writer, data)
		end,
		read = function(reader)
			if reader.read_u8() == 0 then
				return nil
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

local const = function<T>(value: T): Schema<T>
	return {
		write = function(writer, data)
			-- do nothing
		end,
		read = function(reader)
			return value
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
			writer.write_usize(count)
			for _, entry in data do
				schema.write(writer, entry)
			end
		end,
		read = function(reader)
			local count = reader.read_usize()
			local data = {}
			for i = 1, count do
				local entry = schema.read(reader)
				data[entry[key]] = entry
			end
			return data
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
		age = integer,
		alive = boolean,
	}
	local writer = write()
	integer.write(writer, 30)
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
	assert(integer.read(reader) == 30, "number")
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
	double = double,
	integer = integer,
	string = str,
	array = array,
	boolean = boolean,
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
}
