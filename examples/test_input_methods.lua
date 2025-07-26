-- Test what methods InputField supports
local inputField = tui.newInputField()

-- Try to find all methods
local methods_to_test = {
    "SetDoneFunc",
    "SetChangedFunc", 
    "SetFinishedFunc",
    "SetAcceptanceFunc",
    "SetAutocompleteFunc",
    "SetText",
    "GetText",
    "SetLabel",
    "SetPlaceholder",
    "SetFieldWidth",
    "SetFieldBackgroundColor",
    "SetFieldTextColor",
    "SetPlaceholderTextColor",
    "SetBorder",
    "SetTitle",
    "SetTitleAlign",
    "SetTitleColor",
    "SetBackgroundColor",
    "SetBorderColor",
    "SetBorderPadding",
    "SetDrawFunc"
}

print("Testing InputField methods:")
for _, method in ipairs(methods_to_test) do
    if inputField[method] then
        print("✓", method, "exists")
    else
        print("✗", method, "does not exist")
    end
end

-- Test SetChangedFunc if it exists
if inputField.SetChangedFunc then
    print("\nTesting SetChangedFunc...")
    inputField:SetChangedFunc(function(text)
        print("Text changed to:", text)
    end)
end