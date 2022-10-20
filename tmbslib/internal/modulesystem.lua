---Declares a module.
---@param class string Class name of the module
---@param deps? string[] Dependencies
function _Module(class, deps)
    _G[class]._ms_deps = deps or {}
end

---Loads a module if not loaded
---@param name string Name of the module
function Load(name)
    if not _G[name]._ms_loaded then
        for k, dep in ipairs(_G[name]._ms_deps) do
            Load(dep)
        end

        if _G[name .. "Loader"] then
            _G[name .. "Loader"]()
        end
        _G[name]._ms_loaded = function() end
    end
    return Load
end
