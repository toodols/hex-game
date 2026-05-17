local ReplicatedStorage = game:GetService "ReplicatedStorage"
local result_mod = require(ReplicatedStorage.Shared.result)
local util = require(ReplicatedStorage.Shared.util)

local err = result_mod.err
local ok = result_mod.ok
type Result<T, E = nil> = result_mod.Result<T, E>

export type Writer = {
	write_f64: (number) -> (),
	write_u8: (number) -> (),
	write_i8: (number) -> (),
	write_u16: (number) -> (),
	write_i32: (number) -> (),
	write_i64: (number) -> (),
	write_string: (string) -> (),
	write_usize: (number) -> (),
}
export type Reader = {
	read_f64: () -> number,
	read_u8: () -> number,
	read_i8: () -> number,
	read_u16: () -> number,
	read_i32: () -> number,
	read_i64: () -> number,
	read_string: () -> string,
	read_usize: () -> number,
}

export type SerializingSchema<T> = {
	write: (writer: Writer, data: T) -> (),
	read: (reader: Reader) -> T,
}

export type ValidatingSchema<T> = {
	validate: (data: T) -> Result<T>,
}

export type Schema<T> = SerializingSchema<T> & ValidatingSchema<T> & {
	label: string?,
}

local with_label = function<Args, T>(
	constructor: (...Args) -> Schema<T>
): (label: string) -> (...Args) -> Schema<T> | (...Args) -> Schema<T>
	return function(...)
		local label = ...
		if type(label) == "string" then
			return function(...)
				local schema = constructor(...)
				schema.label = label
				return schema
			end
		else
			return constructor(...)
		end
	end
end

local f64: Schema<number> = {
	label = "f64",
	write = function(writer, data)
		writer.write_f64(data)
	end,
	read = function(reader)
		return reader.read_f64()
	end,
	validate = function(data)
		if type(data) ~= "number" then
			return err()
		end
		return ok(data)
	end,
}

local str: Schema<string> = {
	label = "str",
	write = function(writer, data)
		writer.write_string(data)
	end,
	read = function(reader)
		return reader.read_string()
	end,
	validate = function(data)
		if type(data) ~= "string" then
			return err()
		end
		return ok(data)
	end,
}

local i32: Schema<number> = {
	label = "i32",
	write = function(writer, data)
		writer.write_i32(data)
	end,
	read = function(reader)
		return reader.read_i32()
	end,
	validate = function(data)
		if type(data) ~= "number" or data < -2147483648 or data > 2147483647 then
			return err()
		end
		return ok(data)
	end,
}

local u8: Schema<number> = {
	label = "u8",
	write = function(writer, data)
		writer.write_u8(data)
	end,
	read = function(reader)
		return reader.read_u8()
	end,
	validate = function(data)
		if type(data) ~= "number" or data < 0 or data > 255 then
			return err()
		end
		return ok(data)
	end,
}

local u16: Schema<number> = {
	label = "u16",
	write = function(writer, data)
		writer.write_u16(data)
	end,
	read = function(reader)
		return reader.read_u16()
	end,
	validate = function(data)
		if type(data) ~= "number" or data < 0 or data > 65535 then
			return err()
		end
		return ok(data)
	end,
}

local boolean: Schema<boolean> = {
	label = "bool",
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
	validate = function(data)
		if type(data) ~= "boolean" then
			return err()
		end
		return ok(data)
	end,
}

local array = with_label(function<T>(schema: Schema<T>): Schema<{ T }>
	return {
		label = `[{schema.label or "unnamed"}]`,
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
		validate = function(data)
			if type(data) ~= "table" then
				return err()
			end
			for _, v in data do
				local result = schema.validate(v)
				if not result.is_ok then
					return err()
				end
			end
			return ok(data)
		end,
	}
end)

-- where entries are optional
local map = with_label(function<K, V>(key_schema: Schema<K>, value_schema: Schema<V>): Schema<{ [K]: V }>
	return {
		label = `\{[{key_schema.label}]: {value_schema.label}\}`,
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
		validate = function(data)
			if type(data) ~= "table" then
				return err()
			end
			for k, v in data do
				local key_result = key_schema.validate(k)
				if not key_result.is_ok then
					return err()
				end
				local value_result = value_schema.validate(v)
				if not value_result.is_ok then
					return err()
				end
			end
			return ok(data)
		end,
	}
end)

local option = with_label(function<T>(schema: Schema<T>): Schema<T?>
	return {
		label = `{schema.label}?`,
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
		validate = function(data)
			if data == nil then
				return ok(nil)
			end
			local result = schema.validate(data)
			if not result.is_ok then
				return err()
			end
			return ok(data)
		end,
	}
end)

local enum = with_label(function<T>(values: { T }): Schema<T>
	local value_to_index = {}
	for i, value in values do
		value_to_index[value] = i
	end

	return {
		write = function(writer, data)
			if value_to_index[data] == nil then
				error("Invalid enum value: " .. tostring(data))
			end
			writer.write_u8(value_to_index[data])
		end,
		read = function(reader)
			return values[reader.read_u8()]
		end,
		validate = function(data)
			if value_to_index[data] == nil then
				return err()
			end
			return ok(data)
		end,
	}
end)

-- i32 with a special case for math.huge
local i32_infinite = {
	write = function(writer, data)
		if data == math.huge then
			writer.write_i32(0x7fffffff)
			return
		end
		writer.write_i32(data)
	end,
	read = function(reader)
		local value = reader.read_i32()
		if value == 0x7fffffff then
			return math.huge
		end
		return value
	end,
}

local struct = with_label(function<T>(object: { [string]: Schema<any> | any }): Schema<T>
	for key, schema in object do
		if schema.read == nil and schema.write == nil and schema.validate == nil then
			error("the schema for " .. key .. " doesn't look like a schema")
		end
	end
	local self
	self = {
		object = object,
		write = function(writer, data)
			for key, schema in object do
				local value = data[key]
				schema.write(writer, value)
			end
		end,
		read = function(reader)
			local data = {}
			for key, schema in object do
				data[key] = schema.read(reader)
			end
			return data
		end,
		validate = function(data)
			if type(data) ~= "table" then
				return err()
			end
			for key, schema in object do
				local value = data[key]
				local result = schema.validate(value)
				if not result.is_ok then
					return err()
				end
			end
			return ok(data)
		end,
	}
	return self
end)

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
		label = tostring(value),
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
		validate = function(data)
			if data ~= value then
				return err()
			end
			return ok(data)
		end,
	}
end

local tuple = function<T>(schemas: { Schema<any> }): Schema<{ T }>
	return {
		label = "tuple",
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
		validate = function(data)
			if type(data) ~= "table" or #data ~= #schemas then
				return err()
			end
			for i, schema in schemas do
				local result = schema.validate(data[i])
				if not result.is_ok then
					return err()
				end
			end
			return ok(data)
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
local collect_by_key = function<T>(schema: Schema<T>, key: string): Schema<{ [string]: T }>
	if schema.label == nil then
		error "label is nil"
	end
	return {
		label = `{schema.label} by {key}`,
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
		validate = function(data)
			if type(data) ~= "table" then
				return err()
			end
			local seen_keys = {}
			for _, entry in data do
				local result = schema.validate(entry)
				if not result.is_ok then
					return err()
				end
				local entry_key = entry[key]
				if seen_keys[entry_key] then
					return err()
				end
				seen_keys[entry_key] = true
			end
			return ok(data)
		end,
	}
end

local tagged_union = with_label(function<T>(cases: { [string]: Schema<T> }, tag_key: string): Schema<T>
	local cases_keys = {}
	for k in cases do
		table.insert(cases_keys, k)
	end
	local discriminant_schema = enum(cases_keys)
	return {
		label = "tagged union",
		write = function(writer, data)
			local tag = data[tag_key]
			discriminant_schema.write(writer, tag)
			cases[tag].write(writer, data)
		end,
		read = function(reader)
			local tag = discriminant_schema.read(reader)
			return cases[tag].read(reader)
		end,
		validate = function(data)
			local tag = data[tag_key]
			if not cases[tag] then
				return err()
			end
			local result = cases[tag].validate(data)
			if not result.is_ok then
				return err()
			end
			return ok(data)
		end,
	}
end)

local keycode_set = {}
for _, keycode in Enum.KeyCode:GetEnumItems() do
	keycode_set[keycode] = true
end
local keycode: Schema<Enum.KeyCode> = {
	write = function(writer, data: Enum.KeyCode)
		writer.write_u16(data.Value)
	end,

	read = function(reader)
		local value = reader.read_u16()
		return (Enum.KeyCode :: any):FromValue(value)
	end,
	validate = function(data: Enum.KeyCode)
		if not keycode_set[data] then
			return err()
		end
		return ok(data)
	end,
}

local roblox_types = enum "roblox_type" {
	"string",
	"number",
	"boolean",
	"Vector3",
	"Vector2",
	"Color3",
	"UDim2",
	"BrickColor",
	"table",
	"nil",
}

local dynamic_table

local dynamic: Schema<any> = {
	label = "dyn",
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
		elseif t == "nil" then
			roblox_types.write(writer, t)
		elseif t == "function" then
			error "can't serialize functions"
		else
			error("wrote nothing. type is " .. t)
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
		elseif t == "nil" then
			return nil
		end
		return nil
	end,
	validate = function(data)
		return ok(data)
	end,
}

dynamic_table = map(dynamic, dynamic)

local error_schema: Schema<any> = {
	label = "error",
	write = function()
		error "error"
	end,
	read = function()
		error "error"
	end,
	validate = function()
		error "error"
	end,
}

return {
	error = error_schema,
	f64 = f64,
	i32 = i32,
	i32_infinite = i32_infinite,
	u8 = u8,
	u16 = u16,
	str = str,
	array = array,
	boolean = boolean,
	dynamic = dynamic,
	dynamic_table = dynamic_table,
	const = const,
	tuple = tuple,
	enum = enum,
	struct = struct,
	option = option,
	map = map,
	debug_size = debug_size,
	collect_by_key = collect_by_key,
	tagged_union = tagged_union,
	keycode = keycode,
}
