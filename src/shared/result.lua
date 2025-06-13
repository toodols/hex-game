export type Result<T, E = nil> = {
	is_ok: true,
	ok: T,
} | {
	is_ok: false,
	err: E,
}

function err<T, E>(error: E?): Result<T, E>
	return {
		is_ok = false,
		err = error,
	}
end
function ok<T, E>(value: T): Result<T, E>
	return {
		is_ok = true,
		ok = value,
	}
end
function unwrap<T, E>(result: Result<T, E>): T
	if not result.is_ok then
		error(result.err or "unwrap on an error")
	end
	return result.ok :: T
end

function unwrap_or(result: Result<any, any>, default: any): any
	if not result.is_ok then
		return default
	end
	return result.ok
end

return {
	err = err,
	ok = ok,
	unwrap = unwrap,
	unwrap_or = unwrap_or,
}
