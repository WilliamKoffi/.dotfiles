#!/usr/bin/env lua

-- The Composer: Coordinates the domains without knowing how they work internally.

-- Add this script's directory to the package search path for modular imports
local script_path = debug.getinfo(1).source:match("@?(.*)/")
if script_path then
    package.path = package.path .. ";" .. script_path .. "/?.lua"
end

local cache = "/tmp/clipboard"
os.execute("rm -rf " .. cache)
os.execute("mkdir -p " .. cache)

local History = require("clipboard.history")
local Menu = require("clipboard.menu")
local Window = require("clipboard.window")

if not History.populate(cache) then
    os.exit(0)
end

local active = true
while active do
    local intent, selection = Menu.choose(cache)

    if intent == 0 then
        if selection ~= "" then
            History.extract(selection, cache)
            Window.paste()
        end
        active = false
    elseif intent == 10 then
        if selection ~= "" then
            History.read(selection, cache)
            Menu.preview(cache)
        end
    else
        active = false
    end
end
