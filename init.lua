-- Farebox mod

-- adds a box that emmits a mesecons signal when the requested
-- quantity is paid. Ideal to charge admission from visitors to your
-- buildings
farebox = {}
-- Is used to keep the formspec information server-side
farebox.players = {}

function farebox.show_formspec(pos, player)
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local owner = meta:get_string("owner")
	local player_name = player:get_player_name()

	farebox.players[player_name] = vector.new(pos)
	if player_name == owner then
		local loc = "nodemeta:" .. pos.x .. "," .. pos.y .. "," .. pos.z
		minetest.show_formspec(player_name, "farebox:farebox",
			"size[8,10]"..
			"label[0.5,0.5; Entrance fee:]" ..
			"list[" .. loc .. ";request;2.5,0.25;1,1;]" ..
			"button_exit[6,0.25;2,1;open;Open]" ..
			"list[" .. loc .. ";main;0,1.5;8,4]" ..
			"list[current_player;main;0,5.75;8,1;]" ..
			"list[current_player;main;0,7;8,3;8]" ..
			"listring[]" .. default.get_hotbar_bg(0, 4.25)
		)
	else
		minetest.show_formspec(player_name, "farebox:farebox",
			"size[8,4]" ..
			"label[0.5,1.5; Owner Wants:]" ..
			"item_image_button[2.5,1.25;1,1;" ..
				inv:get_stack("request", 1):get_name() .. ";buy;\n\n\b\b\b\b\b" ..
				inv:get_stack("request", 1):get_count() .. "]" ..
			"label[3.5,1.5; (Click on the item to pay)]"
		)
	end
end


farebox.rules = {
	{x=0, y=-2, z=0},
	{x=0, y=2, z=0},
}

function farebox.open_faregate(pos)
	node = minetest.get_node(pos)
	node.name = "farebox:faregate_open"
	minetest.swap_node(pos, node)
	minetest.sound_play("doors_steel_door_open", {
		pos = pos,
		gain = 0.3,
		max_hear_distance = 10
	})
end
function farebox.close_faregate(pos)
	node = minetest.get_node(pos)
	node.name = "farebox:faregate"
	minetest.swap_node(pos, node)
	minetest.sound_play("doors_steel_door_close", {
		pos = pos,
		gain = 0.3,
		max_hear_distance = 10
	})
end

minetest.register_on_player_receive_fields(function(player, formname, pressed)
	if formname ~= "farebox:farebox" then
		return -- Not My Job
	end
	local pname = player:get_player_name()
	local pos = farebox.players[pname]
	if not pos then
		return
	end

	local nodename = minetest.get_node(pos).name
	if nodename ~= "farebox:farebox" and nodename ~= "farebox:faregate" then
		-- Node was removed. Make reference invalid.
		farebox.players[pname] = nil
		return
	end

	local pinv = player:get_inventory()
	local meta = minetest.get_meta(pos)
	local inv = meta:get_inventory()
	local owner = meta:get_string("owner")
	local open = false
	if pressed.buy then
		local request = inv:get_stack("request", 1)
		if pinv:contains_item("main", request)
				and inv:room_for_item("main", request) then
			if not (creative and creative.is_enabled_for
					and creative.is_enabled_for(pname)) then
				pinv:remove_item("main", request)
			end
			inv:add_item("main", request)
			open = true
		elseif not pinv:contains_item("main", request) then
			minetest.chat_send_player(pname, "You don't have enough items to enter")
		elseif not inv:room_for_item("main", request) then
			minetest.chat_send_player(pname, "Owner's inventory is full")
		end
	end
	if (pressed.open and pname == owner) or open then
		minetest.chat_send_player(pname, "Payment accepted.")
		if nodename == "farebox:farebox" then
			mesecon.receptor_on(pos, farebox.rules)
			minetest.after(1, mesecon.receptor_off, pos, farebox.rules)
		elseif nodename == "farebox:faregate" then
			farebox.open_faregate(pos)
		end
		minetest.close_formspec(pname, formname)
	end
end)

minetest.register_on_leaveplayer(function(player)
	farebox.players[player:get_player_name()] = nil
end)

minetest.register_node("farebox:farebox", {
	description = "Farebox",
	tiles = {
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png", "default_steel_block.png",
		"default_steel_block.png", "farebox_front.png"
	},
	paramtype2 = "facedir",
	groups = {cracky=2},
	legacy_facedir_simple = true,
	is_ground_content = false,
	sounds = default.node_sound_stone_defaults(),
	mesecons = {
		receptor = {
			state = mesecon.state.off,
			rules = farebox.rules
		}
	},
	can_dig = can_dig,
	after_place_node = function(pos, player, _)
		local meta = minetest.get_meta(pos)
		local player_name = player:get_player_name()

		meta:set_string("owner", player_name)
		meta:set_string("infotext", "Owned by "..player_name)

		local inv = meta:get_inventory()
		inv:set_size("request", 1)
		inv:set_size("main", 32)
	end,
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
		farebox.show_formspec(pos, player)
	end,
})

minetest.register_craft({
	output = "farebox:farebox",
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"default:steel_ingot", "mesecons:mesecon", "default:steel_ingot"},
	}
})

local modpath = minetest.get_modpath("farebox")
dofile(modpath .. "/faregate.lua")
