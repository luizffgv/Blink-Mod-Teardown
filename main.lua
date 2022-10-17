#include "blinktool.lua"

function init()
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
