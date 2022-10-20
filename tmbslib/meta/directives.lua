---@meta

---TMBS directive: Includes a file if it not yet included
---@param path string File path (relative to src/)
function _include(path) end

---TMBS directive: Declares a TMBS module
---@param name string Module name
function _module(name) end

---TMBS directive: Adds a TMBS dependency to the current module
---@param dependency string Dependency name
function _requires(dependency) end
