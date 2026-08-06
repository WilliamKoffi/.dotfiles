-- Isolated concern: Input mapping. No logic, purely bindings.

local modifier = "SUPER"
local console = "rio"
local files = "thunar"
local launcher = "rofi -show drun"

return function(display, path)
    -- System Actions
    display.bind(modifier .. " + Return", display.dsp.exec_cmd("warp-terminal"))
    display.bind(modifier .. " + Q", display.dsp.window.close())
    display.bind(modifier .. " + M", display.dsp.exit())
    display.bind(modifier .. " + F", display.dsp.window.fullscreen())
    display.bind(modifier .. " + SHIFT + F", display.dsp.window.float({ action = "toggle" }))
    display.bind(modifier .. " + P", display.dsp.window.pseudo())
    display.bind(modifier .. " + J", display.dsp.layout("rotatesplit"))
    display.bind(modifier .. " + L", display.dsp.exec_cmd("hyprlock"))

    -- Launchers
    display.bind(modifier .. " + T", display.dsp.exec_cmd(path .. "/.nix-profile/bin/nixGL " .. path .. "/.nix-profile/bin/rio > /tmp/rio_error.log 2>&1"))
    display.bind(modifier .. " + E", display.dsp.exec_cmd(files))
    display.bind(modifier .. " + C", display.dsp.exec_cmd("brave-browser --new-window"))
    display.bind(modifier .. " + SHIFT + C", display.dsp.exec_cmd("brave-browser --new-window --incognito"))
    display.bind(modifier .. " + B", display.dsp.exec_cmd("google-chrome-stable --new-window"))
    display.bind(modifier .. " + R", display.dsp.exec_cmd(launcher))
    display.bind(modifier .. " + V", display.dsp.exec_cmd(path .. "/.config/hypr/scripts/cliphist-paste.lua > /tmp/cliphist_error.log 2>&1"))

    -- Focus & Navigation
    display.bind("ALT + Tab", display.dsp.window.cycle_next())
    display.bind("ALT + Tab", display.dsp.window.alter_zorder({ mode = "top" }))
    display.bind(modifier .. " + Tab", display.dsp.focus({ workspace = "previous" }))
    display.bind(modifier .. " + left", display.dsp.focus({ direction = "l" }))
    display.bind(modifier .. " + right", display.dsp.focus({ direction = "r" }))
    display.bind(modifier .. " + up", display.dsp.focus({ direction = "u" }))
    display.bind(modifier .. " + down", display.dsp.focus({ direction = "d" }))

    -- Workspaces (1 to 10)
    for index = 1, 10 do
        local keycode = 9 + index
        display.bind(modifier .. " + code:" .. keycode, display.dsp.focus({ workspace = index }))
        display.bind(modifier .. " + SHIFT + code:" .. keycode, display.dsp.window.move({ workspace = index }))
    end

    -- Special Workspace (Scratchpad)
    display.bind(modifier .. " + S", display.dsp.workspace.toggle_special("magic"))
    display.bind(modifier .. " + SHIFT + S", display.dsp.window.move({ workspace = "special:magic" }))

    -- Mouse Actions
    display.bind(modifier .. " + mouse_down", display.dsp.focus({ workspace = "e+1" }))
    display.bind(modifier .. " + mouse_up", display.dsp.focus({ workspace = "e-1" }))
    display.bind(modifier .. " + mouse:272", display.dsp.window.drag(), { mouse = true })
    display.bind(modifier .. " + mouse:273", display.dsp.window.resize(), { mouse = true })

    -- Hardware Controls
    display.bind(modifier .. " + XF86AudioRaiseVolume", display.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { ["repeat"] = true, locked = true })
    display.bind(modifier .. " + XF86AudioLowerVolume", display.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { ["repeat"] = true, locked = true })
    display.bind(modifier .. " + XF86AudioMute", display.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { ["repeat"] = true, locked = true })
    display.bind(modifier .. " + XF86AudioMicMute", display.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { ["repeat"] = true, locked = true })
    display.bind(modifier .. " + XF86MonBrightnessUp", display.dsp.exec_cmd("brightnessctl s 10%+"), { ["repeat"] = true, locked = true })
    display.bind(modifier .. " + XF86MonBrightnessDown", display.dsp.exec_cmd("brightnessctl s 10%-"), { ["repeat"] = true, locked = true })

    -- Media Player Actions
    display.bind("XF86AudioNext", display.dsp.exec_cmd("playerctl next"), { locked = true })
    display.bind("XF86AudioPause", display.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    display.bind("XF86AudioPlay", display.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    display.bind("XF86AudioPrev", display.dsp.exec_cmd("playerctl previous"), { locked = true })

    -- Lid Switch Action
    display.bind("switch:on:Lid Switch", display.dsp.exec_cmd("sh -c 'hyprlock & sleep 1; hyprctl dispatch dpms off'"), { locked = true })

    -- Screenshot Actions
    display.bind("ALT + PRINT", display.dsp.exec_cmd("grimblast --notify copy active"))
    display.bind("PRINT", display.dsp.exec_cmd("grimblast --notify copy area"))
    display.bind("SHIFT + PRINT", display.dsp.exec_cmd("grimblast --notify copy screen"))
end
