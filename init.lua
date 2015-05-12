
--= Teleport Potion mod 0.3 by TenPlus1

--= Create potion/pad, right-click to enter coords and walk into the blue light,
--= Portal closes after 10 seconds, pad remains...  SFX are license Free...

teleport = {}

-- Teleport Portal recipe
minetest.register_craft({
 	output = 'teleport_potion:potion',
	type = "shapeless",
 	recipe = {'vessels:glass_bottle', 'default:diamondblock'}
})

-- Teleport Pad recipe
minetest.register_craft({
	output = 'teleport_potion:pad',
	recipe = {
		{"teleport_potion:potion", 'default:glass', "teleport_potion:potion"},
		{"default:glass", "default:mese", "default:glass"},
		{"teleport_potion:potion", "default:glass", "teleport_potion:potion"}
	}
})

-- Default coords
teleport.default = {x=0, y=0, z=0}

-- Portal
minetest.register_node("teleport_potion:portal", {
	drawtype = "plantlike",
	tiles = {{name="portal.png", animation={type="vertical_frames", aspect_w=16, aspect_h=16, length=1.0}},},	
	light_source = 12,
	walkable = false,
	paramtype = "light",
	pointable = false,
	buildable_to = true,
	waving = 1,
	sunlight_propagates = true,
	damage_per_second = 1, -- Walking into portal also hurts player

	-- Start timer when portal appears
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(10)
	end,

	-- Remove portal after 10 seconds
	on_timer = function(pos)
		minetest.sound_play("portal_close", {pos = pos, gain = 1.0, max_hear_distance = 10,})
		minetest.set_node(pos, {name="air"})
	end,
})

-- Potion
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
	metadata_name = "sign",
	groups = {snappy=3, dig_immediate=3},
	selection_box = {type = "wallmounted",},

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		-- Text entry formspec
		meta:set_string("formspec", "field[text;;${text}]")
		meta:set_string("infotext", "Enter teleport coords (e.g 200,20,-200)")
		meta:set_string("text", teleport.default.x..","..teleport.default.y..","..teleport.default.z)

		-- Load with default coords
		meta:set_float("enabled", -1)
		meta:set_float("x", teleport.default.x)
		meta:set_float("y", teleport.default.y)
		meta:set_float("z", teleport.default.z)
	end,

	-- Right-click to enter new coords
	on_right_click = function(pos, placer)
		local meta = minetest.get_meta(pos)
	end,

	-- Once entered, check coords and teleport, otherwise return potion
	on_receive_fields = function(pos, formname, fields, sender)

		local coords = teleport.coordinates(fields.text)
		local meta = minetest.get_meta(pos)
		local name = sender:get_player_name()

		if coords then	

			minetest.add_node(pos, {name="teleport_potion:portal"})

			local newmeta = minetest.get_meta(pos)

			newmeta:set_float("x", coords.x)
			newmeta:set_float("y", coords.y)
			newmeta:set_float("z", coords.z)
			newmeta:set_string("text", fields.text)

			minetest.sound_play("portal_open", {pos = pos, gain = 1.0, max_hear_distance = 10,})

		else
			minetest.chat_send_player(name, 'Potion failed!')
			minetest.set_node(pos, {name="air"})
			minetest.add_item(pos, 'teleport_potion:potion')
		end
	end,
})

-- Pad
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
	metadata_name = "sign",
	light_source = 5,
	groups = {snappy=3, dig_immediate=3},
	node_box = {
		type = "wallmounted",
		wall_top    = {-0.5, 0.4375, -0.5, 0.5, 0.5, 0.5},
		wall_bottom = {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5},
		wall_side   = {-0.5, -0.5, -0.5, -0.4375, 0.5, 0.5},
	},
	selection_box = {type = "wallmounted"},

	on_construct = function(pos)

		local meta = minetest.get_meta(pos)

		-- Text entry formspec
		meta:set_string("formspec", "field[text;;${text}]")
		meta:set_string("infotext", "Enter teleport coords (e.g 200,20,-200)")
		meta:set_string("text", teleport.default.x..","..teleport.default.y..","..teleport.default.z)

		-- Load with default coords
		meta:set_float("enabled", -1)
		meta:set_float("x", teleport.default.x)
		meta:set_float("y", teleport.default.y)
		meta:set_float("z", teleport.default.z)
	end,

	-- Right-click to enter new coords
	on_right_click = function(pos, placer)
		local meta = minetest.get_meta(pos)
	end,

	-- Once entered, check coords and teleport, otherwise return potion
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
			minetest.sound_play("portal_open", {pos = pos, gain = 1.0, max_hear_distance = 10,})

		else
			minetest.chat_send_player(name, 'Teleport Pad Coordinates failed!')

		end
	end,
})

-- Check coords
teleport.coordinates = function(str)

	if not str or str == "" then return nil end

	-- Get coords from string
	local x,y,z = string.match(str, "^(-?%d+),(-?%d+),(-?%d+)")

	-- Check coords
	if x==nil or string.len(x) > 6
	or y==nil or string.len(y) > 6
	or z==nil or string.len(z) > 6 then
		return nil
	end

	-- Convert string coords to numbers
	x = x + 0.0; y = y + 0.0; z = z + 0.0

	-- Are coords in map range ?
	if x > 30900 or x < -30900
	or y > 30900 or y < -30900
	or z > 30900 or z < -30900 then
		return nil
	end

	-- Return ok coords
	return {x=x, y=y, z=z}
end

-- Has player walked inside portal
minetest.register_abm({
	nodenames = {"teleport_potion:portal", "teleport_potion:pad"},
	interval = 1.0,
	chance = 1,

	action = function(pos, node, active_object_count, active_object_count_wider)
		local objs = minetest.get_objects_inside_radius(pos, 1)
		local meta, target_coords
		for k, player in pairs(objs) do
			if player:get_player_name() then 
				meta = minetest.get_meta(pos)
				target_coords={x=meta:get_float("x"), y=meta:get_float("y"), z=meta:get_float("z")}
				minetest.sound_play("portal_close", {pos = pos, gain = 1.0, max_hear_distance = 5,})
				player:moveto(target_coords, false)
			end
		end
	end	
})
