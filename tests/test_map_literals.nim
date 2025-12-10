## Test script for map literal support in Nimini

import nimini

let code = """
# Test basic map literal
var person = {"name": "Alice", "age": 30}
print(person["name"])
print(person["age"])

# Test empty map
var empty = {}
print(empty)

# Test map with numeric values
var config = {"width": 800, "height": 600, "fps": 60}
print(config["width"])

# Test nested structures
var data = {"items": [1, 2, 3], "count": 3}
print(data["items"])
print(data["count"])

# Test updating map values
var settings = {"volume": 50}
settings["volume"] = 75
print(settings["volume"])
"""

initRuntime()
let tokens = tokenizeDsl(code)
let program = parseDsl(tokens)
execProgram(program, runtimeEnv)
