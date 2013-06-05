--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0
]]--

local require = require
local pairs = pairs
local table = table

local string = string
--local print, tostring, table, string
--    = print, tostring, table, string
local map

module "luci.model.cbi.wizard.portforwarding"

local uci   = require "luci.model.uci"
_uci_real  = cursor or _uci_real or uci.cursor()
local sys = require "luci.sys"
--local json  = require "luci.json"

local device_rules = {
	name,
	description,
	dest_ip,
	src  = 'wan',
	dest = 'lan',
	tcp  = {},
	udp  = {},
	both = {}
}

function set_ip(self, target)
	device_rules.dest_ip = target
	_uci_real:section("temp", "redirect", nil, { dest_ip = target })
	sys.exec("echo device_rules.dest_ip = %s > /dev/console" %device_rules.dest_ip)
	--_uci_real:save("firewall")
	return
end

function readconf(self)
	str = _uci_real:get("preset", "xbox", "description")
	return str
end

--[[ 
returns a list of device names from /etc/config/preset in the format of:
	["dev0", "dev1", "dev2", ... ]
]]--
function device_list_name(self)
	local str = "["
	_uci_real:foreach("preset", "device",
		function(s) str = str .. "\"" ..  s.name .. "\", " end)
	return str:sub(0, -3) .. "]"
end

--[[ 
returns a list of device descriptions from /etc/config/preset in the format of:
	["dev0", "dev1", "dev2", ... ]
]]--
function device_list_desc(self)
	local str = "["
	_uci_real:foreach("preset", "device",
		function(s) str = str .. "\"" ..  s.description .. "\", " end)
	return str:sub(0, -3) .. "]"
end

-- prints out the dictionary table containing protocol and ports
function get_presets(self, tab)
	local str = "["
	for name,proto in pairs(tab) do
		str = "\"" .. str .. name .. ": "
		for i,port in pairs(proto) do
			str = str .. port .. " "
		end
	end
	return str
end

function get_table(self)
	return device_rules
end

-- Build a Lua table of redirection rules
function construct_table(self, devname, target_ip)
	device_rules.name = devname
	device_rules.dest_ip = target_ip
	device_rules.description = _uci_real:get("preset", devname, "description")

	_uci_real:foreach("preset", "redirect",
		function(s)
			if s.device == devname then
				if s.proto == "tcp" then
					table.insert(device_rules.tcp, s.port)
				elseif s.proto == "udp" then
					table.insert(device_rules.udp, s.port)
				elseif s.proto == "tcp udp" then
					table.insert(device_rules.both, s.port)
				end
			end
		end)
end

-- Returns JSON of redirection rules
function export_rules(self, devname)
	local str = "{ \"name\": \"%s\", \"description\": \"%s\""
		    %{device_rules.name, device_rules.description}

	str = "%s, \"tcp\": [" %str
	for i=1,# device_rules.tcp do
		if i < #device_rules.tcp then
			str = "%s%s, " %{str, device_rules.tcp[i]}
		elseif i == #device_rules.tcp then
			str = "%s%s" %{str, device_rules.tcp[i]}
		end
	end
	str = "%s]" %str

	str = "%s, \"udp\": [" %str
	for i=1,# device_rules.udp do
		if i < #device_rules.udp then
			str = "%s%s, " %{str, device_rules.udp[i]}
		elseif i == #device_rules.udp then
			str = "%s%s" %{str, device_rules.udp[i]}
		end
	end
	str = "%s]" %str

	str = "%s, \"both\": [" %str
	for i=1,# device_rules.both do
		if i < #device_rules.both then
			str = "%s%s, " %{str, device_rules.both[i]}
		elseif i == #device_rules.both then
			str = "%s%s" %{str, device_rules.both[i]}
		end
	end
	str = "%s]" %str

	sys.exec("echo json: %s > /dev/console" %device_rules.description)

	return "%s }" %str
end

-- Applies forwarding rules in in etc/config/firewall from the table 'device_rules'
function apply_rules(self)
	for i=1,# device_rules.tcp do
		sys.exec("echo port %s > /dev/console" %device_rules.tcp[i])
		_uci_real:section("firewall", "redirect", nil, redir_rule("tcp", device_rules.tcp[i]))
	end
	for i=1,# device_rules.udp do
		sys.exec("echo port %s > /dev/console" %device_rules.udp[i])
		_uci_real:section("firewall", "redirect", nil, redir_rule("udp", device_rules.udp[i]))
	end
	for i=1,# device_rules.both do
		sys.exec("echo port %s > /dev/console" %device_rules.both[i])
		_uci_real:section("firewall", "redirect", nil, redir_rule("both", device_rules.both[i]))
	end

	_uci_real:save("firewall")
	_uci_real:commit("firewall")
end

function redir_rule(proto_name, port)
	local rules = { src_dport = port
	              , dest_port = port
	              , proto     = proto_name
	              , name      = device_rules.description
	              , src       = device_rules.src
	              , dest      = device_rules.dest
	              , dest_ip   = device_rules.dest_ip
	}
	return rules
end
