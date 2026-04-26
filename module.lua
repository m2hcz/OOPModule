--[[
	AdvancedClassModule++
	---------------------
	--> Purpose:
	    Provide a reusable OOP-style class foundation for Luau with typed
	    properties, lifecycle hooks, events, observers, job scheduling,
	    parent/child ownership, logging, serialization, and history support.

	--> Design goals:
	    Keep instance behavior explicit, remain safe for server-side use,
	    minimize accidental shared state, and make review/debug workflows easier.

	--> Notes:
	    - Property access is mediated through custom __index / __newindex logic.
	    - Computed properties can be cached and invalidated by dependency changes.
	    - Serialization intentionally skips internal runtime state and unsafe values.
	    - Destruction clears listeners, timers, and child ownership state.

	made by m2hcz with love
	1 year of project.
]]

-- --> Public type definitions
export type Connection = {
	Connected: boolean,
	Disconnect: (Connection) -> (),
}

export type PropertyDescriptor = {
	get: ((self: any) -> any)?,
	set: ((self: any, value: any) -> ())?,
	readonly: boolean?,
	default: any?,
	lazy: ((self: any) -> any)?,
	compute: ((self: any) -> any)?,
	dependsOn: { string }?,
	validate: ((self: any, value: any) -> (boolean, string?))?,
	coerce: ((self: any, value: any) -> any)?,
	serializable: boolean?,
	cache: boolean?,
}

export type Class<T> = {
	new: (...any) -> T,
	extend: (self: Class<T>, name: string?) -> Class<T>,
	extendWith: (self: Class<T>, name: string?, spec: { props: { [string]: PropertyDescriptor }?, static: { [string]: any }? }) -> Class<T>,
	isA: (self: T, class: Class<any>) -> boolean,
	constructor: ((self: T, ...any) -> ())?,
	onInit: ((self: T) -> ())?,
	postInit: ((self: T) -> ())?,
	preDestroy: ((self: T) -> ())?,
	onDestroy: ((self: T) -> ())?,
	__index: T,
	super: Class<any>?,
	className: string,
	mixin: (self: Class<T>, mixinTable: { [string]: any }) -> Class<T>,
	use: (self: Class<T>, plugin: (Class<any>) -> ()) -> Class<T>,
	seal: (self: Class<T>) -> (),
	isSealed: (self: Class<T>) -> boolean,
	abstract: (self: Class<T>) -> (),
	isAbstract: (self: Class<T>) -> boolean,
	requireMethods: (self: Class<T>, methods: { string }) -> (),
	implements: (self: Class<T>, interfaces: { string }) -> (),
	registerInterface: (self: Class<T>, name: string, shape: { [string]: boolean }) -> (),
	defineProperty: (self: Class<T>, name: string, desc: PropertyDescriptor) -> (),
	defineComputed: (self: Class<T>, name: string, dependsOn: { string }, compute: (self: T) -> any, cache: boolean?) -> (),
	removeProperty: (self: Class<T>, name: string) -> (),
	static: (self: Class<T>, name: string, value: any) -> (),
	getStatic: (self: Class<T>, name: string) -> any,
	clone: (self: T) -> T,
	deepClone: (self: T) -> T,
	destroy: (self: T) -> (),
	isDestroyed: (self: T) -> boolean,
	ensureNotDestroyed: (self: T) -> (),
	freeze: (self: T) -> (),
	superCall: (self: T, methodName: string, ...any) -> any,
	addEvent: (self: T, eventName: string) -> (),
	on: (self: T, eventName: string, callback: (...any) -> (), priority: number?) -> Connection,
	off: (self: T, eventName: string, callback: (...any) -> ()) -> (),
	offAll: (self: T, eventName: string?) -> (),
	emit: (self: T, eventName: string, ...any) -> (),
	emitAsync: (self: T, eventName: string, ...any) -> (),
	once: (self: T, eventName: string, callback: (...any) -> (), priority: number?) -> Connection,
	onceWithTimeout: (self: T, eventName: string, timeout: number, callback: (self: T, timedOut: boolean, ...any) -> ()) -> (),
	waitFor: (self: T, eventName: string) -> (...any),
	waitForWithTimeout: (self: T, eventName: string, timeout: number) -> (boolean, ...any),
	waitForAny: (self: T, events: { string }) -> (string, ...any),
	bindProperty: (self: T, propertyName: string, callback: (newValue: any, oldValue: any) -> ()) -> (),
	unbindProperty: (self: T, propertyName: string, callback: (newValue: any, oldValue: any) -> ()) -> (),
	watch: (self: T, props: { string }, callback: (prop: string, newValue: any, oldValue: any) -> ()) -> () -> (),
	watchAll: (self: T, predicate: ((prop: string, newValue: any, oldValue: any) -> boolean)?, callback: (prop: string, newValue: any, oldValue: any) -> ()) -> () -> (),
	bindTo: (self: T, target: any, targetProp: string, sourceProp: string?) -> () -> (),
	linkTwoWay: (self: T, other: any, propA: string, propB: string) -> () -> (),
	defer: (self: T, callback: () -> ()) -> { cancel: () -> (), cancelled: boolean },
	delay: (self: T, time: number, callback: () -> ()) -> { cancel: () -> (), cancelled: boolean },
	interval: (self: T, time: number, callback: () -> ()) -> { cancel: () -> (), cancelled: boolean },
	debounce: (self: T, fn: (...any) -> (), ms: number) -> (...any) -> (),
	throttle: (self: T, fn: (...any) -> (), ms: number) -> (...any) -> (),
	cancelAllJobs: (self: T) -> (),
	addChild: (self: T, child: any) -> (),
	removeChild: (self: T, child: any) -> (),
	getChildren: (self: T) -> { any },
	destroyChildren: (self: T) -> (),
	toString: (self: T) -> string,
	log: (self: T, level: string, message: string) -> (),
	logf: (self: T, level: string, fmt: string, ...any) -> (),
	setLogger: (self: T, logger: ((level: string, msg: string) -> ())?) -> (),
	setLogLevel: (self: T, level: string) -> (),
	addTag: (self: T, tag: string) -> (),
	hasTag: (self: T, tag: string) -> boolean,
	removeTag: (self: T, tag: string) -> (),
	serialize: (self: T) -> { [string]: any },
	deserialize: (self: T, data: { [string]: any }) -> (),
	toJSON: (self: T) -> string,
	fromJSON: (self: T, json: string) -> (),
	snapshot: (self: T) -> { [string]: any },
	diff: (self: T, other: T | { [string]: any }) -> { [string]: { old: any, new: any } },
	commit: (self: T) -> (),
	undo: (self: T) -> boolean,
	redo: (self: T) -> boolean,
	clearHistory: (self: T) -> (),
}


-- --> Internal configuration and helper utilities
local MAX_LISTENERS_PER_EVENT = 512

local INTERNAL_INSTANCE_KEYS = {
	class = true,
	parent = true,
}

local RUNTIME_CLONE_KEYS = {
	_events = true,
	_connections = true,
	_observers = true,
	_jobs = true,
	_children = true,
	_history = true,
	parent = true,
}

local CLASS_METADATA_KEYS = {
	__index = true,
	__props = true,
	__sealed = true,
	__abstract = true,
	__required = true,
	__interfaces = true,
	__ifaces = true,
	__static = true,
	__computedDeps = true,
	className = true,
	super = true,
	new = true,
}

local getClock = function()
	return os.clock()
end

do
	local ok, workspaceRef = pcall(function()
		return workspace
	end)
	if ok and workspaceRef and workspaceRef.GetServerTimeNow then
		getClock = function()
			return workspaceRef:GetServerTimeNow()
		end
	elseif type(time) == 'function' then
		getClock = time
	end
end

-- --> Returns the most appropriate runtime clock value available in the current environment.
local function now(): number
	local ok, result = pcall(getClock)
	if ok and type(result) == 'number' then
		return result
	end
	return os.clock()
end

-- --> Normalizes thrown values into a readable message and includes a traceback when available.
local function formatError(err: any): string
	local message = tostring(err)
	if debug and debug.traceback then
		local ok, trace = pcall(function()
			return debug.traceback(message, 2)
		end)
		if ok and trace then
			return trace
		end
	end
	return message
end

-- --> Executes a callback safely, logs context-rich failures, and returns xpcall-style success data.
local function safeCall(context: string, fn: (...any) -> any, ...: any): (boolean, any)
	local ok, result = xpcall(fn, formatError, ...)
	if not ok then
		warn(('[AdvancedClass:%s] %s'):format(context, tostring(result)))
	end
	return ok, result
end

local HttpService
pcall(function()
	HttpService = game:GetService('HttpService')
end)

-- --> Encodes a Lua value to JSON through HttpService.
local function jsonEncode(value: any): string
	if not HttpService then
		error('HttpService is unavailable; JSON encoding is not supported in this environment')
	end
	return HttpService:JSONEncode(value)
end

-- --> Decodes a JSON payload through HttpService.
local function jsonDecode(value: string): any
	if not HttpService then
		error('HttpService is unavailable; JSON decoding is not supported in this environment')
	end
	return HttpService:JSONDecode(value)
end

local tableFreeze = table and table.freeze or function(t)
	return t
end

-- --> Creates a new array copy while preserving element order.
local function shallowCopyArray<T>(list: { T }): { T }
	local out = table.create(#list)
	for i = 1, #list do
		out[i] = list[i]
	end
	return out
end

-- --> Creates a shallow key/value copy of a dictionary-like table.
local function shallowCopyMap(source: { [any]: any }?): { [any]: any }
	local out = {}
	if not source then
		return out
	end
	for key, value in pairs(source) do
		out[key] = value
	end
	return out
end

-- --> Clears all entries from a table while supporting runtimes without table.clear.
local function clearTable(target: { [any]: any })
	if table.clear then
		table.clear(target)
		return
	end
	for key in pairs(target) do
		target[key] = nil
	end
end

-- --> Removes the first matching array element found while scanning from the end.
local function removeArrayValue<T>(list: { T }, value: T)
	for i = #list, 1, -1 do
		if list[i] == value then
			table.remove(list, i)
			return
		end
	end
end

-- --> Inserts an event listener so higher priority entries execute earlier.
local function insertListenerByPriority(list: { any }, listener: any)
	local inserted = false
	for i = #list, 1, -1 do
		if (list[i].priority or 0) >= (listener.priority or 0) then
			table.insert(list, i + 1, listener)
			inserted = true
			break
		end
	end
	if not inserted then
		table.insert(list, 1, listener)
	end
end

-- --> Recursively copies tables and preserves shared references through a seen-map.
local function deepCopy(value: any, seen: { [any]: any }?): any
	if type(value) ~= 'table' then
		return value
	end
	seen = seen or {}
	if seen[value] then
		return seen[value]
	end
	local copy = {}
	seen[value] = copy
	for key, item in pairs(value) do
		copy[deepCopy(key, seen)] = deepCopy(item, seen)
	end
	return copy
end

-- --> Performs structural equality checks without relying on JSON serialization.
local function deepEqual(a: any, b: any, seenA: { [any]: any }?, seenB: { [any]: any }?): boolean
	if a == b then
		return true
	end
	local typeA = type(a)
	if typeA ~= type(b) then
		return false
	end
	if typeA ~= 'table' then
		return false
	end
	seenA = seenA or {}
	seenB = seenB or {}
	local mappedB = seenA[a]
	local mappedA = seenB[b]
	if mappedB or mappedA then
		return mappedB == b and mappedA == a
	end
	seenA[a] = b
	seenB[b] = a
	for key, valueA in pairs(a) do
		if not deepEqual(valueA, b[key], seenA, seenB) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end

-- --> Materializes a safe default value, cloning tables and evaluating factory functions.
local function cloneDefault(value: any): any
	if type(value) == 'function' then
		return value()
	end
	if type(value) == 'table' then
		return deepCopy(value)
	end
	return value
end

-- --> Copies a property descriptor without sharing dependency arrays between classes.
local function copyDescriptor(desc: PropertyDescriptor): PropertyDescriptor
	local copy = {} :: any
	for key, value in pairs(desc) do
		if key == 'dependsOn' and type(value) == 'table' then
			copy[key] = shallowCopyArray(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- --> Returns whether a key belongs directly on the instance table.
local function isInternalInstanceKey(key: any): boolean
	return type(key) == 'string' and (INTERNAL_INSTANCE_KEYS[key] == true or string.sub(key, 1, 1) == '_')
end

-- --> Lazily creates the public value store used to keep __newindex active for future writes.
local function getValueStore(self: any): { [any]: any }
	local values = rawget(self, '_values')
	if not values then
		values = {}
		rawset(self, '_values', values)
	end
	return values
end

-- --> Reads public stored state while falling back to legacy raw fields if present.
local function getStoredValue(self: any, key: any): any
	local values = rawget(self, '_values')
	if values and values[key] ~= nil then
		return values[key]
	end
	return rawget(self, key)
end

-- --> Writes public stored state and removes same-name raw fields so __newindex remains active.
local function setStoredValue(self: any, key: any, value: any)
	local values = getValueStore(self)
	values[key] = value
	if rawget(self, key) ~= nil then
		rawset(self, key, nil)
	end
end

-- --> Removes a public stored value and any legacy raw field with the same key.
local function clearStoredValue(self: any, key: any)
	local values = rawget(self, '_values')
	if values then
		values[key] = nil
	end
	if rawget(self, key) ~= nil then
		rawset(self, key, nil)
	end
end

-- --> Serialization guards
local RESERVED_SERIALIZATION_KEYS = {
	class = true,
	parent = true,
	_events = true,
	_connections = true,
	_observers = true,
	_values = true,
	_jobs = true,
	_children = true,
	_history = true,
	_logger = true,
	_computedCache = true,
	_computedDirty = true,
	_destroyed = true,
}

-- --> Gets a managed property descriptor from an instance's class.
local function getPropertyDescriptor(self: any, key: any): PropertyDescriptor?
	local class = rawget(self, 'class')
	local props = class and rawget(class, '__props') or nil
	return props and props[key] or nil
end

-- --> Returns whether a field is eligible for external serialization output.
local function isSerializableKey(self: any, key: any): boolean
	if type(key) ~= 'string' then
		return false
	end
	if RESERVED_SERIALIZATION_KEYS[key] then
		return false
	end
	if string.sub(key, 1, 1) == '_' then
		return false
	end
	local desc = getPropertyDescriptor(self, key)
	if desc and desc.serializable == false then
		return false
	end
	return true
end

-- --> Returns whether serialized input may be applied back to an instance.
local function isDeserializableKey(self: any, key: any): boolean
	if not isSerializableKey(self, key) then
		return false
	end
	local desc = getPropertyDescriptor(self, key)
	if not desc then
		return true
	end
	if desc.readonly then
		return false
	end
	if (desc.compute or desc.get) and not desc.set then
		return false
	end
	return true
end

-- --> Removes a computed property from every dependency bucket on a class.
local function removeComputedDependencies(classObj: any, name: string)
	local dependencyMap = rawget(classObj, '__computedDeps')
	if not dependencyMap then
		return
	end
	for dependency, dependents in pairs(dependencyMap) do
		for i = #dependents, 1, -1 do
			if dependents[i] == name then
				table.remove(dependents, i)
			end
		end
		if #dependents == 0 then
			dependencyMap[dependency] = nil
		end
	end
end

-- --> Registers dependency edges for a computed descriptor, avoiding duplicates.
local function registerComputedDependencies(classObj: any, name: string, desc: PropertyDescriptor)
	if not desc.compute or type(desc.dependsOn) ~= 'table' then
		return
	end
	for _, dependency in ipairs(desc.dependsOn) do
		local dependents = classObj.__computedDeps[dependency]
		if not dependents then
			dependents = {}
			classObj.__computedDeps[dependency] = dependents
		end
		local exists = false
		for _, existing in ipairs(dependents) do
			if existing == name then
				exists = true
				break
			end
		end
		if not exists then
			table.insert(dependents, name)
		end
	end
end

-- --> Looks up a registered interface shape across the superclass chain.
local function collectInterfaceShape(classObj: any, name: string): { [string]: boolean }?
	local current = classObj
	while current do
		local registry = rawget(current, '__ifaces')
		if registry and registry[name] then
			return registry[name]
		end
		current = current.super
	end
	return nil
end

-- --> Collects all declared interfaces inherited by a class.
local function collectImplementedInterfaces(classObj: any): { string }
	local result = {}
	local seen = {}
	local current = classObj
	while current do
		local interfaces = rawget(current, '__interfaces')
		if interfaces then
			for name, enabled in pairs(interfaces) do
				if enabled and not seen[name] then
					seen[name] = true
					table.insert(result, name)
				end
			end
		end
		current = current.super
	end
	return result
end

-- --> Broadcasts observer callbacks and change events for a property update.
local function notifyChange(self: any, key: string, newValue: any, oldValue: any)
	if deepEqual(newValue, oldValue) then
		return
	end
	local observers = self._observers and self._observers[key]
	if observers then
		local snapshot = shallowCopyArray(observers)
		for _, callback in ipairs(snapshot) do
			safeCall('observer:' .. tostring(key), callback, newValue, oldValue)
		end
	end
	if self.emit then
		self:emit('changed', key, newValue, oldValue)
		self:emit('changed:' .. tostring(key), newValue, oldValue)
	end
end

-- --> Invalidates and refreshes computed fields that depend on a changed property.
local function invalidateComputedForDependency(self: any, dependency: string, visited: { [string]: boolean }?)
	visited = visited or {}
	if visited[dependency] then
		return
	end
	visited[dependency] = true

	local class = rawget(self, 'class')
	local dependencyMap = class and rawget(class, '__computedDeps') or nil
	local dependents = dependencyMap and dependencyMap[dependency] or nil
	if not dependents then
		return
	end
	local props = class and rawget(class, '__props') or nil
	local cache = rawget(self, '_computedCache')
	local dirty = rawget(self, '_computedDirty')
	for _, propName in ipairs(dependents) do
		local desc = props and props[propName]
		if desc and desc.compute then
			if desc.cache == false then
				invalidateComputedForDependency(self, propName, visited)
			elseif cache and dirty then
				if cache[propName] ~= nil and not dirty[propName] then
					local oldValue = cache[propName]
					dirty[propName] = true
					local newValue = desc.compute(self)
					cache[propName] = newValue
					dirty[propName] = false
					notifyChange(self, propName, newValue, oldValue)
				else
					dirty[propName] = true
				end
				invalidateComputedForDependency(self, propName, visited)
			else
				invalidateComputedForDependency(self, propName, visited)
			end
		end
	end
end

-- --> Centralized instance property resolution for raw values, getters, lazy values, and computed properties.
local function instanceIndex(tbl: any, key: any)
	local class = rawget(tbl, 'class')
	local props = class and rawget(class, '__props') or nil
	if props then
		local desc = props[key]
		if desc then
			if desc.get then
				return desc.get(tbl)
			end
			if desc.compute then
				local shouldCache = desc.cache ~= false
				if shouldCache then
					local cache = rawget(tbl, '_computedCache')
					local dirty = rawget(tbl, '_computedDirty')
					if cache and dirty and cache[key] ~= nil and not dirty[key] then
						return cache[key]
					end
					local computed = desc.compute(tbl)
					if cache then
						cache[key] = computed
					end
					if dirty then
						dirty[key] = false
					end
					return computed
				end
				return desc.compute(tbl)
			end
			local storedValue = getStoredValue(tbl, key)
			if storedValue ~= nil then
				if rawget(tbl, key) ~= nil then
					setStoredValue(tbl, key, storedValue)
				end
				return storedValue
			end
			if desc.lazy then
				local lazyValue = desc.lazy(tbl)
				setStoredValue(tbl, key, lazyValue)
				notifyChange(tbl, key, lazyValue, nil)
				return lazyValue
			end
		end
	end
	local values = rawget(tbl, '_values')
	if values and values[key] ~= nil then
		return values[key]
	end
	local current = class
	while current do
		local value = rawget(current, key)
		if value ~= nil then
			return value
		end
		current = current.super
	end
	return rawget(tbl, key)
end

-- --> Centralized property assignment with validation, coercion, invalidation, and change notification.
local function propertyNewIndex(tbl: any, key: any, value: any)
	local class = rawget(tbl, 'class')
	local props = class and rawget(class, '__props') or nil
	local desc = props and props[key] or nil

	if not desc and isInternalInstanceKey(key) then
		rawset(tbl, key, value)
		return
	end

	local oldValue
	if desc and desc.get then
		oldValue = desc.get(tbl)
	else
		oldValue = getStoredValue(tbl, key)
	end

	if desc then
		if desc.readonly then
			error(("Property '%s' is readonly"):format(tostring(key)))
		end
		if desc.coerce then
			value = desc.coerce(tbl, value)
		end
		if desc.validate then
			local ok, reason = desc.validate(tbl, value)
			if not ok then
				error(("Invalid value for property '%s'%s"):format(tostring(key), reason and (': ' .. tostring(reason)) or ''))
			end
		end
		if desc.set then
			local ok = safeCall('property:set:' .. tostring(key), desc.set, tbl, value)
			if not ok then
				return
			end
			local rawAssigned = rawget(tbl, key)
			if rawAssigned ~= nil then
				setStoredValue(tbl, key, rawAssigned)
			end
			local newValue
			if desc.get then
				newValue = desc.get(tbl)
			else
				newValue = getStoredValue(tbl, key)
			end
			if not deepEqual(newValue, oldValue) then
				tbl._updatedAt = now()
				invalidateComputedForDependency(tbl, tostring(key))
				notifyChange(tbl, tostring(key), newValue, oldValue)
			end
			return
		end
	end

	if deepEqual(oldValue, value) then
		return
	end

	if value == nil then
		clearStoredValue(tbl, key)
	else
		setStoredValue(tbl, key, value)
	end
	tbl._updatedAt = now()
	invalidateComputedForDependency(tbl, tostring(key))
	notifyChange(tbl, tostring(key), value, oldValue)
end

-- --> Creates a disconnectable event handle tied to an owner instance and event bucket.
local function makeConnection(owner: any, eventName: string, listener: any): Connection
	local conn = { Connected = true } :: any
	function conn:Disconnect()
		if not self.Connected then
			return
		end
		self.Connected = false
		local store = owner._events
		local list = store and store[eventName]
		if list then
			removeArrayValue(list, listener)
		end
		removeArrayValue(owner._connections, self)
	end
	listener.connection = conn
	return conn
end

-- --> Recursively converts values into a serialization-safe representation.
local function serializeValue(self: any, value: any, seen: { [any]: boolean }): any
	local valueType = type(value)
	if valueType == 'function' or valueType == 'thread' or valueType == 'userdata' then
		return nil
	end
	if valueType ~= 'table' then
		return value
	end
	if seen[value] then
		return '<recursive>'
	end
	seen[value] = true
	local result = {}
	for key, item in pairs(value) do
		if not (type(key) == 'string' and string.sub(key, 1, 1) == '_') then
			local encodedKey = serializeValue(self, key, seen)
			local encodedValue = serializeValue(self, item, seen)
			if encodedKey ~= nil and encodedValue ~= nil then
				result[encodedKey] = encodedValue
			end
		end
	end
	seen[value] = nil
	return result
end

-- --> Builds the current serialized snapshot for an instance.
local function collectSerializableSnapshot(self: any): { [string]: any }
	local snapshot = {}
	local seen = {}
	local values = rawget(self, '_values')
	if values then
		for key, value in pairs(values) do
			if isSerializableKey(self, key) then
				local encoded = serializeValue(self, value, seen)
				if encoded ~= nil then
					snapshot[key] = encoded
				end
			end
		end
	end
	for key, value in pairs(self) do
		local desc = getPropertyDescriptor(self, key)
		if isSerializableKey(self, key) and snapshot[key] == nil and not (desc and (desc.get or desc.compute)) then
			local encoded = serializeValue(self, value, seen)
			if encoded ~= nil then
				snapshot[key] = encoded
			end
		end
	end
	local class = rawget(self, 'class')
	local props = class and rawget(class, '__props') or nil
	if props then
		for key, desc in pairs(props) do
			if isSerializableKey(self, key) and desc.serializable ~= false and snapshot[key] == nil then
				local ok, resolved = pcall(function()
					return self[key]
				end)
				if ok and resolved ~= nil and type(resolved) ~= 'function' and type(resolved) ~= 'thread' and type(resolved) ~= 'userdata' then
					local encoded = serializeValue(self, resolved, seen)
					if encoded ~= nil then
						snapshot[key] = encoded
					end
				end
			end
		end
	end
	return snapshot
end

-- --> Replaces serializable instance state with a previously captured snapshot.
local function applySnapshot(self: any, snapshot: { [string]: any })
	local current = collectSerializableSnapshot(self)
	for key in pairs(current) do
		if snapshot[key] == nil then
			if isDeserializableKey(self, key) then
				propertyNewIndex(self, key, nil)
			else
				clearStoredValue(self, key)
			end
		end
	end
	for key, value in pairs(snapshot) do
		if isDeserializableKey(self, key) then
			propertyNewIndex(self, key, deepCopy(value))
		else
			clearStoredValue(self, key)
		end
	end
	local class = rawget(self, 'class')
	local props = class and rawget(class, '__props') or nil
	local dirty = rawget(self, '_computedDirty')
	local cache = rawget(self, '_computedCache')
	if cache then
		clearTable(cache)
	end
	if props and dirty then
		for key, desc in pairs(props) do
			if desc.compute and desc.cache ~= false then
				dirty[key] = true
			end
		end
	end
	self._updatedAt = now()
	self:emit('restored')
end

-- --> Allocates a cancellable job handle and tracks it inside a job bucket.
local function createJobHandle(bucket: { any }): any
	local handle = { cancelled = false }
	function handle.cancel()
		if handle.cancelled then
			return
		end
		handle.cancelled = true
		removeArrayValue(bucket, handle)
	end
	table.insert(bucket, handle)
	return handle
end

-- --> Removes a finished or cancelled job handle from its tracking bucket.
local function finalizeJobHandle(bucket: { any }, handle: any)
	removeArrayValue(bucket, handle)
end

-- --> Base class definition
local AdvancedClass = {} :: Class<any>
AdvancedClass.__index = AdvancedClass
AdvancedClass.className = 'AdvancedClass'
AdvancedClass.super = nil
AdvancedClass.__props = {}
AdvancedClass.__sealed = false
AdvancedClass.__abstract = false
AdvancedClass.__required = {}
AdvancedClass.__interfaces = {}
AdvancedClass.__ifaces = {}
AdvancedClass.__static = {}
AdvancedClass.__computedDeps = {}

--> Applies a plugin function to the class and returns the class for chaining.
function AdvancedClass:use(plugin)
	plugin(self)
	return self
end

--> Marks the class as sealed. Notes: A sealed class cannot be extended further.
function AdvancedClass:seal()
	self.__sealed = true
end

--> Returns whether the class is sealed.
function AdvancedClass:isSealed()
	return self.__sealed == true
end

--> Marks the class as abstract.
--> Notes:Abstract classes cannot be instantiated directly.
function AdvancedClass:abstract()
	self.__abstract = true
end

--> Returns whether the class is abstract.
function AdvancedClass:isAbstract()
	return self.__abstract == true
end

--> Registers method names that must exist before instances can be created.
function AdvancedClass:requireMethods(methods)
	for _, methodName in ipairs(methods) do
		table.insert(self.__required, methodName)
	end
end

--> Registers an interface shape on the class.
function AdvancedClass:registerInterface(name: string, shape: { [string]: boolean })
	self.__ifaces[name] = shape
end

--> Declares that the class implements one or more registered interfaces.
function AdvancedClass:implements(interfaces: { string })
	for _, interfaceName in ipairs(interfaces) do
		self.__interfaces[interfaceName] = true
	end
end

--> Defines or replaces a managed property descriptor on the class.
function AdvancedClass:defineProperty(name: string, desc: PropertyDescriptor)
	assert(type(name) == 'string', 'property name must be a string')
	assert(type(desc) == 'table', 'property descriptor must be a table')
	removeComputedDependencies(self, name)
	local copied = copyDescriptor(desc)
	self.__props[name] = copied
	registerComputedDependencies(self, name, copied)
end

--> Registers a readonly computed property and its dependency list.
function AdvancedClass:defineComputed(name: string, dependsOn: { string }, compute: (self: any) -> any, cache: boolean?)
	self:defineProperty(name, {
		compute = compute,
		dependsOn = dependsOn,
		readonly = true,
		cache = cache ~= false,
	})
end

--> Removes a managed property descriptor and detaches dependency tracking entries.
function AdvancedClass:removeProperty(name: string)
	self.__props[name] = nil
	removeComputedDependencies(self, name)
end

--> Assigns a static value on the class.
function AdvancedClass:static(name: string, value: any)
	self.__static[name] = value
end

--> Reads a static value from the class.
function AdvancedClass:getStatic(name: string)
	return self.__static[name]
end

--> Creates a new instance of the class.
--[[
	Notes:
	    Runs abstract/interface checks, copies default properties, initializes
	    runtime state, then executes onInit, constructor, and postInit
]]

function AdvancedClass:new(...): any
	if self.__abstract then
		error(("Cannot instantiate abstract class '%s'"):format(self.className))
	end

	for _, methodName in ipairs(self.__required) do
		if type(self[methodName]) ~= 'function' then
			error(("Class '%s' is missing required method '%s'"):format(self.className, methodName))
		end
	end

	for _, interfaceName in ipairs(collectImplementedInterfaces(self)) do
		local shape = collectInterfaceShape(self, interfaceName)
		if not shape then
			error(("Class '%s' declares interface '%s' but no shape was registered"):format(self.className, interfaceName))
		end
		for methodName, required in pairs(shape) do
			if required and type(self[methodName]) ~= 'function' then
				error(("Class '%s' does not satisfy interface '%s': missing method '%s'"):format(self.className, interfaceName, methodName))
			end
		end
	end

	local instance = {}
	instance.class = self
	instance._destroyed = false
	instance._events = {}
	instance._connections = {}
	instance._observers = {}
	instance._values = {}
	instance._jobs = { intervals = {}, timers = {}, debounces = {}, throttles = {} }
	instance._children = {}
	instance._history = { past = {}, future = {}, limit = 64 }
	instance._tags = {}
	instance._computedCache = {}
	instance._computedDirty = {}
	instance._createdAt = now()
	instance._updatedAt = instance._createdAt
	local nextId = (self.__static.__nextId or 0) + 1
	instance._values.id = nextId
	self.__static.__nextId = nextId

	setmetatable(instance, {
		__index = instanceIndex,
		__newindex = propertyNewIndex,
	})

	for key, desc in pairs(self.__props or {}) do
		if desc.default ~= nil and getStoredValue(instance, key) == nil and not desc.get and not desc.compute then
			setStoredValue(instance, key, cloneDefault(desc.default))
		end
		if desc.compute and desc.cache ~= false then
			instance._computedDirty[key] = true
		end
	end

	if instance.onInit and type(instance.onInit) == 'function' then
		safeCall('onInit', instance.onInit, instance)
	end
	if instance.constructor and type(instance.constructor) == 'function' then
		instance:constructor(...)
	end
	if instance.postInit and type(instance.postInit) == 'function' then
		safeCall('postInit', instance.postInit, instance)
	end
	return instance
end

--> Creates a subclass that inherits behavior, descriptors, statics, and interfaces.
function AdvancedClass:extend(name: string?): Class<any>
	if self.__sealed then
		error(("Class '%s' is sealed and cannot be extended"):format(self.className))
	end

	local subclass = {} :: Class<any>
	subclass.__index = subclass
	subclass.className = name or (self.className .. 'Subclass')
	subclass.super = self
	subclass.__props = {}
	subclass.__sealed = false
	subclass.__abstract = false
	subclass.__required = shallowCopyArray(self.__required or {})
	subclass.__interfaces = {}
	subclass.__ifaces = setmetatable({}, { __index = self.__ifaces })
	subclass.__static = setmetatable({}, { __index = self.__static })
	subclass.__computedDeps = {}

	for key, value in pairs(self) do
		if not CLASS_METADATA_KEYS[key] then
			subclass[key] = value
		end
	end

	for key, value in pairs(self.__props or {}) do
		subclass.__props[key] = copyDescriptor(value)
	end
	for key, value in pairs(self.__interfaces or {}) do
		subclass.__interfaces[key] = value
	end
	for dep, dependents in pairs(self.__computedDeps or {}) do
		subclass.__computedDeps[dep] = shallowCopyArray(dependents)
	end

	subclass.new = self.new
	setmetatable(subclass, {
		__index = self,
		__call = function(cls, ...)
			return cls:new(...)
		end,
	})
	return subclass
end

--> Creates a subclass and applies property/static definitions in one step.
function AdvancedClass:extendWith(name: string?, spec: { props: { [string]: PropertyDescriptor }?, static: { [string]: any }? }): Class<any>
	local subclass = self:extend(name)
	if spec and spec.props then
		for key, desc in pairs(spec.props) do
			subclass:defineProperty(key, desc)
		end
	end
	if spec and spec.static then
		for key, value in pairs(spec.static) do
			subclass.__static[key] = value
		end
	end
	return subclass
end

--> Returns whether the instance belongs to a class or one of its ancestors.
function AdvancedClass:isA(class: Class<any>): boolean
	local current = self.class or getmetatable(self)
	while current do
		if current == class then
			return true
		end
		current = current.super
	end
	return false
end

--> Copies missing members from a mixin table onto the class.
function AdvancedClass:mixin(mixinTable: { [string]: any }): Class<any>
	for key, value in pairs(mixinTable) do
		if self[key] == nil then
			self[key] = value
		end
	end
	return self
end

--> Produces a shallow instance clone while rebuilding runtime-only containers.
function AdvancedClass:clone(): any
	local copy = { _values = shallowCopyMap(rawget(self, '_values')) }
	for key, value in pairs(self) do
		if key == 'class' then
			copy[key] = value
		elseif key ~= '_values' and not RUNTIME_CLONE_KEYS[key] then
			if isInternalInstanceKey(key) then
				copy[key] = value
			else
				copy._values[key] = value
			end
		end
	end
	copy._events = {}
	copy._observers = {}
	copy._connections = {}
	copy._jobs = { intervals = {}, timers = {}, debounces = {}, throttles = {} }
	copy._children = {}
	copy._history = { past = {}, future = {}, limit = self._history and self._history.limit or 64 }
	copy._tags = shallowCopyMap(rawget(self, '_tags'))
	copy._computedCache = deepCopy(self._computedCache or {})
	copy._computedDirty = deepCopy(self._computedDirty or {})
	copy._destroyed = false
	copy._createdAt = now()
	copy._updatedAt = copy._createdAt
	copy._values.id = ((self.class and self.class.__static.__nextId) or 0) + 1
	if self.class then
		self.class.__static.__nextId = copy._values.id
	end
	setmetatable(copy, getmetatable(self))
	return copy
end

-- --> Deep clone support
local function shouldSkipRuntimeCloneKey(obj: any, key: any): boolean
	return RUNTIME_CLONE_KEYS[key] == true and rawget(obj, 'class') ~= nil and rawget(obj, '_events') ~= nil
end

-- --> Deeply clones arbitrary table graphs while skipping runtime-only instance internals.
local function recursiveDeepClone(obj: any, seen: { [any]: any }): any
	if type(obj) ~= 'table' then
		return obj
	end
	if seen[obj] then
		return seen[obj]
	end
	local copy = {}
	seen[obj] = copy
	for key, value in pairs(obj) do
		if key == 'class' then
			copy[key] = value
		elseif not shouldSkipRuntimeCloneKey(obj, key) then
			copy[recursiveDeepClone(key, seen)] = recursiveDeepClone(value, seen)
		end
	end
	return copy
end

--> Produces a deep instance clone while skipping runtime-only containers.
function AdvancedClass:deepClone(): any
	local copy = recursiveDeepClone(self, {})
	copy._values = copy._values or {}
	for key, value in pairs(copy) do
		if key ~= '_values' and key ~= 'class' and not isInternalInstanceKey(key) and not RUNTIME_CLONE_KEYS[key] then
			copy._values[key] = value
			copy[key] = nil
		end
	end
	copy._events = {}
	copy._observers = {}
	copy._connections = {}
	copy._jobs = { intervals = {}, timers = {}, debounces = {}, throttles = {} }
	copy._children = {}
	copy._history = { past = {}, future = {}, limit = self._history and self._history.limit or 64 }
	copy._destroyed = false
	copy._createdAt = now()
	copy._updatedAt = copy._createdAt
	copy._values.id = ((self.class and self.class.__static.__nextId) or 0) + 1
	if self.class then
		self.class.__static.__nextId = copy._values.id
	end
	setmetatable(copy, getmetatable(self))
	return copy
end

--> Throws when the instance has already been destroyed. Notes: Use this as a defensive precondition in public instance methods.
function AdvancedClass:ensureNotDestroyed()
	if self._destroyed then
		error(("Instance '%s' is destroyed"):format(self:toString()))
	end
end

--> Freezes the instance table when table.freeze is available.
function AdvancedClass:freeze()
	if tableFreeze then
		tableFreeze(self)
	end
end

--> Destroys the instance and releases owned runtime resources.
function AdvancedClass:destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self.preDestroy and type(self.preDestroy) == 'function' then
		safeCall('preDestroy', self.preDestroy, self)
	end
	self:emit('destroying')
	self:destroyChildren()
	self:cancelAllJobs()
	if self.onDestroy and type(self.onDestroy) == 'function' then
		safeCall('onDestroy', self.onDestroy, self)
	end
	self:emit('destroyed')
	for _, conn in ipairs(shallowCopyArray(self._connections or {})) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	self._events = {}
	self._observers = {}
	self._connections = {}
end

--> Returns whether destroy() has already been executed.
function AdvancedClass:isDestroyed(): boolean
	return self._destroyed == true
end

--> Invokes the first matching method found in the superclass chain.
function AdvancedClass:superCall(methodName: string, ...): any
	local parent = self.class and self.class.super or nil
	while parent do
		if parent[methodName] then
			return parent[methodName](self, ...)
		end
		parent = parent.super
	end
	error("Method '" .. methodName .. "' not found in superclass chain")
end

--> Ensures that an event bucket exists on the instance.
function AdvancedClass:addEvent(eventName: string)
	self._events = self._events or {}
	self._events[eventName] = self._events[eventName] or {}
end

--> Registers a persistent event listener.
function AdvancedClass:on(eventName: string, callback: (...any) -> (), priority: number?): Connection
	self:ensureNotDestroyed()
	assert(type(callback) == 'function', 'event callback must be a function')
	self._events = self._events or {}
	local list = self._events[eventName]
	if not list then
		list = {}
		self._events[eventName] = list
	end
	if #list >= MAX_LISTENERS_PER_EVENT then
		error(("Event '%s' exceeded the listener limit (%d)"):format(eventName, MAX_LISTENERS_PER_EVENT))
	end
	local listener = { cb = callback, once = false, priority = priority or 0 }
	insertListenerByPriority(list, listener)
	local conn = makeConnection(self, eventName, listener)
	table.insert(self._connections, conn)
	return conn
end

--> Removes matching listeners for an event callback.
function AdvancedClass:off(eventName: string, callback: (...any) -> ())
	local list = self._events and self._events[eventName]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		local listener = list[i]
		if listener.cb == callback then
			if listener.connection and listener.connection.Connected then
				listener.connection.Connected = false
				removeArrayValue(self._connections, listener.connection)
			end
			table.remove(list, i)
		end
	end
end

--> Removes all listeners for one event or for every event.
function AdvancedClass:offAll(eventName: string?)
	if not self._events then
		return
	end
	if eventName then
		local list = self._events[eventName]
		if not list then
			return
		end
		for _, listener in ipairs(list) do
			if listener.connection then
				listener.connection.Connected = false
				removeArrayValue(self._connections, listener.connection)
			end
		end
		self._events[eventName] = {}
		return
	end
	for name, list in pairs(self._events) do
		for _, listener in ipairs(list) do
			if listener.connection then
				listener.connection.Connected = false
				removeArrayValue(self._connections, listener.connection)
			end
		end
		self._events[name] = {}
	end
end

--> Emits an event immediately to the current listener snapshot.
function AdvancedClass:emit(eventName: string, ...: any)
	local list = self._events and self._events[eventName]
	if not list or #list == 0 then
		return
	end
	local args = table.pack(...)
	local snapshot = shallowCopyArray(list)
	for _, listener in ipairs(snapshot) do
		if listener.connection and listener.connection.Connected then
			if listener.once then
				listener.connection:Disconnect()
			end
			safeCall('event:' .. eventName, listener.cb, self, table.unpack(args, 1, args.n))
		end
	end
end

--> Emits an event on a deferred task.
function AdvancedClass:emitAsync(eventName: string, ...: any)
	local args = table.pack(...)
	self:defer(function()
		self:emit(eventName, table.unpack(args, 1, args.n))
	end)
end

--> Registers a listener that disconnects itself after the first invocation.
function AdvancedClass:once(eventName: string, callback: (...any) -> (), priority: number?): Connection
	self:ensureNotDestroyed()
	assert(type(callback) == 'function', 'event callback must be a function')
	self._events = self._events or {}
	local list = self._events[eventName]
	if not list then
		list = {}
		self._events[eventName] = list
	end
	if #list >= MAX_LISTENERS_PER_EVENT then
		error(("Event '%s' exceeded the listener limit (%d)"):format(eventName, MAX_LISTENERS_PER_EVENT))
	end
	local listener = { cb = callback, once = true, priority = priority or 0 }
	insertListenerByPriority(list, listener)
	local conn = makeConnection(self, eventName, listener)
	table.insert(self._connections, conn)
	return conn
end

--> Waits for a single event occurrence with an explicit timeout callback.
function AdvancedClass:onceWithTimeout(eventName: string, timeout: number, callback: (self: any, timedOut: boolean, ...any) -> ())
	local resolved = false
	local conn: Connection? = nil
	conn = self:once(eventName, function(instance, ...)
		if resolved then
			return
		end
		resolved = true
		if conn and conn.Connected then
			conn:Disconnect()
		end
		callback(instance, false, ...)
	end)
	self:delay(timeout, function()
		if resolved then
			return
		end
		resolved = true
		if conn and conn.Connected then
			conn:Disconnect()
		end
		callback(self, true)
	end)
end

--> Suspends the current coroutine until the event fires once.
function AdvancedClass:waitFor(eventName: string): (...any)
	local co = coroutine.running()
	if not co then
		error('waitFor must be called within a coroutine')
	end
	local result = nil
	local conn: Connection? = nil
	conn = self:on(eventName, function(_, ...)
		result = table.pack(...)
		if conn and conn.Connected then
			conn:Disconnect()
		end
		task.spawn(co)
	end, 0)
	coroutine.yield()
	return table.unpack(result or {}, 1, result and result.n or 0)
end

--> Suspends the current coroutine until the event fires or times out.
function AdvancedClass:waitForWithTimeout(eventName: string, timeout: number): (boolean, ...any)
	local co = coroutine.running()
	if not co then
		error('waitForWithTimeout must be called within a coroutine')
	end
	local result = nil
	local fired = false
	local conn: Connection? = nil
	conn = self:on(eventName, function(_, ...)
		if fired then
			return
		end
		fired = true
		result = table.pack(...)
		if conn and conn.Connected then
			conn:Disconnect()
		end
		task.spawn(co, true)
	end, 0)
	self:delay(timeout, function()
		if fired then
			return
		end
		fired = true
		if conn and conn.Connected then
			conn:Disconnect()
		end
		task.spawn(co, false)
	end)
	local ok = coroutine.yield()
	if ok then
		return true, table.unpack(result or {}, 1, result and result.n or 0)
	end
	return false
end

--> Suspends the current coroutine until any listed event fires.
function AdvancedClass:waitForAny(events: { string }): (string, ...any)
	assert(type(events) == 'table' and #events > 0, 'waitForAny expects at least one event')
	local co = coroutine.running()
	if not co then
		error('waitForAny must be called within a coroutine')
	end
	local done = false
	local payload = nil
	local conns = {}
	local function finish(eventName: string, ...)
		if done then
			return
		end
		done = true
		payload = table.pack(eventName, ...)
		for _, conn in ipairs(conns) do
			if conn.Connected then
				conn:Disconnect()
			end
		end
		task.spawn(co)
	end
	for _, eventName in ipairs(events) do
		table.insert(conns, self:on(eventName, function(_, ...)
			finish(eventName, ...)
		end))
	end
	coroutine.yield()
	return table.unpack(payload or {}, 1, payload and payload.n or 0)
end

-- --> Property observation and binding --> Registers a property observer callback.
function AdvancedClass:bindProperty(propertyName: string, callback: (newValue: any, oldValue: any) -> ())
	assert(type(callback) == 'function', 'property callback must be a function')
	self._observers = self._observers or {}
	self._observers[propertyName] = self._observers[propertyName] or {}
	table.insert(self._observers[propertyName], callback)
end

--> Removes a previously registered property observer.
function AdvancedClass:unbindProperty(propertyName: string, callback: (newValue: any, oldValue: any) -> ())
	local list = self._observers and self._observers[propertyName]
	if not list then
		return
	end
	for i = #list, 1, -1 do
		if list[i] == callback then
			table.remove(list, i)
			break
		end
	end
end

--> Observes multiple properties through a shared callback.
function AdvancedClass:watch(props: { string }, callback: (prop: string, newValue: any, oldValue: any) -> ())
	local unbinders = {}
	for _, propertyName in ipairs(props) do
		local fn = function(newValue, oldValue)
			callback(propertyName, newValue, oldValue)
		end
		self:bindProperty(propertyName, fn)
		table.insert(unbinders, function()
			self:unbindProperty(propertyName, fn)
		end)
	end
	return function()
		for _, unbind in ipairs(unbinders) do
			unbind()
		end
	end
end

--> Observes every property change emitted through the changed event.
function AdvancedClass:watchAll(predicate, callback)
	local conn = self:on('changed', function(_, prop, newValue, oldValue)
		if not predicate or predicate(prop, newValue, oldValue) then
			callback(prop, newValue, oldValue)
		end
	end)
	return function()
		if conn.Connected then
			conn:Disconnect()
		end
	end
end

--> Mirrors a source property into a target property.
function AdvancedClass:bindTo(target: any, targetProp: string, sourceProp: string?): () -> ()
	sourceProp = sourceProp or targetProp
	local fn = function(newValue)
		target[targetProp] = newValue
	end
	self:bindProperty(sourceProp, fn)
	local ok, currentValue = pcall(function()
		return self[sourceProp]
	end)
	if ok and currentValue ~= nil then
		target[targetProp] = currentValue
	end
	return function()
		self:unbindProperty(sourceProp, fn)
	end
end

--> Creates a guarded two-way property synchronization link.
function AdvancedClass:linkTwoWay(other: any, propA: string, propB: string): () -> ()
	local syncing = false
	local fnA = function(newValue)
		if syncing then
			return
		end
		syncing = true
		local ok, err = pcall(function()
			other[propB] = newValue
		end)
		syncing = false
		if not ok then
			error(err)
		end
	end
	local fnB = function(newValue)
		if syncing then
			return
		end
		syncing = true
		local ok, err = pcall(function()
			self[propA] = newValue
		end)
		syncing = false
		if not ok then
			error(err)
		end
	end
	self:bindProperty(propA, fnA)
	if other.bindProperty then
		other:bindProperty(propB, fnB)
	end
	local ok, currentValue = pcall(function()
		return self[propA]
	end)
	if ok and currentValue ~= nil then
		other[propB] = currentValue
	end
	return function()
		self:unbindProperty(propA, fnA)
		if other.unbindProperty then
			other:unbindProperty(propB, fnB)
		end
	end
end

-- --> Scheduled work and rate control	--> Schedules a callback on the next deferred task step.
function AdvancedClass:defer(callback: () -> ())
	assert(type(callback) == 'function', 'defer callback must be a function')
	local bucket = self._jobs.timers
	local handle = createJobHandle(bucket)
	task.defer(function()
		if handle.cancelled or self._destroyed then
			finalizeJobHandle(bucket, handle)
			return
		end
		safeCall('defer', callback)
		finalizeJobHandle(bucket, handle)
	end)
	return handle
end

--> Schedules a callback after a delay
function AdvancedClass:delay(timeSeconds: number, callback: () -> ())
	assert(type(callback) == 'function', 'delay callback must be a function')
	local bucket = self._jobs.timers
	local handle = createJobHandle(bucket)
	task.delay(math.max(timeSeconds, 0), function()
		if handle.cancelled or self._destroyed then
			finalizeJobHandle(bucket, handle)
			return
		end
		safeCall('delay', callback)
		finalizeJobHandle(bucket, handle)
	end)
	return handle
end

--> Repeats a callback on a fixed interval until cancelled or destroyed.
function AdvancedClass:interval(timeSeconds: number, callback: () -> ())
	assert(type(callback) == 'function', 'interval callback must be a function')
	local bucket = self._jobs.intervals
	local handle = createJobHandle(bucket)
	local waitSeconds = math.max(timeSeconds, 0)
	task.spawn(function()
		while not handle.cancelled and not self._destroyed do
			task.wait(waitSeconds)
			if handle.cancelled or self._destroyed then
				break
			end
			safeCall('interval', callback)
		end
		finalizeJobHandle(bucket, handle)
	end)
	return handle
end

--> Creates a debounced wrapper around a callback.
function AdvancedClass:debounce(fn: (...any) -> (), ms: number)
	assert(type(fn) == 'function', 'debounce callback must be a function')
	local bucket = self._jobs.debounces
	local state = createJobHandle(bucket)
	local timer = nil
	local waitSeconds = math.max(ms, 0) / 1000
	return function(...)
		if state.cancelled or self._destroyed then
			return
		end
		local args = table.pack(...)
		if timer then
			timer.cancelled = true
		end
		timer = { cancelled = false }
		local token = timer
		task.delay(waitSeconds, function()
			if state.cancelled or self._destroyed or token.cancelled then
				return
			end
			safeCall('debounce', fn, table.unpack(args, 1, args.n))
		end)
	end
end

--> Creates a throttled wrapper around a callback
function AdvancedClass:throttle(fn: (...any) -> (), ms: number)
	assert(type(fn) == 'function', 'throttle callback must be a function')
	local bucket = self._jobs.throttles
	local state = createJobHandle(bucket)
	local open = true
	local queuedArgs = nil
	local waitSeconds = math.max(ms, 0) / 1000
	local release: () -> ()
	release = function()
		task.delay(waitSeconds, function()
			if state.cancelled or self._destroyed then
				return
			end
			if queuedArgs then
				local nextArgs = queuedArgs
				queuedArgs = nil
				safeCall('throttle:queued', fn, table.unpack(nextArgs, 1, nextArgs.n))
				release()
				return
			end
			open = true
		end)
	end
	return function(...)
		if state.cancelled or self._destroyed then
			return
		end
		local args = table.pack(...)
		if open then
			open = false
			safeCall('throttle', fn, table.unpack(args, 1, args.n))
			release()
		else
			queuedArgs = args
		end
	end
end

--> Cancels every tracked timer, interval, debounce, and throttle job.
function AdvancedClass:cancelAllJobs()
	for _, bucket in pairs(self._jobs) do
		for i = #bucket, 1, -1 do
			local handle = bucket[i]
			if handle and handle.cancel then
				handle.cancel()
			elseif handle then
				handle.cancelled = true
			end
		end
		clearTable(bucket)
	end
end

-- --> Parent / child ownership
--> Adds a child object to this instance ownership tree.
function AdvancedClass:addChild(child: any)
	self:ensureNotDestroyed()
	assert(type(child) == 'table', 'child must be a table-like object')
	assert(child ~= self, 'cannot add self as a child')
	for _, existing in ipairs(self._children) do
		if existing == child then
			return
		end
	end
	local cursor = self
	while cursor do
		if cursor == child then
			error('cannot create cyclic parent/child relationships')
		end
		cursor = cursor.parent
	end
	if child.parent and child.parent ~= self and child.parent.removeChild then
		child.parent:removeChild(child)
	end
	table.insert(self._children, child)
	child.parent = self
	self:emit('childAdded', child)
end

--> Removes a child object from the instance ownership tree.
function AdvancedClass:removeChild(child: any)
	for i = #self._children, 1, -1 do
		if self._children[i] == child then
			table.remove(self._children, i)
			child.parent = nil
			self:emit('childRemoved', child)
			break
		end
	end
end

--> Returns a shallow copy of the current child list.
function AdvancedClass:getChildren(): { any }
	return shallowCopyArray(self._children)
end

--> Destroys every owned child that exposes a destroy() method.
function AdvancedClass:destroyChildren()
	for i = #self._children, 1, -1 do
		local child = self._children[i]
		if child and child.destroy then
			child:destroy()
		end
		self._children[i] = nil
	end
end

-- --> Logging, tagging, and persistence
local LOG_LEVELS = { trace = 1, debug = 2, info = 3, warn = 4, error = 5 }

--> Assigns a custom logger callback for instance log output.
function AdvancedClass:setLogger(logger)
	assert(logger == nil or type(logger) == 'function', 'logger must be a function or nil')
	self._logger = logger
end

--> Sets the minimum log severity emitted by the instance.
function AdvancedClass:setLogLevel(level: string)
	self._logLevel = LOG_LEVELS[level] or 3
end

--> Returns a review-friendly instance label.
function AdvancedClass:toString(): string
	local classObj = rawget(self, 'class')
	local name = classObj and classObj.className or self.className or 'Instance'
	local id = getStoredValue(self, 'id')
	if id ~= nil then
		return name .. ' #' .. tostring(id)
	end
	return name
end

--> Emits a formatted log message through the custom logger or default output.
function AdvancedClass:log(level: string, message: string)
	local currentLevel = self._logLevel or 3
	local requestedLevel = LOG_LEVELS[level] or 3
	if requestedLevel < currentLevel then
		return
	end
	local formatted = '[' .. string.upper(level) .. '] ' .. self:toString() .. ': ' .. message
	if self._logger then
		safeCall('logger', self._logger, level, formatted)
		return
	end
	if level == 'error' or level == 'warn' then
		warn(formatted)
	else
		print(formatted)
	end
end

--> Formats and emits a log message.
function AdvancedClass:logf(level: string, fmt: string, ...: any)
	self:log(level, string.format(fmt, ...))
end

--> Adds a lightweight tag to the instance.
function AdvancedClass:addTag(tag: string)
	self._tags[tag] = true
end

--> Returns whether the instance currently has the given tag.
function AdvancedClass:hasTag(tag: string)
	return self._tags[tag] == true
end

--> Removes a lightweight tag from the instance.
function AdvancedClass:removeTag(tag: string)
	self._tags[tag] = nil
end

--> Serializes the instance into a safe external snapshot.
function AdvancedClass:serialize(): { [string]: any }
	return collectSerializableSnapshot(self)
end

--> Applies serialized state back onto the instance.
function AdvancedClass:deserialize(data: { [string]: any })
	assert(type(data) == 'table', 'deserialize expects a table')
	for key, value in pairs(data) do
		if isDeserializableKey(self, key) then
			propertyNewIndex(self, key, deepCopy(value))
		end
	end
	self._updatedAt = now()
end

--> Serializes the instance and encodes the result as JSON.
function AdvancedClass:toJSON(): string
	return jsonEncode(self:serialize())
end

--> Decodes JSON and applies the resulting serializable state to the instance.
function AdvancedClass:fromJSON(json: string)
	local ok, decoded = pcall(jsonDecode, json)
	if not ok then
		error('Invalid JSON payload for fromJSON')
	end
	self:deserialize(decoded)
end

--> Returns the current serializable state snapshot.
function AdvancedClass:snapshot(): { [string]: any }
	return self:serialize()
end

--> Compares the instance snapshot against another instance or plain table.
function AdvancedClass:diff(other: any): { [string]: { old: any, new: any } }
	local current = self:serialize()
	local target = type(other) == 'table' and ((other.serialize and other:serialize()) or other) or {}
	local out = {}
	local seen = {}
	for key, value in pairs(current) do
		seen[key] = true
		if not deepEqual(value, target[key]) then
			out[key] = { old = value, new = target[key] }
		end
	end
	for key, value in pairs(target) do
		if not seen[key] then
			out[key] = { old = current[key], new = value }
		end
	end
	return out
end

--> Pushes the current snapshot into history and clears redo state.
function AdvancedClass:commit()
	table.insert(self._history.past, self:snapshot())
	self._history.future = {}
	if #self._history.past > self._history.limit then
		table.remove(self._history.past, 1)
	end
end
--> Restores the most recent committed snapshot.
function AdvancedClass:undo(): boolean
	local past = self._history.past
	if #past == 0 then
		return false
	end
	local snapshot = table.remove(past)
	table.insert(self._history.future, self:snapshot())
	applySnapshot(self, snapshot)
	return true
end

--> Reapplies the most recently undone snapshot.
function AdvancedClass:redo(): boolean
	local future = self._history.future
	if #future == 0 then
		return false
	end
	local snapshot = table.remove(future)
	table.insert(self._history.past, self:snapshot())
	applySnapshot(self, snapshot)
	return true
end

--> Clears both undo and redo history buffers.
function AdvancedClass:clearHistory()
	self._history.past = {}
	self._history.future = {}
end

setmetatable(AdvancedClass, {
	__call = function(classObj, ...)
		return classObj:new(...)
	end,
})

return AdvancedClass
