include "modulesystem"
include "BlinkTool"

function LoadModules()
    Require "BlinkTool"
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
