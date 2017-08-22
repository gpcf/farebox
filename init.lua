-- Farebox mod

-- adds a box that emmits a mesecons signal when the requested
-- quantity is paid. Ideal to charge admission from visitors to your
-- buildings
farebox = {}
function farebox.show_formspec(pos, player)
   local spos = pos.x .. "," ..pos.y .. "," .. pos.z
   local meta = minetest.get_meta(pos)
   local inv = meta:get_inventory()
   local owner = meta:get_string("owner")
   local formspec = ""
   if owner and player:get_player_name()==owner then
      formspec = "size[8,10]"..
	 "label[0.5,0.5; Entrance fee:]"..
	 "list[nodemeta:" .. spos .. ";request;2.5,0.25;1,1;]" ..
	 "button[6,0.25;2,1;open;Open]"..
	 "list[nodemeta:" .. spos .. ";main;0,1.5;8,4]"..
	 "list[current_player;main;0,5.75;8,1;]"..
	 "list[current_player;main;0,7;8,3;8]"..
	 "listring[]"..      default.get_hotbar_bg(0, 4.25)      
   else
      formspec = "size[8,4]"..
	 "label[0.5,1.5; Owner Wants:]"..
	 "item_image_button[2.5,1.25;1,1;"..inv:get_stack("request",1):get_name()..";buy;\n\n\b\b\b\b\b"..inv:get_stack("request",1):get_count() .."]"..
	 "label[3.5,1.5; (Click on the item to pay)]"..
	 "listring[]"..      default.get_hotbar_bg(0, 4.25)
   end
   minetest.after((0.1), function(gui)
	 return minetest.show_formspec(player:get_player_name(), "farebox:"..spos,gui)
			 end, formspec)
end


farebox.rules =
{{x=0,  y=-2,  z=0},
      {x=0,  y=2,  z=0}}

minetest.register_on_player_receive_fields(function(player, form, pressed)

      if string.sub(form,1,string.len("farebox:")) == "farebox:" then
	 local spos = string.sub(form,string.len("farebox:")+1,-1)
	 local pos = minetest.string_to_pos(spos)
	 local pinv=player:get_inventory()
	 local meta = minetest.get_meta(pos)
	 local inv = meta:get_inventory()
	 local open = false
	 if pressed.buy then
	    if pinv:contains_item("main", inv:get_stack("request",1)) and inv:room_for_item("main", inv:get_stack("request",1)) then
	       if not (creative and creative.is_enabled_for
		       and creative.is_enabled_for(player:get_player_name())) then
		  pinv:remove_item("main", inv:get_stack("request",1))
	       end
	       inv:add_item("main", inv:get_stack("request",1))
	       open = true
	    elseif not pinv:contains_item("main", inv:get_stack("request",1)) then
	       minetest.chat_send_player(player:get_player_name(), "You don't have enough items to enter")
	    elseif not inv:room_for_item("main", inv:get_stack("request",1)) then
	       minetest.chat_send_player(player:get_player_name(), "Owner's inventory is full")
	    end
	 end
	 if pressed.open or open then
	    minetest.chat_send_player(player:get_player_name(), "Payment accepted.")
	    mesecon.receptor_on(pos,farebox.rules)
	    minetest.after(3, function (_)
			      mesecon.receptor_off(pos,farebox.rules)

	    end)
	 end
      end
	 
end)



minetest.register_node("farebox:farebox", {
			  description = "Farebox",
			  tiles = {
			     "farebox_side.png", "farebox_side.png",
			     "farebox_side.png", "farebox_side.png",
			     "farebox_side.png", "farebox_front.png"
			  },
			  paramtype2 = "facedir",
			  groups = {cracky=2},
			  legacy_facedir_simple = true,
			  is_ground_content = false,
			  sounds = default.node_sound_stone_defaults(),
			  mesecons = {receptor = {
					 state = mesecon.state.off,
					 rules = farebox.rules
				     }},
			  can_dig = can_dig,
			  after_place_node = function(pos, player, _)
			     local meta = minetest.get_meta(pos)
			     local player_name = player:get_player_name()

			     meta:set_string("owner", player_name)
			     meta:set_string("infotext", "Owned by "..player_name)
			     
			     local inv = meta:get_inventory()
			     inv:set_size("request", 1)
			     inv:set_size("drop", 1)
			     inv:set_size("main", 32)
			  end,

			  on_rightclick = function(pos, node, player, itemstack, pointed_thing)
			     farebox.show_formspec(pos, player)
			  end,
			  
})

minetest.register_craft({output = "farebox:farebox",
			 recipe = {
			    {"group:wood", "group:wood", "group:wood"},
			    {"group:wood", "", "group:wood"},
			    {"group:wood", "mesecons:mesecon", "group:wood"},
			 }
})
