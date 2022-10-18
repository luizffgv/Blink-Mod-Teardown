#include "blinktool.lua"
#include "constants.lua"
#include "registry.lua"
#include "vectors.lua"

function LoadModules()
    ConstantsModule()
    RegistryModule()
    VectorsModule()
    BlinkToolModule()
    BlinkTool:Init()
end

function init()
    LoadModules()
    BlinkTool:Init()
end

function tick(dt)
    BlinkTool:Tick(dt)
end

function update(dt)
    BlinkTool:Update(dt)
end

function draw(dt)
    BlinkTool:Draw(dt)
end

function handleCommand(command)
    if command == "quickload" then
        LoadModules()
    end
end
