-- Lexical Domain over Agents. 
-- We do not create a 'WorkspaceManager'. We give the Browser an affordance.

local Browser = {}

Browser.identifiers = {
    ["brave-browser"] = true,
    ["google-chrome"] = true,
    ["google-chrome-stable"] = true,
    ["chromium"] = true,
    ["chromium-browser"] = true,
    ["firefox"] = true,
    ["firefoxdeveloperedition"] = true,
    ["org.mozilla.firefox"] = true,
    ["zen"] = true,
    ["zen-browser"] = true,
    ["vivaldi-stable"] = true,
    ["microsoft-edge"] = true,
    ["microsoft-edge-stable"] = true,
}

-- Affordance: A browser window affords being isolated to an empty workspace.
function Browser.isolate(window, display)
    if not window or not Browser.identifiers[window.class] then 
        return 
    end

    local start = 3
    local maximum = 20
    local occupied = {}
    local instances = display.get_windows()

    for _, instance in ipairs(instances) do
        if instance.address ~= window.address and Browser.identifiers[instance.class] then
            if instance.workspace then
                occupied[instance.workspace.id] = true
            end
        end
    end

    local target = start
    for index = start, maximum do
        if not occupied[index] then
            target = index
            break
        end
    end

    if not window.workspace or window.workspace.id ~= target then
        display.dispatch(display.dsp.window.move({ workspace = target, window = "address:" .. window.address }))
    end
end

return Browser
