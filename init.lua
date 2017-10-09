
--= Teleport Potion mod by TenPlus1

-- Create teleport potion or pad, place then right-click to enter coords
-- and step onto pad or walk into the blue portal light, portal closes after
-- 10 seconds, pad remains, potions are throwable...  SFX are license Free...

-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")


-- max teleport distance
local dist = tonumber(minetest.settings:get("map_generation_limit") or 31000)

-- creative check
local creative_mode_cache = minetest.settings:get_bool("creative_mode")
function is_creative(name)
	return creative_mode_cache or minetest.check_player_privs(name, {creative = true})
end

local check_coordinates = function(str)

	if not str or str == "" then
		return nil
	end

	-- get coords from string
	local x, y, z, desc = string.match(str, "^(-?%d+),(-?%d+),(-?%d+),?(.*)$")

	-- check coords
	if x == nil or string.len(x) > 6
	or y == nil or string.len(y) > 6
	or z == nil or string.len(z) > 6 then
		return nil
	end

	-- convert string coords to numbers
	x = tonumber(x)
	y = tonumber(y)
	z = tonumber(z)

	-- are coords in map range ?
	if x > dist or x < -dist
	or y > dist or y < -dist
	or z > dist or z < -dist then
		return nil
	end

	-- return ok coords
	return {x = x, y = y, z = z, desc = desc}
end


-- particle effects
function tp_effect(pos)
	minetest.add_particlespawner({
		amount = 20,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -2, y = 1, z = -2},
		maxvel = {x = 2,  y = 2,  z = 2},
		minacc = {x = 0, y = -2, z = 0},
		maxacc = {x = 0, y = -4, z = 0},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1.5,
		texture = "particle.png",
		glow = 15,
	})
end


-- teleport portal
minetest.register_node("teleport_potion:portal", {
	drawtype = "plantlike",
	tiles = {
		{name="portal.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 1.0
			}
		}
	},
	light_source = 13,
	walkable = false,
	paramtype = "light",
	pointable = false,
	buildable_to = true,
	waving = 1,
	sunlight_propagates = true,
	damage_per_second = 1, -- walking into portal hurts player

	-- start timer when portal appears
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(10)
	end,

	-- remove portal after 10 seconds
	on_timer = function(pos)

		minetest.sound_play("portal_close", {
			pos = pos,
			gain = 1.0,
			max_hear_distance = 10
		})

		minetest.set_node(pos, {name = "air"})
	end,
})


-- teleport potion
minetest.register_node("teleport_potion:potion", {
	tiles = {"pad.png"},
	drawtype = "signlike",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	sunlight_propagates = true,
	description = S("Teleport Potion (place and right-click to enchant location)"),
	inventory_image = "potion.png",
	wield_image = "potion.png",
	groups = {dig_immediate = 3},
	selection_box = {type = "wallmounted"},

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		-- text entry formspec
		meta:set_string("formspec", "field[text;" .. S("Enter teleport coords (e.g. 200,20,-200)") .. ";${text}]")
		meta:set_string("infotext", S("Right-click to enchant teleport location"))
		meta:set_string("text", pos.x .. "," .. pos.y .. "," .. pos.z)

		-- set default coords
		meta:set_int("x", pos.x)
		meta:set_int("y", pos.y)
		meta:set_int("z", pos.z)
	end,

	-- throw potion when used like tool
	on_use = function(itemstack, user)

		throw_potion(itemstack, user)

		if not is_creative(user:get_player_name()) then
			itemstack:take_item()
			return itemstack
		end
	end,

	-- check if coords ok then open portal, otherwise return potion
	on_receive_fields = function(pos, formname, fields, sender)

		local coords = check_coordinates(fields.text)
		local name = sender:get_player_name()

		if coords then

			minetest.set_node(pos, {name = "teleport_potion:portal"})

			local meta = minetest.get_meta(pos)

			-- set portal destination
			meta:set_int("x", coords.x)
			meta:set_int("y", coords.y)
			meta:set_int("z", coords.z)

			-- portal open effect and sound
			tp_effect(pos)

			minetest.sound_play("portal_open", {
				pos = pos,
				gain = 1.0,
				max_hear_distance = 10
			})

		else
			minetest.chat_send_player(name, S("Potion failed!"))
			minetest.set_node(pos, {name = "air"})
			minetest.add_item(pos, "teleport_potion:potion")
		end
	end,
})


-- teleport potion recipe
minetest.register_craft({
	output = "teleport_potion:potion",
	recipe = {
		{"", "default:diamond", ""},
		{"default:diamond", "vessels:glass_bottle", "default:diamond"},
		{"", "default:diamond", ""},
	},
})


-- teleport pad
minetest.register_node("teleport_potion:pad", {
	tiles = {"padd.png", "padd.png^[transformFY"},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	legacy_wallmounted = true,
	walkable = true,
	sunlight_propagates = true,
	description = S("Teleport Pad (place and right-click to enchant location)"),
	inventory_image = "padd.png",
	wield_image = "padd.png",
	light_source = 5,
	groups = {snappy = 3},
	node_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -6/16, 0.5}
	},

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		-- text entry formspec
		meta:set_string("formspec", "field[text;" .. S("Enter teleport coords (e.g. 200,20,-200,Home)") .. ";${text}]")
		meta:set_string("infotext", S("Right-click to enchant teleport location"))
		meta:set_string("text", pos.x .. "," .. pos.y .. "," .. pos.z)

		-- set default coords
		meta:set_int("x", pos.x)
		meta:set_int("y", pos.y)
		meta:set_int("z", pos.z)
	end,

	-- once entered, check coords, if ok then return potion
	on_receive_fields = function(pos, formname, fields, sender)

		local name = sender:get_player_name()

		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return
		end

		local coords = check_coordinates(fields.text)

		if coords then

			local meta = minetest.get_meta(pos)

			meta:set_int("x", coords.x)
			meta:set_int("y", coords.y)
			meta:set_int("z", coords.z)
			meta:set_string("text", fields.text)

			if coords.desc and coords.desc ~= "" then

				meta:set_string("infotext", S("Teleport to @1", coords.desc))
			else
				meta:set_string("infotext", S("Pad Active (@1,@2,@3)",
					coords.x, coords.y, coords.z))
			end

			minetest.sound_play("portal_open", {
				pos = pos,
				gain = 1.0,
				max_hear_distance = 10
			})

		else
			minetest.chat_send_player(name, S("Teleport Pad coordinates failed!"))
		end
	end,
})


-- teleport pad recipe
minetest.register_craft({
	output = 'teleport_potion:pad',
	recipe = {
		{"teleport_potion:potion", 'default:glass', "teleport_potion:potion"},
		{"default:glass", "default:mese", "default:glass"},
		{"teleport_potion:potion", "default:glass", "teleport_potion:potion"}
	}
})


-- check portal & pad, teleport any entities on top
minetest.register_abm({
	label = "Potion/Pad teleportation",
	nodenames = {"teleport_potion:portal", "teleport_potion:pad"},
	interval = 2,
	chance = 1,
	catch_up = false,

	action = function(pos, node, active_object_count, active_object_count_wider)

		-- check objects inside pad/portal
		local objs = minetest.get_objects_inside_radius(pos, 1)

		if #objs == 0 then
			return
		end

		-- get coords from pad/portal
		local meta = minetest.get_meta(pos)

		if not meta then return end -- errorcheck

		local target_coords = {
			x = meta:get_int("x"),
			y = meta:get_int("y"),
			z = meta:get_int("z")
		}

		for n = 1, #objs do

			if objs[n] then

				-- play sound on portal end
				minetest.sound_play("portal_close", {
					pos = pos,
					gain = 1.0,
					max_hear_distance = 5
				})

				-- move player/object
				objs[n]:setpos(target_coords)

				-- paricle effects on arrival
				tp_effect(target_coords)

				-- play sound on destination end
				minetest.sound_play("portal_close", {
					pos = target_coords,
					gain = 1.0,
					max_hear_distance = 5
				})

				-- rotate player to look in pad placement direction
				if objs[n]:is_player() then

					local rot = node.param2
					local yaw = 0

					if rot == 0 or rot == 20 then
						yaw = 0 -- north
					elseif rot == 2 or rot == 22 then
						yaw = 3.14 -- south
					elseif rot == 1 or rot == 23 then
						yaw = 4.71 -- west
					elseif rot == 3 or rot == 21 then
						yaw = 1.57 -- east
					end

					objs[n]:set_look_yaw(yaw)
				end
			end
		end
	end
})


-- Throwable potion

local potion_entity = {
	physical = true,
	visual = "sprite",
	visual_size = {x = 1.0, y = 1.0},
	textures = {"potion.png"},
	collisionbox = {0,0,0,0,0,0},
	lastpos = {},
	player = "",
}

potion_entity.on_step = function(self, dtime)

	if not self.player then
		self.object:remove()
		return
	end

	local pos = self.object:get_pos()

	if self.lastpos.x ~= nil then

		local vel = self.object:getvelocity()

		-- only when potion hits something physical
		if vel.x == 0
		or vel.y == 0
		or vel.z == 0 then

			if self.player ~= "" then

				-- round up coords to fix glitching through doors
				self.lastpos = vector.round(self.lastpos)

				self.player:setpos(self.lastpos)

				minetest.sound_play("portal_close", {
					pos = self.lastpos,
					gain = 1.0,
					max_hear_distance = 5
				})

				tp_effect(self.lastpos)
			end

			self.object:remove()

			return

		end
	end

	self.lastpos = pos
end

minetest.register_entity("teleport_potion:potion_entity", potion_entity)


function throw_potion(itemstack, player)

	local playerpos = player:get_pos()

	local obj = minetest.add_entity({
		x = playerpos.x,
		y = playerpos.y + 1.5,
		z = playerpos.z
	}, "teleport_potion:potion_entity")

	local dir = player:get_look_dir()
	local velocity = 20

	obj:setvelocity({
		x = dir.x * velocity,
		y = dir.y * velocity,
		z = dir.z * velocity
	})

	obj:setacceleration({
		x = dir.x * -3,
		y = -9.5,
		z = dir.z * -3
	})

	obj:setyaw(player:get_look_yaw() + math.pi)
	obj:get_luaentity().player = player

end


-- add lucky blocks

-- Teleport Potion mod
if minetest.get_modpath("lucky_block") then
	lucky_block:add_blocks({
		{"dro", {"teleport_potion:potion"}, 2},
		{"tel"},
		{"dro", {"teleport_potion:pad"}, 1},
		{"lig"},
	})
end

print ("[MOD] Teleport Potion loaded")
