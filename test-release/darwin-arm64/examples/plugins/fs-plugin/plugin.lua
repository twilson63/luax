-- Simple filesystem plugin for hype
local fs = {}

-- Read a file and return its contents
function fs.readFile(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return nil, "Failed to open file: " .. filepath
    end
    
    local content = file:read("*a")
    file:close()
    
    return content, nil
end

-- Write content to a file
function fs.writeFile(filepath, content)
    local file = io.open(filepath, "w")
    if not file then
        return false, "Failed to open file for writing: " .. filepath
    end
    
    file:write(content)
    file:close()
    
    return true, nil
end

-- Check if a file exists
function fs.exists(filepath)
    local file = io.open(filepath, "r")
    if file then
        file:close()
        return true
    end
    return false
end

-- Get file size
function fs.size(filepath)
    local file = io.open(filepath, "r")
    if not file then
        return nil, "File not found: " .. filepath
    end
    
    local size = file:seek("end")
    file:close()
    
    return size, nil
end

-- List files in a directory (simple implementation)
function fs.listDir(dirpath)
    -- This is a simple implementation using os.execute
    -- In a real plugin, you'd want more robust directory listing
    local handle = io.popen("ls -1 " .. dirpath .. " 2>/dev/null")
    if not handle then
        return nil, "Failed to list directory: " .. dirpath
    end
    
    local files = {}
    for line in handle:lines() do
        table.insert(files, line)
    end
    handle:close()
    
    return files, nil
end

-- Create a directory
function fs.mkdir(dirpath)
    local success = os.execute("mkdir -p " .. dirpath)
    if success then
        return true, nil
    else
        return false, "Failed to create directory: " .. dirpath
    end
end

return fs