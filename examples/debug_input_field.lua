-- Debug InputField methods
print("Debugging InputField...")

local inputField = tui.newInputField()
print("inputField type:", type(inputField))

-- List all available methods
print("\nTrying to access methods:")
local methods = {
    "SetDoneFunc",
    "SetInputCapture",
    "SetText",
    "GetText",
    "SetLabel",
    "SetPlaceholder",
    "SetBorder",
    "SetTitle"
}

for _, method in ipairs(methods) do
    local value = inputField[method]
    print(method .. ":", type(value))
end

-- Test if SetDoneFunc works
print("\nTesting SetDoneFunc...")
local ok1, err1 = pcall(function()
    inputField:SetDoneFunc(function(key)
        print("Key pressed:", key)
    end)
end)
print("SetDoneFunc result:", ok1, err1 or "OK")

-- Check if there's a different method for input capture
print("\nChecking for alternative input methods...")
local mt = getmetatable(inputField)
if mt and mt.__index then
    print("Has metatable with __index")
end