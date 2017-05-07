-- default to static_spawnpoint or 0/0/0
local default_spawn = minetest.setting_get_pos("static_spawnpoint") or {x=0, y=0, z=0}

-- supported modes: default, sethome, beds, origin
local compass_mode = minetest.setting_get("compass_mode") or "default"

-- Get players spawn point (compass target) in order sethome, beds-spawn and static_spawnpoint
local function get_destination(player, stack)
	if compass_mode == "default" then
		return minetest.setting_get_pos("static_spawnpoint") or default_spawn
	elseif compass_mode == "sethome" then
		return sethome.get(player:get_player_name()) or default_spawn
	elseif compass_mode == "beds" then
		return beds.spawn[player:get_player_name()] or default_spawn
	elseif compass_mode == "origin" then
		return minetest.string_to_pos(stack:get_metadata())
	end
end

-- get right image number for players compas
local function get_compass_stack(player, stack)
	local spawn = get_destination(player, stack)
	local pos = player:getpos()
	local dir = player:get_look_yaw()
	local angle_north = math.deg(math.atan2(spawn.x - pos.x, spawn.z - pos.z))
	if angle_north < 0 then
		angle_north = angle_north + 360
	end
	local angle_dir = 90 - math.deg(dir)
	local angle_relative = (angle_north - angle_dir) % 360
	local compass_image = math.floor((angle_relative/30) + 0.5)%12
	local meta = stack:get_metadata()

	local newstack = ItemStack("compass:"..compass_image)
	--meta:set_string("description", "Compass to "..minetest.pos_to_string(spawn)) -- does not work on stable 0.4.15
	newstack:set_metadata(meta)
	return newstack
end

-- update inventory
minetest.register_globalstep(function(dtime)
	for i,player in ipairs(minetest.get_connected_players()) do
		if player:get_inventory() then
			for i,stack in ipairs(player:get_inventory():get_list("main")) do
				if string.sub(stack:get_name(), 0, 8) == "compass:" then
					if compass_mode == "origin" then
						local meta = stack:get_metadata()
						if not meta or meta == "" then
							meta = minetest.pos_to_string(player:getpos())
							stack:set_metadata(meta)
							player:get_inventory():set_stack("main", i, stack)
						end
					elseif i > 8 then
						break
					end
					if i <= 8 then
						player:get_inventory():set_stack("main", i, get_compass_stack(player, stack))
					end
				end
			end
		end
	end
end)

-- register items
for i = 0, 11 do
	local image = "compass_"..i..".png"
	local groups = {}
	if i > 0 then
		groups.not_in_creative_inventory = 1
	end
	minetest.register_tool("compass:"..i, {
		description = "Compass",
		inventory_image = image,
		wield_image = image,
		groups = groups
	})
end

minetest.register_craft({
	output = 'compass:0',
	recipe = {
		{'', 'default:steel_ingot', ''},
		{'default:steel_ingot', 'default:mese_crystal_fragment', 'default:steel_ingot'},
		{'', 'default:steel_ingot', ''}
	}
})
