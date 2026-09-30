-- pack-test.lua: drive the pack like a user would, logging the console to console.txt
dofile(os.getenv("PACK") .. "\\autoboot.lua")
local space = manager.machine.devices[":vme:slot1:mvme147:maincpu"].spaces["program"]
local log = io.open(os.getenv("TESTDIR") .. "\\console.txt", "wb")
local out = ""
local P = "\n# "
local steps = {
	{ "Login:", "root\r" },
	{ "Password:", "sysv68\r" },
	{ P, "uname -a\r" },
	{ P, "echo a/b-c | tr a-z A-Z\r" },
	{ P, "stty erase '^H'\r" },
	{ P, "echo ZZ\b\bERASE-OK\r" },
	{ P, "cd /\r" },
	{ P, "/etc/shutdown -y -g0 -i0\r" },
	{ "secured for powering down", nil },
}
local step, from, due = 1, 1, nil
test_tap = space:install_write_tap(0xfffe3000, 0xfffe3003, "pack-test", function(offset, data, mask)
	if (mask & 0xff) == 0 then return end
	local c = string.char(data & 0xff)
	log:write(c) log:flush()
	out = out .. c
end)
local date_from = 1
emu.register_periodic(function()
	local now = manager.machine.time.seconds
	-- the date question only comes up when the board clock looks wrong
	local d = out:find("(y or n)", date_from, true)
	if d then
		date_from = d + 8
		log:write("\n[pack-test] date question\n")
		manager.machine.natkeyboard:post("y\r")
	end
	if due then
		if now >= due then
			manager.machine.natkeyboard:post(steps[step][2])
			step, due = step + 1, nil
		end
		return
	end
	local s = steps[step]
	if not s then return end
	local i = out:find(s[1], from, true)
	if not i then return end
	from = i + #s[1]
	if s[2] then
		due = now + 2
	else
		log:write("\n[pack-test] OK t=" .. now .. "\n") log:close()
		manager.machine:exit()
	end
end)
