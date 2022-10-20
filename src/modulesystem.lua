---Declares a module
---@param class string Class name of the module
---@param deps? string[] Dependencies
function Module(class, deps)
    _G[class]._ms_deps = deps or {}
end

---Loads a module if not loaded
---@param class string Class name of the module
function Require(class)
    if not _G[class]._ms_loaded then
        for k, dep in ipairs(_G[class]._ms_deps) do
            Require(dep)
        end

        _G[class .. "Loader"]()
        _G[class]._ms_loaded = function() end
    end
    return Require
end
