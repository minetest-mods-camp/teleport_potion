
--= Teleport Potion mod 0.4 by TenPlus1

-- Create teleport potion or pad, place then right-click to enter coords
-- and step onto pad or walk into the blue portal light, portal closes after
-- 10 seconds, pad remains...  SFX are license Free...

teleport = {}

-- teleport portal recipe
minetest.register_craft({
 	output = 'teleport_potion:potion',
	type = "shapeless",
 	recipe = {'vessels:glass_bottle', 'default:diamondblock'}
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

-- default coords (from static spawnpoint or default values at end)
teleport.default = (minetest.setting_get_pos("static_spawnpoint") or {x = 0, y = 2, z = 0})

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
	light_source = default.LIGHT_MAX - 2,
	walkable = false,
	paramtype = "light",
	pointable = false,
	buildable_to = true,
	waving = 1,
	sunlight_propagates = true,
	damage_per_second = 1, -- walking into portal also hurts player

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
	tile_images = {"pad.png"},
	drawtype = "signlike",
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = false,
	sunlight_propagates = true,
	description="Teleport Potion (place and right-click to enchant location)",
	inventory_image = "potion.png",
	wield_image = "potion.png",
	groups = {snappy = 3, dig_immediate = 3},
	selection_box = {type = "wallmounted"},

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		-- text entry formspec
		meta:set_string("formspec", "field[text;;${text}]")
		meta:set_string("infotext", "Enter teleport coords (e.g 200,20,-200)")
		meta:set_string("text", teleport.default.x..","..teleport.default.y..","..teleport.default.z)

		-- set default coords
		meta:set_float("x", teleport.default.x)
		meta:set_float("y", teleport.default.y)
		meta:set_float("z", teleport.default.z)
	end,

	-- right-click to enter new coords
	on_right_click = function(pos, placer)
		local meta = minetest.get_meta(pos)
	end,

	-- check if coords ok then open portal, otherwise return potion
	on_receive_fields = function(pos, formname, fields, sender)

		local coords = teleport.coordinates(fields.text)
		local meta = minetest.get_meta(pos)
		local name = sender:get_player_name()

		if coords then

			minetest.add_node(pos, {name = "teleport_potion:portal"})

			local newmeta = minetest.get_meta(pos)

			-- set portal destination
			newmeta:set_float("x", coords.x)
			newmeta:set_float("y", coords.y)
			newmeta:set_float("z", coords.z)
			newmeta:set_string("text", fields.text)

			-- portal open effect and sound
			effect(pos)

			minetest.sound_play("portal_open", {
				pos = pos,
				gain = 1.0,
				max_hear_distance = 10
			})

		else
			minetest.chat_send_player(name, 'Potion failed!')
			minetest.set_node(pos, {name = "air"})
			minetest.add_item(pos, 'teleport_potion:potion')
		end
	end,
})

-- teleport pad
minetest.register_node("teleport_potion:pad", {
	tile_images = {"padd.png"},
	drawtype = 'nodebox',
	paramtype = "light",
	paramtype2 = "wallmounted",
	walkable = true,
	sunlight_propagates = true,
	description="Teleport Pad (place and right-click to enchant location)",
	inventory_image = "padd.png",
	wield_image = "padd.png",
	light_source = 5,
	groups = {snappy = 3},
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.4375, -0.5, 0.5, 0.5, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.4375, 0.5, 0.5},
	},
	selection_box = {type = "wallmounted"},

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		-- text entry formspec
		meta:set_string("formspec", "field[text;;${text}]")
		meta:set_string("infotext", "Enter teleport coords (e.g 200,20,-200)")
		meta:set_string("text", teleport.default.x..","..teleport.default.y..","..teleport.default.z)

		-- set default coords
		meta:set_float("x", teleport.default.x)
		meta:set_float("y", teleport.default.y)
		meta:set_float("z", teleport.default.z)
	end,

	-- right-click to enter new coords
	on_right_click = function(pos, placer)
		local meta = minetest.get_meta(pos)
	end,

	-- once entered, check coords, if ok then return potion
	on_receive_fields = function(pos, formname, fields, sender)

		local coords = teleport.coordinates(fields.text)
		local meta = minetest.get_meta(pos)
		local name = sender:get_player_name()

		if minetest.is_protected(pos, name) then
			minetest.record_protection_violation(pos, name)
			return
		end

		if coords then

			local newmeta = minetest.get_meta(pos)

			newmeta:set_float("x", coords.x)
			newmeta:set_float("y", coords.y)
			newmeta:set_float("z", coords.z)
			newmeta:set_string("text", fields.text)

			meta:set_string("infotext", "Pad Active ("..coords.x..","..coords.y..","..coords.z..")")
			minetest.sound_play("portal_open", {
				pos = pos,
				gain = 1.0,
				max_hear_distance = 10
			})

		else
			minetest.chat_send_player(name, 'Teleport Pad coordinates failed!')
		end
	end,
})

teleport.coordinates = function(str)

	if not str or str == "" then return nil end

	-- get coords from string
	local x, y, z = string.match(str, "^(-?%d+),(-?%d+),(-?%d+)")

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
	if x > 30900 or x < -30900
	or y > 30900 or y < -30900
	or z > 30900 or z < -30900 then
		return nil
	end

	-- return ok coords
	return {x = x, y = y, z = z}
end

-- particle effects
function effect(pos)
	minetest.add_particlespawner({
		amount = 20,
		time = 0.25,
		minpos = pos,
		maxpos = pos,
		minvel = {x = -2, y = -2, z = -2},
		maxvel = {x = 2,  y = 2,  z = 2},
		minacc = {x = -4, y = -4, z = -4},
		maxacc = {x = 4, y = 4, z = 4},
		minexptime = 0.1,
		maxexptime = 1,
		minsize = 0.5,
		maxsize = 1,
		texture = "particle.png",
	})
end

-- check pad and teleport objects on top
minetest.register_abm({
	nodenames = {"teleport_potion:portal", "teleport_potion:pad"},
	interval = 1,
	chance = 1,

	action = function(pos, node, active_object_count, active_object_count_wider)

		-- check objects inside pad/portal
		local objs = minetest.get_objects_inside_radius(pos, 1)
		if #objs == 0 then return end

		-- get coords from pad/portal
		local meta = minetest.get_meta(pos)
		local target_coords = {
			x = meta:get_float("x"),
			y = meta:get_float("y"),
			z = meta:get_float("z")
		}

		for k, player in pairs(objs) do
			if player:get_player_name() then

				-- play sound on portal end
				minetest.sound_play("portal_close", {
					pos = pos,
					gain = 1.0,
					max_hear_distance = 5
				})

				-- move player/object
				player:moveto(target_coords, false)

				-- paricle effects on arrival
				effect(target_coords)

				-- play sound on destination end
				minetest.sound_play("portal_close", {
					pos = target_coords,
					gain = 1.0,
					max_hear_distance = 5
				})
			end
		end
	end
})