-- Test REPL features
print("Testing table formatting...")

local t = {
    name = "John",
    age = 30,
    hobbies = {"coding", "reading", "gaming"},
    address = {
        street = "123 Main St",
        city = "Anytown",
        zip = 12345
    },
    active = true,
    callback = function() end
}

print("Table t =", t)

-- Test escape sequences
print("\nTesting string formatting...")
local s = 'Hello "World"'
print("String s =", s)

print("\nTesting history...")
print("Type multiple commands then use Up/Down arrows to navigate")