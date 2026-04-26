# AdvancedClassModule++

Advanced OOP utilities for Roblox Luau: classes, inheritance, typed-style managed properties, computed values, events, observers, bindings, scheduling, child ownership, logging, serialization, snapshots, undo/redo, mixins, plugins, interfaces, abstract classes, and sealed classes.

This repository contains a single drop-in ModuleScript:

```text
module.lua
```

## Status

Updated on 2026-04-26 with a safer and more consistent runtime core.

Highlights in this version:

- Fixed subclass metadata inheritance so `extend()` no longer leaks or overwrites `className`, `super`, `__props`, `__static`, and related class internals.
- Added internal public-value storage so managed properties keep validation, observers, computed invalidation, and `changed` events active after the first assignment.
- Improved computed-property cache invalidation, including dependent computed chains.
- Improved `serialize`, `deserialize`, `snapshot`, `undo`, and `redo` so readonly/computed runtime fields are handled safely.
- Fixed `cancelAllJobs()` so cancellation cannot skip handles while mutating job buckets.
- Improved `clone()` and `deepClone()` to rebuild runtime containers and assign fresh instance ids.
- Added more defensive checks for callbacks, logger assignment, children, and `waitForAny`.

## Installation

Copy `module.lua` into your Roblox project as a ModuleScript, commonly in `ReplicatedStorage` or `ServerScriptService`.

```lua
local AdvancedClass = require(path.to.module)
```

Example from `ReplicatedStorage`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AdvancedClass = require(ReplicatedStorage.AdvancedClass)
```

## Quick Start

```lua
local AdvancedClass = require(path.to.module)

local PlayerState = AdvancedClass:extend("PlayerState")

PlayerState:defineProperty("health", {
	default = 100,
	coerce = function(_, value)
		return math.clamp(value, 0, 100)
	end,
	validate = function(_, value)
		return type(value) == "number", "health must be a number"
	end,
})

PlayerState:defineComputed("isAlive", { "health" }, function(self)
	return self.health > 0
end)

function PlayerState:constructor(player)
	self.player = player
end

local state = PlayerState.new(game.Players.LocalPlayer)

state:on("changed:health", function(_, newValue, oldValue)
	print("Health changed", oldValue, "->", newValue)
end)

state.health = 75
print(state.isAlive) -- true
```

## Properties

Use `defineProperty` for values that need defaults, validation, coercion, serialization control, lazy loading, or custom getters/setters.

```lua
local Profile = AdvancedClass:extend("Profile")

Profile:defineProperty("displayName", {
	default = "Player",
	coerce = function(_, value)
		return tostring(value)
	end,
	validate = function(_, value)
		return #value > 0, "displayName cannot be empty"
	end,
	serializable = true,
})
```

Descriptor fields:

- `default`: static default value or factory function.
- `lazy`: function evaluated on first read.
- `get`: custom getter.
- `set`: custom setter.
- `readonly`: prevents direct assignment.
- `coerce`: normalizes incoming values before validation.
- `validate`: returns `true` or `false, reason`.
- `compute`: computed value function.
- `dependsOn`: dependency list for computed invalidation.
- `cache`: set to `false` to recompute on every read.
- `serializable`: set to `false` to exclude from snapshots/serialization.

## Computed Values

```lua
local CharacterStats = AdvancedClass:extend("CharacterStats")

CharacterStats:defineProperty("strength", { default = 10 })
CharacterStats:defineProperty("weaponPower", { default = 5 })

CharacterStats:defineComputed("attackPower", { "strength", "weaponPower" }, function(self)
	return self.strength + self.weaponPower
end)

local stats = CharacterStats()
print(stats.attackPower) -- 15
stats.strength = 20
print(stats.attackPower) -- 25
```

Computed values are readonly. By default they are cached and invalidated when dependencies change.

## Events

```lua
local Emitter = AdvancedClass:extend("Emitter")
local obj = Emitter()

local conn = obj:on("hit", function(self, damage)
	print(self:toString(), "took", damage)
end)

obj:emit("hit", 25)
conn:Disconnect()
```

Supported event helpers:

- `addEvent(name)`
- `on(name, callback, priority?)`
- `once(name, callback, priority?)`
- `onceWithTimeout(name, timeout, callback)`
- `off(name, callback)`
- `offAll(name?)`
- `emit(name, ...)`
- `emitAsync(name, ...)`
- `waitFor(name)`
- `waitForWithTimeout(name, timeout)`
- `waitForAny({ names })`

Listeners are called through guarded execution so one listener error does not stop the emitter.

## Observers and Binding

```lua
local Settings = AdvancedClass:extend("Settings")
Settings:defineProperty("volume", { default = 50 })

local settings = Settings()

local unwatch = settings:watch({ "volume" }, function(prop, newValue, oldValue)
	print(prop, oldValue, newValue)
end)

settings.volume = 80
unwatch()
```

Binding helpers:

- `bindProperty(propertyName, callback)`
- `unbindProperty(propertyName, callback)`
- `watch(props, callback)`
- `watchAll(predicate?, callback)`
- `bindTo(target, targetProp, sourceProp?)`
- `linkTwoWay(other, propA, propB)`

## Scheduling

```lua
local obj = AdvancedClass()

local delayHandle = obj:delay(2, function()
	print("runs later unless cancelled or destroyed")
end)

delayHandle.cancel()
```

Scheduling helpers:

- `defer(callback)`
- `delay(seconds, callback)`
- `interval(seconds, callback)`
- `debounce(fn, ms)`
- `throttle(fn, ms)`
- `cancelAllJobs()`

All scheduled work is tied to the instance and cancelled by `destroy()`.

## Lifecycle

Classes can define lifecycle hooks:

```lua
function MyClass:onInit()
end

function MyClass:constructor(...)
end

function MyClass:postInit()
end

function MyClass:preDestroy()
end

function MyClass:onDestroy()
end
```

Call `instance:destroy()` to emit destroy events, destroy children, cancel jobs, disconnect listeners, and clear runtime containers.

## Serialization and History

```lua
local Doc = AdvancedClass:extend("Doc")
Doc:defineProperty("text", { default = "" })

local doc = Doc()
doc.text = "v1"
doc:commit()

doc.text = "v2"
doc:commit()

doc:undo()
print(doc.text) -- v1

local snapshot = doc:serialize()
doc:deserialize(snapshot)
```

Available helpers:

- `serialize()`
- `deserialize(data)`
- `toJSON()`
- `fromJSON(json)`
- `snapshot()`
- `diff(other)`
- `commit()`
- `undo()`
- `redo()`
- `clearHistory()`

Serialization skips runtime internals, private `_` fields, functions, threads, userdata, unsafe values, and recursive table loops. JSON helpers require Roblox `HttpService`.

## Class Utilities

- `extend(name)`
- `extendWith(name, spec)`
- `mixin(table)`
- `use(plugin)`
- `seal()`
- `isSealed()`
- `abstract()`
- `isAbstract()`
- `requireMethods(methods)`
- `registerInterface(name, shape)`
- `implements(interfaces)`
- `static(name, value)`
- `getStatic(name)`
- `isA(class)`
- `superCall(methodName, ...)`

## Instance Utilities

- `clone()`
- `deepClone()`
- `freeze()`
- `isDestroyed()`
- `ensureNotDestroyed()`
- `addChild(child)`
- `removeChild(child)`
- `getChildren()`
- `destroyChildren()`
- `setLogger(logger?)`
- `setLogLevel(level)`
- `log(level, message)`
- `logf(level, fmt, ...)`
- `addTag(tag)`
- `hasTag(tag)`
- `removeTag(tag)`
- `toString()`

## Best Practices

- Use `default = function() return {} end` for table defaults that should be unique per instance.
- Use `defineComputed` for derived readonly values and regular properties for mutable state.
- Call `destroy()` for temporary objects so listeners and scheduled jobs are released.
- Prefer `serializable = false` for runtime-only public properties.
- Use `commit()` before state changes you want to undo later.

## Testing

There is no bundled test runner yet. Recommended smoke checks:

- Property defaults, validation, coercion, and observer notifications.
- Computed properties updating after dependency changes.
- Event priority, `once`, disconnect, and listener error isolation.
- `delay`, `interval`, `debounce`, `throttle`, and `cancelAllJobs`.
- `serialize`, `deserialize`, `commit`, `undo`, and `redo`.
- `clone` and `deepClone` producing fresh ids and empty runtime containers.

## License

Add your preferred license file if this repository is intended for public reuse.
