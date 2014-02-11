local lib = LibStub:NewLibrary("Libra", 1)

if not lib then return end

lib.objects = lib.objects or {}
lib.namespaces = lib.namespaces or {}
lib.embeds = lib.embeds or {}

function lib:Create(objectType, parent, ...)
	return lib.objects[objectType].constructor(self, objectType, parent, ...)
end

function lib:CreateFactory(objectType)
end

function lib:GetModule(object, version)
	local o = self.objects[object]
	if o and o.version >= version then
		return
	end
	self.objects[object] = {
		version = version,
		t = {},
	}
	return self.objects[object].t
end

function lib:GetWidgetName(name)
	name = name or "Generic"
	local namespace = self.namespaces[name]
	if not namespace then
		local n = 0
		namespace = function()
			n = n + 1
			return format("%sLibraWidget%d", name, n)
		end
		self.namespaces[name] = namespace
	end
	return namespace()
end

local mixins = {
	"Create",
}

function lib:Embed(target)
	for i, v in ipairs(mixins) do
		target[v] = self[v]
	end
	for k, v in pairs(self.objects) do
		target["Create"..k] = v.constructor
	end
	self.embeds[target] = true
end

for k, v in pairs(lib.embeds) do
	lib:Embed(v)
end