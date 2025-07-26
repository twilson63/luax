-- Demo script to showcase REPL features

-- Run this with: ./hype run examples/repl-demo.lua
-- Or use the REPL directly: ./hype repl

print("=== Hype REPL Demo ===")
print()

-- Example 1: Simple expressions
print("Simple math:")
print("2 + 2 =", 2 + 2)
print()

-- Example 2: Tables with nice formatting
print("Tables are formatted nicely in the REPL:")
local person = {
    name = "John Doe",
    age = 30,
    email = "john@example.com",
    hobbies = {"coding", "gaming", "reading"},
    address = {
        street = "123 Main St",
        city = "Anytown",
        zip = 12345
    }
}
print("person =", person)
print("(In REPL, this would be nicely formatted)")
print()

-- Example 3: Using Hype modules
print("Hype modules available:")
print("- tui: Terminal UI components")
print("- http: HTTP client/server")
print("- kv: Key-value database")
print("- crypto: Cryptographic functions")
print("- ws: WebSocket support")
print()

-- Example 4: REPL commands
print("Special REPL commands:")
print(":help    - Show help")
print(":history - Show command history")
print(":clear   - Clear output")
print()

print("Try these in the REPL:")
print('• {name="test", data={a=1, b=2}}')
print('• math')
print('• string')
print('• for i=1,5 do print(i) end')
print('• local http = require("http")')