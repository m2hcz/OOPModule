--[[
  AdvancedClassModule++
  ---------------------
  Advanced OOP utilities for Luau:
  - Inheritance, mixins, super calls
  - Events (priorities, Connection handles, once/timeout, async emit)
  - Property system (get/set/readonly/default/lazy/computed)
  - Property observers + "changed" events
  - Binding (1-way and 2-way), watch/watchAll
  - Scheduling (defer/delay/interval, debounce/throttle, cancelAllJobs)
  - Lifecycle hooks (onInit/postInit/preDestroy/onDestroy)
  - Children tree (add/remove/destroy, bubbling for some events)
  - Logging with levels + custom logger, timers
  - Snapshots/diff/undo/redo
  - Serialization/JSON
  - Abstract/sealed classes, interfaces, plugins
  - Freeze instances/classes

  Developed by m2hcz.
--]]

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

	-- Mixins & plugins
	mixin: (self: Class<T>, mixinTable: { [string]: any }) -> Class<T>,
	use: (self: Class<T>, plugin: (Class<any>) -> ()) -> Class<T>,

	-- OOP constraints
	seal: (self: Class<T>) -> (),
	isSealed: (self: Class<T>) -> boolean,
	abstract: (self: Class<T>) -> (),
	isAbstract: (self: Class<T>) -> boolean,
	requireMethods: (self: Class<T>, methods: { string }) -> (),
	implements: (self: Class<T>, interfaces: { string }) -> (),
	registerInterface: (self: Class<T>, name: string, shape: { [string]: boolean }) -> (),

	-- Properties
	defineProperty: (self: Class<T>, name: string, desc: PropertyDescriptor) -> (),
	defineComputed: (self: Class<T>, name: string, dependsOn: { string }, compute: (self: T) -> any) -> (),
	removeProperty: (self: Class<T>, name: string) -> (),

	-- Clone/Destroy
	clone: (self: T) -> T,
	deepClone: (self: T) -> T,
	destroy: (self: T) -> (),
	isDestroyed: (self: T) -> boolean,
	ensureNotDestroyed: (self: T) -> (),
	freeze: (self: T) -> (),

	-- Super
	superCall: (self: T, methodName: string, ...any) -> any,

	-- Events
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

	-- Property observers / bindings
	bindProperty: (self: T, propertyName: string, callback: (newValue: any, oldValue: any) -> ()) -> (),
	unbindProperty: (self: T, propertyName: string, callback: (newValue: any, oldValue: any) -> ()) -> (),
	watch: (self: T, props: { string }, callback: (prop: string, newValue: any, oldValue: any) -> ()) -> ()->(),
	watchAll: (self: T, predicate: ((prop: string, newValue: any, oldValue: any) -> boolean)?, callback: (prop: string, newValue: any, oldValue: any) -> ()) -> ()->(),
	bindTo: (self: T, target: any, targetProp: string, sourceProp: string?) -> ()->(),
	linkTwoWay: (self: T, other: any, propA: string, propB: string) -> ()->(),

	-- Scheduling
	defer: (self: T, callback: () -> ()) -> (),
	delay: (self: T, time: number, callback: () -> ()) -> (),
	interval: (self: T, time: number, callback: () -> ()) -> { cancel: () -> () },
	debounce: (self: T, fn: (...any) -> (), ms: number) -> (...any) -> (),
	throttle: (self: T, fn: (...any) -> (), ms: number) -> (...any) -> (),
	cancelAllJobs: (self: T) -> (),

	-- Children tree
	addChild: (self: T, child: any) -> (),
	removeChild: (self: T, child: any) -> (),
	getChildren: (self: T) -> { any },
	destroyChildren: (self: T) -> (),

	-- Identity & tags
	toString: (self: T) -> string,
	log: (self: T, level: string, message: string) -> (),
	logf: (self: T, level: string, fmt: string, ...any) -> (),
	setLogger: (self: T, logger: ((level: string, msg: string) -> ())?) -> (),
	setLogLevel: (self: T, level: string) -> (),
	addTag: (self: T, tag: string) -> (),
	hasTag: (self: T, tag: string) -> boolean,
	removeTag: (self: T, tag: string) -> (),

	-- Serialization/state
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

-- Utilities
local function now(): number
	local ok, t = pcall(function() return os.time() end)
	return ok and t or 0
end

local function safePcall(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then warn("[AdvancedClass] Listener error: ", err) end
end

local HttpService
pcall(function() HttpService = game:GetService("HttpService") end)

local function jsonEncode(tbl)
	if HttpService then
		return HttpService:JSONEncode(tbl)
	else
		return tostring(tbl) -- fallback
	end
end

local function jsonDecode(str)
	if HttpService then
		return HttpService:JSONDecode(str)
	else
		error("JSON decode unavailable without HttpService")
	end
end

local tableFreeze = table and table.freeze or function(t) return t end

-- ID generator
local _idCounter = 0
local function nextId()
	_idCounter = _idCounter + 1
	return _idCounter
end

-- Event connections
local function makeConnection(store, eventName, listener)
	local conn = { Connected = true }
	function conn:Disconnect()
		if not self.Connected then return end
		self.Connected = false
		local list = store[eventName]
		if not list then return end
		for i, item in ipairs(list) do
			if item == listener then
				table.remove(list, i)
				break
			end
		end
	end
	return conn
end

-- Internal notify for property observers + "changed" events
local function notifyChange(self, key, newValue, oldValue)
	if self._observers and self._observers[key] then
		for _, callback in ipairs(self._observers[key]) do
			safePcall(callback, newValue, oldValue)
		end
	end
	-- fire "changed" and "changed:<key>"
	if self.emit then
		self:emit("changed", key, newValue, oldValue)
		self:emit("changed:" .. tostring(key), newValue, oldValue)
	end
end

-- Property map-based __index/__newindex
local function instanceIndex(tbl: any, key: any)
	local class = rawget(tbl, "class")
	local props = class and rawget(class, "__props")
	if props then
		local desc = props[key]
		if desc then
			if desc.get then
				return desc.get(tbl)
			end
			if desc.compute then
				return desc.compute(tbl)
			end
			if rawget(tbl, key) ~= nil then
				return rawget(tbl, key)
			end
			if desc.lazy then
				local v = desc.lazy(tbl)
				rawset(tbl, key, v)
				notifyChange(tbl, key, v, nil)
				return v
			end
		end
	end
	local v = nil
	local cls = class
	if cls ~= nil then
		v = cls[key]
		if v ~= nil then return v end
	end
	return rawget(tbl, key)
end

local function propertyNewIndex(tbl: any, key: any, value: any)
	local class = rawget(tbl, "class")
	local props = class and rawget(class, "__props")
	local desc = props and props[key] or nil
	local oldValue = rawget(tbl, key)
	if desc then
		if desc.readonly then
			error(("Property '%s' is readonly"):format(tostring(key)))
		end
		if desc.set then
			safePcall(desc.set, tbl, value)
			local newValue = rawget(tbl, key)
			tbl._updatedAt = now()
			notifyChange(tbl, key, newValue, oldValue)
			return
		end
	end
	rawset(tbl, key, value)
	tbl._updatedAt = now()
	notifyChange(tbl, key, value, oldValue)
end

-- Base Class
local AdvancedClass = {} :: Class<any>
AdvancedClass.__index = AdvancedClass
AdvancedClass.className = "AdvancedClass"
AdvancedClass.super = nil
AdvancedClass.__props = {}         -- class-level property descriptors
AdvancedClass.__sealed = false
AdvancedClass.__abstract = false
AdvancedClass.__required = {}      -- list of required method names
AdvancedClass.__interfaces = {}    -- set of strings
AdvancedClass.__ifaces = {}        -- registry of interface shapes
AdvancedClass.__static = {}        -- static bag

-- Plugins
function AdvancedClass:use(plugin)
	plugin(self)
	return self
end

-- Class constraints
function AdvancedClass:seal() self.__sealed = true end
function AdvancedClass:isSealed() return self.__sealed == true end
function AdvancedClass:abstract() self.__abstract = true end
function AdvancedClass:isAbstract() return self.__abstract == true end
function AdvancedClass:requireMethods(methods)
	for _, m in ipairs(methods) do table.insert(self.__required, m) end
end
function AdvancedClass:registerInterface(name: string, shape: { [string]: boolean })
	self.__ifaces[name] = shape
end
function AdvancedClass:implements(interfaces: { string })
	for _, n in ipairs(interfaces) do
		self.__interfaces[n] = true
	end
end

-- Properties
function AdvancedClass:defineProperty(name: string, desc: PropertyDescriptor)
	self.__props[name] = desc
end

function AdvancedClass:defineComputed(name: string, dependsOn: { string }, compute: (self: any) -> any)
	self.__props[name] = { compute = compute, dependsOn = dependsOn, readonly = true }
end

function AdvancedClass:removeProperty(name: string)
	self.__props[name] = nil
end

-- Static bag
function AdvancedClass:static(name: string, value: any)
	self.__static[name] = value
end
function AdvancedClass:getStatic(name: string)
	return self.__static[name]
end

-- new
function AdvancedClass:new(...): any
	if self.__abstract then
		error(("Cannot instantiate abstract class '%s'"):format(self.className))
	end
	-- check required methods implemented (including overrides)
	for _, m in ipairs(self.__required) do
		if type(self[m]) ~= "function" then
			error(("Class '%s' is missing required method '%s'"):format(self.className, m))
		end
	end

	local instance = {}
	instance.class = self
	instance._destroyed = false
	instance._events = {}           -- eventName -> {listeners}
	instance._connections = {}      -- active Connection handles for cleanup
	instance._observers = {}        -- property observers
	instance._jobs = { intervals = {}, timers = {}, debounces = {}, throttles = {} }
	instance._children = {}
	instance._history = { past = {}, future = {}, limit = 64 }
	instance._tags = {}
	instance.id = nextId()
	instance._createdAt = now()
	instance._updatedAt = instance._createdAt

	setmetatable(instance, {
		__index = instanceIndex,
		__newindex = propertyNewIndex,
	})

	-- Defaults for properties with "default"
	if self.__props then
		for key, desc in pairs(self.__props) do
			if desc.default ~= nil and rawget(instance, key) == nil and not desc.get and not desc.compute then
				rawset(instance, key, typeof and typeof(desc.default) == "function" and desc.default() or desc.default)
			end
		end
	end

	if instance.onInit and type(instance.onInit) == "function" then
		safePcall(instance.onInit, instance)
	end
	if instance.constructor and type(instance.constructor) == "function" then
		instance:constructor(...)
	end
	if instance.postInit and type(instance.postInit) == "function" then
		safePcall(instance.postInit, instance)
	end
	return instance
end

-- extend
function AdvancedClass:extend(name: string?): Class<any>
	if self.__sealed then
		error(("Class '%s' is sealed and cannot be extended"):format(self.className))
	end
	local subclass = {} :: Class<any>
	subclass.__index = subclass
	subclass.className = name or (self.className .. "Subclass")
	subclass.super = self
	subclass.__props = {}
	subclass.__sealed = false
	subclass.__abstract = false
	subclass.__required = {}
	subclass.__interfaces = {}
	subclass.__ifaces = setmetatable({}, { __index = self.__ifaces }) -- inherit registry
	subclass.__static = setmetatable({}, { __index = self.__static })

	-- inherit methods/fields except "new"
	for k, v in pairs(self) do
		if k ~= "new" then
			subclass[k] = v
		end
	end
	-- inherit props (shallow copy)
	for k, v in pairs(self.__props or {}) do
		subclass.__props[k] = v
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

function AdvancedClass:extendWith(name: string?, spec: { props: { [string]: PropertyDescriptor }?, static: { [string]: any }? }): Class<any>
	local sub = self:extend(name)
	if spec and spec.props then
		for k, d in pairs(spec.props) do sub.__props[k] = d end
	end
	if spec and spec.static then
		for k, v in pairs(spec.static) do sub.__static[k] = v end
	end
	return sub
end

-- isA
function AdvancedClass:isA(class: Class<any>): boolean
	local current = self.class or getmetatable(self)
	while current do
		if current == class then return true end
		current = current.super
	end
	return false
end

-- mixin
function AdvancedClass:mixin(mixinTable: { [string]: any }): Class<any>
	for key, value in pairs(mixinTable) do
		if self[key] == nil then
			self[key] = value
		end
	end
	return self
end

-- Clone
function AdvancedClass:clone(): any
	local copy = {}
	for k, v in pairs(self) do
		if k ~= "_events" and k ~= "_observers" and k ~= "_connections" and k ~= "_jobs" and k ~= "_children" then
			copy[k] = v
		end
	end
	copy._events, copy._observers, copy._connections = {}, {}, {}
	copy._jobs = { intervals = {}, timers = {}, debounces = {}, throttles = {} }
	copy._children = {}
	setmetatable(copy, getmetatable(self))
	return copy
end

local function recursiveDeepClone(obj: any, seen: { [any]: any }): any
	if type(obj) ~= "table" then return obj end
	if seen[obj] then return seen[obj] end
	local copy = {}
	seen[obj] = copy
	for k, v in pairs(obj) do
		if k ~= "_events" and k ~= "_observers" and k ~= "_connections" and k ~= "_jobs" and k ~= "_children" then
			copy[recursiveDeepClone(k, seen)] = recursiveDeepClone(v, seen)
		end
	end
	return copy
end

function AdvancedClass:deepClone(): any
	local copy = recursiveDeepClone(self, {})
	copy._events, copy._observers, copy._connections = {}, {}, {}
	copy._jobs = { intervals = {}, timers = {}, debounces = {}, throttles = {} }
	copy._children = {}
	setmetatable(copy, getmetatable(self))
	return copy
end

-- ensure / freeze
function AdvancedClass:ensureNotDestroyed()
	if self._destroyed then error(("Instance '%s' is destroyed"):format(self:toString())) end
end

function AdvancedClass:freeze()
	if tableFreeze then tableFreeze(self) end
end

-- destroy
function AdvancedClass:destroy(): ()
	if self._destroyed then return end
	self._destroyed = true
	if self.preDestroy and type(self.preDestroy) == "function" then
		safePcall(self.preDestroy, self)
	end

	-- bubble destroying to children
	self:destroyChildren()

	-- cancel jobs
	self:cancelAllJobs()

	-- disconnect connections
	for _, conn in ipairs(self._connections or {}) do
		if conn and conn.Connected then conn:Disconnect() end
	end

	-- fire events then clear
	self:emit("destroying")
	if self.onDestroy and type(self.onDestroy) == "function" then
		safePcall(self.onDestroy, self)
	end
	self:emit("destroyed")

	self._events = {}
	self._observers = {}
	self._connections = {}
end

function AdvancedClass:isDestroyed(): boolean
	return self._destroyed
end

-- superCall
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

-- Events
function AdvancedClass:addEvent(eventName: string): ()
	if not self._events then self._events = {} end
	self._events[eventName] = self._events[eventName] or {}
end

local function sortByPriority(listeners)
	table.sort(listeners, function(a, b) return (a.priority or 0) > (b.priority or 0) end)
end

function AdvancedClass:on(eventName: string, callback: (...any) -> (), priority: number?): Connection
	if not self._events then self._events = {} end
	local list = self._events[eventName]
	if not list then
		list = {}
		self._events[eventName] = list
	end
	local listener = { cb = callback, once = false, priority = priority or 0 }
	table.insert(list, listener)
	sortByPriority(list)
	local conn = makeConnection(self._events, eventName, listener)
	table.insert(self._connections, conn)
	return conn
end

function AdvancedClass:off(eventName: string, callback: (...any) -> ()): ()
	if self._events and self._events[eventName] then
		local list = self._events[eventName]
		for i = #list, 1, -1 do
			if list[i].cb == callback then
				table.remove(list, i)
			end
		end
	end
end

function AdvancedClass:offAll(eventName: string?): ()
	if not self._events then return end
	if eventName then
		self._events[eventName] = {}
	else
		for k in pairs(self._events) do self._events[k] = {} end
	end
end

function AdvancedClass:emit(eventName: string, ...: any): ()
	if self._events and self._events[eventName] then
		local snapshot = table.clone and table.clone(self._events[eventName]) or { table.unpack(self._events[eventName]) }
		for _, listener in ipairs(snapshot) do
			if listener.once then
				self:off(eventName, listener.cb)
			end
			safePcall(listener.cb, self, ...)
		end
	end
end

function AdvancedClass:emitAsync(eventName: string, ...: any): ()
	local args = table.pack(...)
	self:defer(function()
		self:emit(eventName, table.unpack(args, 1, args.n))
	end)
end

function AdvancedClass:once(eventName: string, callback: (...any) -> (), priority: number?): Connection
	if not self._events then self._events = {} end
	local list = self._events[eventName] or {}
	self._events[eventName] = list
	local listener = { cb = callback, once = true, priority = priority or 0 }
	table.insert(list, listener)
	sortByPriority(list)
	local conn = makeConnection(self._events, eventName, listener)
	table.insert(self._connections, conn)
	return conn
end

function AdvancedClass:onceWithTimeout(eventName: string, timeout: number, callback: (self: any, timedOut: boolean, ...any) -> ()): ()
	local timedOut = false
	local conn: Connection? = nil
	conn = self:once(eventName, function(self, ...)
		if not timedOut then
			timedOut = true
			if conn and conn.Connected then conn:Disconnect() end
			callback(self, false, ...)
		end
	end)
	self:delay(timeout, function()
		if not timedOut then
			timedOut = true
			if conn and conn.Connected then conn:Disconnect() end
			callback(self, true)
		end
	end)
end

function AdvancedClass:waitFor(eventName: string): (...any)
	local co = coroutine.running()
	if not co then error("waitFor must be called within a coroutine") end
	local result
	local conn
	conn = self:on(eventName, function(self, ...)
		result = { ... }
		if conn and conn.Connected then conn:Disconnect() end
		coroutine.resume(co)
	end, 0)
	coroutine.yield()
	return table.unpack(result or {})
end

function AdvancedClass:waitForWithTimeout(eventName: string, timeout: number): (boolean, ...any)
	local co = coroutine.running()
	if not co then error("waitForWithTimeout must be called within a coroutine") end
	local result
	local fired = false
	local conn
	conn = self:on(eventName, function(self, ...)
		if not fired then
			fired = true
			result = { ... }
			if conn and conn.Connected then conn:Disconnect() end
			coroutine.resume(co, true)
		end
	end, 0)
	self:delay(timeout, function()
		if not fired then
			fired = true
			if conn and conn.Connected then conn:Disconnect() end
			coroutine.resume(co, false)
		end
	end)
	local ok = coroutine.yield()
	if ok then
		return true, table.unpack(result or {})
	else
		return false
	end
end

function AdvancedClass:waitForAny(events: { string }): (string, ...any)
	local co = coroutine.running()
	if not co then error("waitForAny must be called within a coroutine") end
	local done = false
	local conns = {}
	local function finish(ev, ...)
		if done then return end
		done = true
		for _, c in ipairs(conns) do if c.Connected then c:Disconnect() end end
		coroutine.resume(co, ev, ...)
	end
	for _, ev in ipairs(events) do
		table.insert(conns, self:on(ev, function(self, ...)
			finish(ev, ...)
		end))
	end
	local ev, a, b, c, d = coroutine.yield()
	return ev, a, b, c, d
end

-- Property observers
function AdvancedClass:bindProperty(propertyName: string, callback: (newValue: any, oldValue: any) -> ()): ()
	if not self._observers then self._observers = {} end
	if not self._observers[propertyName] then self._observers[propertyName] = {} end
	table.insert(self._observers[propertyName], callback)
end

function AdvancedClass:unbindProperty(propertyName: string, callback: (newValue: any, oldValue: any) -> ()): ()
	if self._observers and self._observers[propertyName] then
		for i, cb in ipairs(self._observers[propertyName]) do
			if cb == callback then
				table.remove(self._observers[propertyName], i)
				break
			end
		end
	end
end

function AdvancedClass:watch(props: { string }, callback: (prop: string, newValue: any, oldValue: any) -> ())
	local unbinders = {}
	for _, p in ipairs(props) do
		local fn = function(newValue, oldValue) callback(p, newValue, oldValue) end
		self:bindProperty(p, fn)
		table.insert(unbinders, function() self:unbindProperty(p, fn) end)
	end
	return function()
		for _, u in ipairs(unbinders) do u() end
	end
end

function AdvancedClass:watchAll(predicate, callback)
	local function handler(prop, newValue, oldValue)
		if not predicate or predicate(prop, newValue, oldValue) then
			callback(prop, newValue, oldValue)
		end
	end
	local conns = {}
	table.insert(conns, self:on("changed", function(_, prop, newValue, oldValue)
		handler(prop, newValue, oldValue)
	end))
	return function()
		for _, c in ipairs(conns) do if c.Connected then c:Disconnect() end end
	end
end

-- Bindings
function AdvancedClass:bindTo(target: any, targetProp: string, sourceProp: string?): ()->()
	sourceProp = sourceProp or targetProp
	local fn = function(newValue) target[targetProp] = newValue end
	self:bindProperty(sourceProp, fn)
	-- initial sync
	if rawget(self, sourceProp) ~= nil then target[targetProp] = self[sourceProp] end
	return function() self:unbindProperty(sourceProp, fn) end
end

function AdvancedClass:linkTwoWay(other: any, propA: string, propB: string): ()->()
	local unA = self:bindTo(other, propB, propA)
	local unB = other.bindTo and other:bindTo(self, propA, propB) or (function()
		local fn = function(newValue) self[propA] = newValue end
		if other.bindProperty then other:bindProperty(propB, fn) end
		return function()
			if other.unbindProperty then other:unbindProperty(propB, fn) end
		end
	end)()
	return function() unA(); unB() end
end

-- Scheduling
function AdvancedClass:defer(callback: () -> ()): ()
	task.defer(callback)
end

function AdvancedClass:delay(time: number, callback: () -> ()): ()
	local cancelled = false
	local handle = { cancel = function() cancelled = true end }
	table.insert(self._jobs.timers, handle)
	task.delay(time, function()
		if not cancelled then callback() end
	end)
end

function AdvancedClass:interval(time: number, callback: () -> ()): { cancel: () -> () }
	local cancelled = false
	local handle = { cancel = function() cancelled = true end }
	table.insert(self._jobs.intervals, handle)
	task.spawn(function()
		while not cancelled do
			task.wait(time)
			if cancelled then break end
			callback()
		end
	end)
	return handle
end

function AdvancedClass:debounce(fn: (...any) -> (), ms: number)
	local timer = nil
	return function(...)
		local args = table.pack(...)
		if timer then timer.cancelled = true end
		local t = { cancelled = false }
		timer = t
		task.delay(ms/1000, function()
			if not t.cancelled then fn(table.unpack(args, 1, args.n)) end
		end)
	end
end

function AdvancedClass:throttle(fn: (...any) -> (), ms: number)
	local open, queuedArgs = true, nil
	return function(...)
		local args = table.pack(...)
		if open then
			open = false
			fn(table.unpack(args, 1, args.n))
			task.delay(ms/1000, function()
				open = true
				if queuedArgs then
					local qa = queuedArgs
					queuedArgs = nil
					fn(table.unpack(qa, 1, qa.n))
				end
			end)
		else
			queuedArgs = args
		end
	end
end

function AdvancedClass:cancelAllJobs()
	for _, h in ipairs(self._jobs.intervals) do if h and h.cancel then h.cancel() end end
	for _, h in ipairs(self._jobs.timers) do if h and h.cancel then h.cancel() end end
	self._jobs.intervals = {}
	self._jobs.timers = {}
end

-- Children tree
function AdvancedClass:addChild(child: any)
	self:ensureNotDestroyed()
	table.insert(self._children, child)
	child.parent = self
	self:emit("childAdded", child)
end

function AdvancedClass:removeChild(child: any)
	for i, c in ipairs(self._children) do
		if c == child then
			table.remove(self._children, i)
			self:emit("childRemoved", child)
			child.parent = nil
			break
		end
	end
end

function AdvancedClass:getChildren(): { any }
	return self._children
end

function AdvancedClass:destroyChildren()
	for i = #self._children, 1, -1 do
		local c = self._children[i]
		if c and c.destroy then c:destroy() end
	end
	self._children = {}
end

-- Identity/Tags/Logging
local LOG_LEVELS = { trace=1, debug=2, info=3, warn=4, error=5 }
function AdvancedClass:setLogger(logger) self._logger = logger end
function AdvancedClass:setLogLevel(level: string) self._logLevel = LOG_LEVELS[level] or 3 end

function AdvancedClass:toString(): string
	local str = self.className or "Instance"
	if self.id then str = str .. " #" .. tostring(self.id) end
	return str
end

function AdvancedClass:log(level: string, message: string): ()
	local cur = self._logLevel or 3
	local lvl = LOG_LEVELS[level] or 3
	if lvl < cur then return end
	local formatted = "[" .. level:upper() .. "] " .. self:toString() .. ": " .. message
	if self._logger then
		self._logger(level, formatted)
	else
		if level == "error" then
			warn(formatted)
		else
			print(formatted)
		end
	end
end

function AdvancedClass:logf(level: string, fmt: string, ...: any)
	self:log(level, string.format(fmt, ...))
end

function AdvancedClass:addTag(tag: string) self._tags[tag] = true end
function AdvancedClass:hasTag(tag: string) return self._tags[tag] == true end
function AdvancedClass:removeTag(tag: string) self._tags[tag] = nil end

-- Serialization / State
local function serializeTable(tbl: any, seen: { [any]: boolean }): any
	if type(tbl) ~= "table" then return tbl end
	if seen[tbl] then return "<recursive>" end
	seen[tbl] = true
	local result = {}
	for k, v in pairs(tbl) do
		if type(v) ~= "function" and k ~= "_events" and k ~= "_observers" and k ~= "_connections" and k ~= "_jobs" and k ~= "_children" then
			result[k] = serializeTable(v, seen)
		end
	end
	return result
end

function AdvancedClass:serialize(): { [string]: any }
	return serializeTable(self, {})
end

function AdvancedClass:deserialize(data: { [string]: any })
	for k, v in pairs(data) do
		if type(v) ~= "function" then
			rawset(self, k, v)
		end
	end
	self._updatedAt = now()
end

function AdvancedClass:toJSON(): string
	return jsonEncode(self:serialize())
end

function AdvancedClass:fromJSON(json: string)
	self:deserialize(jsonDecode(json))
end

function AdvancedClass:snapshot(): { [string]: any }
	return self:serialize()
end

function AdvancedClass:diff(other: any): { [string]: { old: any, new: any } }
	local a = self:serialize()
	local b = type(other) == "table" and (other.serialize and other:serialize() or other) or {}
	local out = {}
	local seen = {}
	for k, v in pairs(a) do
		seen[k] = true
		if b[k] == nil or jsonEncode(b[k]) ~= jsonEncode(v) then
			out[k] = { old = v, new = b[k] }
		end
	end
	for k, v in pairs(b) do
		if not seen[k] then
			out[k] = { old = a[k], new = v }
		end
	end
	return out
end

function AdvancedClass:commit()
	table.insert(self._history.past, self:snapshot())
	self._history.future = {}
	if #self._history.past > self._history.limit then
		table.remove(self._history.past, 1)
	end
end

local function applySnapshot(self, snap)
	for k, v in pairs(snap) do
		rawset(self, k, v)
	end
	self._updatedAt = now()
	self:emit("restored")
end

function AdvancedClass:undo(): boolean
	local past = self._history.past
	if #past == 0 then return false end
	local snap = table.remove(past)
	table.insert(self._history.future, self:snapshot())
	applySnapshot(self, snap)
	return true
end

function AdvancedClass:redo(): boolean
	local future = self._history.future
	if #future == 0 then return false end
	local snap = table.remove(future)
	table.insert(self._history.past, self:snapshot())
	applySnapshot(self, snap)
	return true
end

function AdvancedClass:clearHistory()
	self._history.past, self._history.future = {}, {}
end

return AdvancedClass
