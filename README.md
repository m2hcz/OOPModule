# AdvancedClassModule++

**Advanced OOP utilities for Luau** — a compact, battle-tested class system for Roblox/Luau projects: properties, events, binding, scheduling, snapshot/undo, serialization, mixins, plugins and more.

---

## Table of contents

* [Overview](#overview)
* [Key features](#key-features)
* [Installation](#installation)
* [Quick examples](#quick-examples)
* [API summary](#api-summary)
* [Best practices & notes](#best-practices--notes)
* [Testing](#testing)
* [Contributing](#contributing)
* [License](#license)

---

## Overview

`AdvancedClassModule++` provides a rich object system for Luau with first-class support for:

* properties (default, lazy, readonly, computed),
* event system (priorities, safe listeners),
* observers & bindings (1-way / 2-way),
* job scheduling (defer, delay, interval, debounce, throttle),
* snapshot / undo / redo history,
* JSON serialization and deserialization,
* mixins, plugins and lifecycle hooks.

Designed to be safe (listener errors don’t kill the emitter), practical for games and libraries, and easy to extend.

---

## Key features

* Create and extend classes (`extend`, `extendWith`)
* Rich properties (`defineProperty`, `defineComputed`)
* Events: `on`, `once`, `emit`, `emitAsync` with connection handles
* Binding: `bindProperty`, `bindTo`, `linkTwoWay`
* Scheduling: `defer`, `delay`, `interval`, `debounce`, `throttle`
* Snapshot/history: `snapshot`, `commit`, `undo`, `redo`
* Serialize/deserialize: `serialize`, `toJSON`, `fromJSON`
* Lifecycle: `onInit`, `postInit`, `preDestroy`, `onDestroy`
* Children management, tags, logging utilities

---

## Installation

Copy the module file into your project (e.g. `ReplicatedStorage` or `ServerScriptService`) and require it:

```lua
local AdvancedClass = require(path.to.AdvancedClass) -- adjust path
```

---

## Quick examples

### Simple class

```lua
local AdvancedClass = require(...) -- require the module

local Person = AdvancedClass:extend("Person")

function Person:constructor(name, age)
    self.name = name or "Anon"
    self.age = age or 0
end

local p = Person("Cristyan", 27)
print(p.name, p.age) --> Cristyan 27
```

### Properties and computed values

```lua
local Player = AdvancedClass:extend("Player")
Player:defineProperty("hp", { default = 100 })
Player:defineComputed("isAlive", {"hp"}, function(self) return self.hp > 0 end)

local pl = Player()
print(pl.hp)      --> 100
print(pl.isAlive) --> true
pl.hp = 0
print(pl.isAlive) --> false
```

### Events

```lua
local Emitter = AdvancedClass:extend("Emitter")
Emitter:addEvent("hit")

local obj = Emitter()
local conn = obj:on("hit", function(self, damage)
    print(self:toString() .. " took", damage)
end)

obj:emit("hit", 25)
conn:Disconnect()
```

### Two-way binding

```lua
local A = AdvancedClass:extend("A")
A:defineProperty("value", { default = 0 })

local a = A()
local b = A()
local unlink = a:linkTwoWay(b, "value", "value")

a.value = 42
print(b.value) -- 42

unlink()
```

### Snapshot / undo / redo

```lua
local Doc = AdvancedClass:extend("Doc")
Doc:defineProperty("text", { default = "" })

local d = Doc()
d.text = "v1"; d:commit()
d.text = "v2"; d:commit()

d:undo()  -- returns to "v1"
d:redo()  -- returns to "v2"
```

### Serialize / deserialize

```lua
local obj = Person("Alice", 30)
local json = obj:toJSON()

local newObj = Person()
newObj:fromJSON(json)
print(newObj.name, newObj.age)
```

---

## API summary

*(Short reference — module includes more utilities; consult source for full signatures.)*

### Class / static

* `:extend(name)` — create subclass
* `:extendWith(name, spec)` — extend with property/static spec
* `:mixin(table)` — apply mixin
* `:use(plugin)` — apply plugin
* `:defineProperty(name, desc)` — define property
* `:defineComputed(name, deps, compute)` — define computed property

### Instance

* `:destroy()`, `:isDestroyed()`
* Events: `:addEvent(name)`, `:on(name, cb, priority)`, `:once(...)`, `:emit(...)`, `:emitAsync(...)`
* Bindings: `:bindProperty(name, cb)`, `:unbindProperty(...)`, `:bindTo(target, prop)`, `:linkTwoWay(other, a, b)`
* Scheduling: `:defer(fn)`, `:delay(t, fn)`, `:interval(t, fn)`, `:debounce(fn, ms)`, `:throttle(fn, ms)`
* History: `:snapshot()`, `:commit()`, `:undo()`, `:redo()`
* Serialization: `:serialize()`, `:toJSON()`, `:fromJSON(json)`
* Children: `:addChild(child)`, `:removeChild(child)`, `:destroyChildren()`
* Tags/logging: `:log(level, msg)`, `:addTag(tag)`, `:hasTag(tag)`

---

## Best practices & notes

* `default` values that are functions are invoked per-instance at `new` time — use this for table defaults.
* `defineComputed` produces readonly derived properties (use regular properties for mutables).
* `destroy()` cancels scheduled jobs and disconnects listeners; always call it for ephemeral objects.
* Avoid serializing functions — the serializer skips them by design.
* `waitFor`-style utilities use coroutines; call from an appropriate coroutine context.

---

## Testing

Create small test scripts that exercise:

* property defaults and computed updates
* event emission and listener error handling
* two-way binding and unlink behavior
* snapshot/commit/undo/redo flows
  If you want, I can generate a basic `tests/` folder with runnable Luau/RBXScript cases.

---

## Contributing

PRs welcome. Suggested workflow:

1. Open an issue describing the feature/bug.
2. Create a clear branch (`fix/logging`, `feat/computed-cache`).
3. Include tests or example scripts demonstrating behavior.
   Please document breaking changes if you introduce them.

---

## License

Suggested: **MIT** for maximum adoption. Example header:

```
MIT © m2hcz
```

---

If you want, I’ll produce a ready-to-drop `README.md` file, add badges (CI, license), or generate a `tests/` directory with sample scripts — I can even mock a small demo project that shows property binding and undo/redo in action. No assembly required; just plug and play.
