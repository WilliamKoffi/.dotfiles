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
    local stream = io.popen("hyprctl activewindow -j 2>/dev/null")
    local class = ""
    
    if stream then
        local payload = stream:read("*a")
        stream:close()
        class = payload:match('"class":%s*"([^"]+)"') or ""
    end

    local keystroke = "wtype -M ctrl -k v -m ctrl"
    if Window.terminals[class] then
        keystroke = "wtype -M shift -M ctrl -k v -m ctrl -m shift"
    end

    os.execute(keystroke)
end

return Window
