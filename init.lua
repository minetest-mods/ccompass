-- default to static_spawnpoint or 0/0/0
local default_spawn = minetest.setting_get_pos("static_spawnpoint") or {x=0, y=0, z=0}

-- Get players spawn point (compass target) in order sethome, beds-spawn and static_spawnpoint
local function get_spawn(player)
	local playername = player:get_player_name()
	local spawn
	if minetest.global_exists("sethome") then
		spawn = sethome.get(playername)
	end
	if not spawn and minetest.global_exists("beds") and beds.spawn then
		spawn = beds.spawn[playername]
	end
	if not spawn then
		spawn = default_spawn
	end
	return spawn
end

-- get right image number for players compas
local function get_compass_image(player)
	local spawn = get_spawn(player)
	local pos = player:getpos()
	local dir = player:get_look_yaw()
	local angle_north = math.deg(math.atan2(spawn.x - pos.x, spawn.z - pos.z))
	if angle_north < 0 then
		angle_north = angle_north + 360
	end
	local angle_dir = 90 - math.deg(dir)
	local angle_relative = (angle_north - angle_dir) % 360
	local compass_image = math.floor((angle_relative/30) + 0.5)%12
	return compass_image
end

-- update inventory
minetest.register_globalstep(function(dtime)
	for i,player in ipairs(minetest.get_connected_players()) do
		if player:get_inventory() then
			for i,stack in ipairs(player:get_inventory():get_list("main")) do
				if i > 8 then
					break
				end
				if string.sub(stack:get_name(), 0, 8) == "compass:" then
					player:get_inventory():set_stack("main", i, "compass:"..get_compass_image(player))
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
