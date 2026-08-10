-- Lexical Domain: History. Encapsulates all reading/writing of the clipboard log.
local History = {}

function History.populate(cache)
    local stream = io.popen("cliphist list")
    if not stream then return false end

    local input = io.open(cache .. "/input", "w")
    if not input then
        stream:close()
        return false
    end

    for record in stream:lines() do
        if not record:match("^[0-9]+%s+<meta http-equiv=") then
            local identifier, extension = record:match("^([0-9]+)%s+binary.*%.?(%w+)$")
            
            if not identifier then identifier, extension = record:match("^([0-9]+)%s+%[%[%s+binary.*%.?(%w+)%s*%]%]$") end
            if not identifier then identifier, extension = record:match("^([0-9]+).-binary.-(png)") end
            if not identifier then identifier, extension = record:match("^([0-9]+).-binary.-(jpg)") end
            if not identifier then identifier, extension = record:match("^([0-9]+).-binary.-(jpeg)") end
            if not identifier then identifier, extension = record:match("^([0-9]+).-binary.-(bmp)") end

            if identifier and extension then
                local icon = cache .. "/" .. identifier .. "." .. extension
                os.execute(string.format("echo %s | cliphist decode > %s 2>/dev/null", identifier, icon))
                input:write(string.format("%s\0icon\x1f%s\n", record, icon))
            else
                input:write(record .. "\n")
            end
        end
    end
    
    stream:close()
    input:close()
    return true
end

-- Affordance: History affords being extracted to the system clipboard
function History.extract(selection, cache)
    local target = cache .. "/selection"
    local file = io.open(target, "w")
    if file then
        file:write(selection)
        file:close()
        os.execute("cliphist decode < " .. target .. " | copyq copy -")
        os.execute("sleep 0.1")
    end
end

-- Affordance: History affords being read as a preview file
function History.read(selection, cache)
    local target = cache .. "/selection"
    local file = io.open(target, "w")
    if file then
        file:write(selection)
        file:close()
        local preview = cache .. "/preview"
        os.execute("cliphist decode < " .. target .. " > " .. preview .. " 2>/dev/null")
    end
end

return History
