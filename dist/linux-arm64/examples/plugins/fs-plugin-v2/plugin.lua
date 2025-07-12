-- Enhanced filesystem plugin v2.0.0 for hype
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

-- NEW in v2.0.0: Copy a file
function fs.copyFile(source, destination)
    local content, err = fs.readFile(source)
    if not content then
        return false, "Failed to read source file: " .. (err or "unknown error")
    end
    
    local success, err = fs.writeFile(destination, content)
    if not success then
        return false, "Failed to write destination file: " .. (err or "unknown error")
    end
    
    return true, nil
end

-- NEW in v2.0.0: Move/rename a file
function fs.moveFile(source, destination)
    local success = os.rename(source, destination)
    if success then
        return true, nil
    else
        return false, "Failed to move file from " .. source .. " to " .. destination
    end
end

-- NEW in v2.0.0: Delete a file
function fs.deleteFile(filepath)
    local success = os.remove(filepath)
    if success then
        return true, nil
    else
        return false, "Failed to delete file: " .. filepath
    end
end

-- NEW in v2.0.0: Get plugin version
function fs.version()
    return "2.0.0"
end

return fs