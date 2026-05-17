local ServerScriptService = game:GetService "ServerScriptService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local OpenSkill = require(ServerScriptService.Server.openskill)
local util = require(ReplicatedStorage.Shared.util)
local assert_eq = util.assert_eq

local tests = {}
function tests.openskill()
	local alice = OpenSkill.Rating()
	local bob = OpenSkill.Rating()
	local charlie = OpenSkill.Rating()

	-- charlie always loses
	for i = 1, 10 do
		OpenSkill.Rate { { alice }, { bob, charlie } }
		OpenSkill.Rate { { alice, bob }, { charlie } }
		OpenSkill.Rate { { bob }, { alice } }
		OpenSkill.Rate { { bob }, { alice, charlie } }
		OpenSkill.Rate { { alice }, { bob, charlie } }
	end

	local alice_ordinal = OpenSkill.Ordinal(alice)
	local bob_ordinal = OpenSkill.Ordinal(bob)
	local charlie_ordinal = OpenSkill.Ordinal(charlie)

	assert(bob_ordinal > alice_ordinal, "bob should be better than alice")
	assert(alice_ordinal > charlie_ordinal, "alice should be better than charlie")
	assert(bob_ordinal > charlie_ordinal, "bob should be better than charlie")

	OpenSkill.Rate({ { alice }, { bob } }, { rank = { 0, 0 } })

	local alice_new_ordinal = OpenSkill.Ordinal(alice)
	local bob_new_ordinal = OpenSkill.Ordinal(bob)
	assert(alice_new_ordinal > alice_ordinal, "alice's ordinal should go up")
	assert(bob_new_ordinal < bob_ordinal, "bob's ordinal should go down")
end

function tests.bench_encode_decode_coord()
	local N = 100000
	local function rand_coord()
		local x = math.random(-1000, 1000)
		local y = math.random(-1000, 1000)
		return { x, y, -x - y }
	end
	do
		local t0 = tick()
		for i = 1, N do
			local coord = rand_coord()
			assert_eq(coord, coord)
		end
		local t1 = tick()
		print("Doing literally nothing took", t1 - t0, "average", (t1 - t0) / N)
	end
	do
		local t0 = tick()
		for i = 1, N do
			local coord = rand_coord()
			local encoded = string.format("%d %d", coord[1], coord[2])
			local res = string.split(encoded, " ")
			local x = tonumber(res[1])
			local y = tonumber(res[2])
			local z = -x - y
			assert_eq(coord, { x, y, z })
		end
		local t1 = tick()
		print("Encoding as a string took", t1 - t0, "average", (t1 - t0) / N)
	end

	do
		local t0 = tick()
		local BITS_PER_COMPONENT = 16
		local UNSIGNED_MAX = 2 ^ BITS_PER_COMPONENT
		local SIGNED_MAX = UNSIGNED_MAX / 2
		for i = 1, N do
			local coord = rand_coord()
			local encoded = (coord[1] + SIGNED_MAX) * UNSIGNED_MAX + coord[2] + SIGNED_MAX
			local decode_y = (encoded % UNSIGNED_MAX) - SIGNED_MAX
			local decode_x = math.floor(encoded / UNSIGNED_MAX) - SIGNED_MAX
			local decoded = { decode_x, decode_y, -decode_x - decode_y }
			assert_eq(coord, decoded)
		end
		local t1 = tick()
		print("Bit shift took", t1 - t0, "average", (t1 - t0) / N)
	end
	do
		local t0 = tick()
		local BITS_PER_COMPONENT = 16
		local UNSIGNED_MAX = 2 ^ BITS_PER_COMPONENT
		local SIGNED_MAX = UNSIGNED_MAX / 2

		for i = 1, N do
			local coord = rand_coord()

			local encoded = bit32.bor(bit32.lshift(coord[1] + SIGNED_MAX, BITS_PER_COMPONENT), coord[2] + SIGNED_MAX)

			local decode_y = bit32.band(encoded, UNSIGNED_MAX - 1) - SIGNED_MAX

			local decode_x = bit32.rshift(encoded, BITS_PER_COMPONENT) - SIGNED_MAX

			local decoded = { decode_x, decode_y, -decode_x - decode_y }

			assert_eq(coord, decoded)
		end

		local t1 = tick()
		print("chatgptified bit shift took", t1 - t0, "average", (t1 - t0) / N)
	end
end
return tests
