-- Lexical Domain: Menu. Encapsulates the UI prompt.
local Menu = {}

function Menu.choose(cache)
    local input = cache .. "/input"
    local output = cache .. "/output"
    local status = cache .. "/status"

    os.execute(string.format("rofi -dmenu -p Clipboard -show-icons -kb-custom-1 'Alt+p' < %s > %s; echo $? > %s", input, output, status))

    local intent = 0
    local condition = io.open(status, "r")
    if condition then
        intent = tonumber(condition:read("*a"):match("%d+") or "0")
        condition:close()
    end

    local selection = ""
    local result = io.open(output, "r")
    if result then
        selection = result:read("*a"):gsub("%s+$", "")
        result:close()
    end

    return intent, selection
end

function Menu.preview(cache)
    local target = cache .. "/preview"
    os.execute(string.format("rofi -dmenu -p 'Preview (Esc to exit)' < %s >/dev/null 2>&1", target))
end

return Menu
