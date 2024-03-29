-- Overrides the Skeleton_key with a Advanced one.

local function make_key_form(meta)
	local ctable = {}
	for pstring, chest in pairs(meta:to_table().fields) do
		if pstring ~= "owner" and pstring ~= "user" and pstring ~= "secret" and pstring ~= "description" then
			local chesttable = string.split(chest, " ")
			table.remove(chesttable, 1)
			local cheststring = table.concat(chesttable, " ")
			table.insert(ctable, cheststring.." at "..minetest.formspec_escape(pstring))
		end
	end
	local form = "size[5,4]" ..
		"field[0.6,1;2,0.7;user;User of the Key;"..meta:get_string("user").."]" ..
		"button[3,0.5;1.5,1;save;Save]" ..
		"dropdown[0.3,1.5;4;chestlist;"..table.concat(ctable, ",")..";1]" ..
		"button[0.3,3;2,1;delete;Delete Entry]"
	return form
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "adv_keys:key_form" then
		local itemstack = player:get_wielded_item()
		local name = player:get_player_name()
		local meta = itemstack:get_meta()
		if meta:get_string("description") ~= "Key by "..name then
			return
		end
		if fields.save then
			meta:set_string("user", fields.user)
		elseif fields.delete and type(fields.chestlist) == "string" then
			local chesttable = string.split(fields.chestlist, " ")
			if type(chesttable) == "table" and type(chesttable[#chesttable]) == "string" then
				meta:set_string(chesttable[#chesttable], "")
				minetest.show_formspec(name, "adv_keys:key_form", make_key_form(meta))
			end
		end
		player:set_wielded_item(itemstack)
	end
end)

-- Clear old key crafts (would otherwise be pointless gold to gold crafts)
minetest.clear_craft({
	output = "keys:skeleton_key",
})
minetest.clear_craft({
	type = "cooking",
	recipe = "keys:skeleton_key",
})

-- Register alias for existing keys (in this case a replacement ingot)
minetest.register_alias_force("keys:skeleton_key", "default:gold_ingot")

minetest.override_item("keys:key", {
	description = "Advanced Key",
	inventory_image = "keys_key.png",
	groups = {key = 1},
	stack_max = 1,
	on_use = function(itemstack, user, pointed_thing)
	local meta = itemstack:get_meta()
	local name = user:get_player_name()
	if not meta:get_string("owner") or meta:get_string("owner") == "" then
		meta:set_string("owner", name)
		meta:set_string("description", "Key by "..name)
	end
	if meta:get_string("owner") ~= name then
		minetest.chat_send_player(name, "You are not the owner of the key!")
		return itemstack
	end
		if pointed_thing.type ~= "node" then
			minetest.show_formspec(name, "adv_keys:key_form", make_key_form(meta))
			return itemstack
		end

		local pos = pointed_thing.under
		local node = minetest.get_node(pos)

		if not node then
			return itemstack
		end

		local on_skeleton_key_use = minetest.registered_nodes[node.name].on_skeleton_key_use
		if not on_skeleton_key_use then
			return itemstack
		end

		-- Make a new key secret in case the node callback needs it
		local random = math.random
		local newsecret = string.format(
			"%04x%04x%04x%04x",
			random(2^16) - 1, random(2^16) - 1,
			random(2^16) - 1, random(2^16) - 1)

		local secret, _, _ = on_skeleton_key_use(pos, user, newsecret)

		if secret then
			meta:set_string(minetest.pos_to_string(pos), secret.." "..minetest.registered_nodes[node.name].description)
		end
	return itemstack
	end,
	on_place = function(itemstack, placer, pointed_thing)
	local meta = itemstack:get_meta()
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		local def = minetest.registered_nodes[node.name]
		if pointed_thing.type ~= "node" then
			return itemstack
		end

		if not node or node.name == "ignore" then
			return itemstack
		end

		if not def then
			return itemstack
		end

		local on_key_use = def.on_key_use
		if meta:get_string("user") == placer:get_player_name() and meta:get_string(minetest.pos_to_string(pos)) ~= "" then
			meta:set_string("secret", string.split(meta:get_string(minetest.pos_to_string(pos)), " ")[1])
			if on_key_use then
				minetest.after(0.1, function()
					on_key_use(pos, placer)
				end)
			end
		else
			meta:set_string("secret", "no")
		end
		return itemstack
	end
})

minetest.register_craft({
	output = "keys:key",
	recipe = {
		{"default:gold_ingot", "", "default:gold_ingot"},
		{"", "default:diamondblock", ""},
		{"", "", ""}
	}
})
