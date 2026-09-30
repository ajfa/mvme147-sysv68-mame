-- autoboot.lua: when 147Bug prints its prompt for the first time, type the disk boot command
local space = manager.machine.devices[":vme:slot1:mvme147:maincpu"].spaces["program"]
local seen = ""
local done = false
-- 0xfffe3003 is the console SCC channel A data register (lowest byte lane of the word)
console_tap = space:install_write_tap(0xfffe3000, 0xfffe3003, "console", function(offset, data, mask)
	if done or (mask & 0xff) == 0 then return end
	seen = (seen .. string.char(data & 0xff)):sub(-16)
	if seen:find("Bug>", 1, true) then
		done = true
		manager.machine.natkeyboard:post("bo 0,0\r")
	end
end)
