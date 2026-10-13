-- Compatibility shim for awful.util, which was removed in somewm 2.0.
-- lain and vicious (and older parts of rc.lua) still depend on it, so it is
-- rebuilt here on top of the gears.* equivalents and preloaded from rc.lua.
local gtable = require("gears.table")
local gstring = require("gears.string")
local gfs = require("gears.filesystem")

local util = {}

util.shell = os.getenv("SHELL") or "/bin/sh"
util.table = gtable
util.escape = gstring.xml_escape
util.unescape = gstring.xml_unescape
util.get_cache_dir = gfs.get_cache_dir
util.get_configuration_dir = gfs.get_configuration_dir
util.file_readable = gfs.file_readable
util.dir_readable = gfs.dir_readable

function util.getdir(d)
    if d == "config" then
        return gfs.get_configuration_dir()
    elseif d == "cache" then
        return gfs.get_cache_dir()
    end
end

function util.spawn(...)
    return require("awful.spawn")(...)
end

function util.eval(s)
    local f, err = load(s)
    if not f then return err end
    return f()
end

return util
