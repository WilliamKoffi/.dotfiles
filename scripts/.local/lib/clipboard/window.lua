-- Lexical Domain: Window. Encapsulates active window interactions.
local Window = {}

Window.terminals = {
    rio = true,
    kitty = true,
    Alacritty = true,
    foot = true,
    wezterm = true,
    ["org.wezfurlong.wezterm"] = true,
    ["dev.warp.Warp"] = true,
    ["warp-terminal"] = true,
    ["com.mitchellh.ghostty"] = true
}

-- Affordance: The window affords having content pasted into it.
function Window.paste()
    local stream = io.popen("niri msg --json focused-window 2>/dev/null")
    local app_id = ""

    if stream then
        local payload = stream:read("*a")
        stream:close()
        app_id = payload:match('"app_id":%s*"([^"]+)"') or ""
    end

    local keystroke = "wtype -M ctrl -k v -m ctrl"
    if Window.terminals[app_id] then
        keystroke = "wtype -M shift -M ctrl -k v -m ctrl -m shift"
    end

    os.execute(keystroke)
end

return Window
