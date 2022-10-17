#include "vectors.lua"
#include "registry.lua"

-- ---------------------------------- Types --------------------------------- --

---@alias handle number

---@class BlinkTool
---@field BLINK_PARTICLES_N integer
---@field BLINK_DURATION number
---@field BLINK_DURATION_DEFAULT number
---@field RANGE number
---@field COOLDOWN_DURATION number
---@field COUGH_DURATION number
---@field KEYBIND string
---@field status BlinkTool.status_id
---@field sourcepos table
---@field targetpos table
---@field previewpos table
---@field player_rot table
---@field progress number
---@field cooldown number Current cooldown. nil if out of cooldown.
---@field cough_cooldown number
BlinkTool = {
}

---@enum BlinkTool.status_id
BlinkTool.STATUS_IDS = {
    IDLE = 0,
    PREVIEWING = 1,
    BLINKING = 2
}

---@enum BlinkTool.sound
BlinkTool.SOUNDS = {
    PREVIEW_LOOP = LoadLoop("assets/windloop.ogg"),
    BLINK = LoadSound("assets/swoosh.ogg"),
    COUGH = LoadSound("assets/cough.ogg")
}





-- -------------------------------- Constants ------------------------------- --
BlinkTool.BLINK_PARTICLES_N = 8
BlinkTool.BLINK_DURATION = Registry:Get(Registry.KEYS.DURATION)
BlinkTool.BLINK_DURATION_DEFAULT = Registry:GetDefault(Registry.KEYS.DURATION)
BlinkTool.RANGE = Registry:Get(Registry.KEYS.RANGE)
BlinkTool.COOLDOWN_DURATION = Registry:Get(Registry.KEYS.COOLDOWN)
BlinkTool.COUGH_DURATION = 5
BlinkTool.KEYBIND = Registry:Get(Registry.KEYS.KEYBIND)
if BlinkTool.KEYBIND == "" then
    BlinkTool.KEYBIND = nil
end





-- --------------------------------- Methods -------------------------------- --

---Checks whether the tool is equipped
---@return boolean # true if the tool is equipped
function BlinkTool:_InHand()
    return GetString("game.player.tool") == ID
end

---Starts a state where the player is not previewing nor blinking.
function BlinkTool:_StartIdling()
    self.status = self.STATUS_IDS.IDLE
    self.sourcepos = nil
    self.targetpos = nil
    SetPostProcessingDefault()
end

---Starts previewing the target location
function BlinkTool:_StartPreview()
    ReleasePlayerGrab()
    self.status = self.STATUS_IDS.PREVIEWING
end

---Starts blink. Should only be called while previewing.
function BlinkTool:_StartBlink()
    self.status = self.STATUS_IDS.BLINKING
    self.sourcepos = GetPlayerTransform(false).pos
    self.progress = 0

    if not GetBool("level.unlimitedammo") then
        self.cooldown = self.COOLDOWN_DURATION
        self.cough_cooldown = nil
    end

    PlaySound(self.SOUNDS.BLINK)
    self:_SpawnBlinkParticles()
end

---Checks if the player is not blinking nor previewing
---@return boolean # true if the player is previewing, false otherwise
function BlinkTool:_IsIdling()
    return self.status == self.STATUS_IDS.IDLE
end

---Checks if the player is previewing
---@return boolean # true if the player is previewing, false otherwise
function BlinkTool:_IsPreviewing()
    return self.status == self.STATUS_IDS.PREVIEWING
end

---Checks if the player is blinking
---@return boolean # true if the player is blinking, false otherwise
function BlinkTool:_IsBlinking()
    return self.status == self.STATUS_IDS.BLINKING
end

---Spawns point lights for the blink target preview
function BlinkTool:_DrawPreviewLights()
    if self.targetpos then
        PointLight(self.previewpos, 0.6, 0.8, 1)
    end
end

---Spawns particles for the blink target preview
function BlinkTool:_SpawnPreviewParticles()
    ParticleReset()
    -- Spawn smoke
    ParticleAlpha(0.2)
    ParticleColor(0.6, 0.8, 1)
    ParticleRadius(0.5, 0)
    ParticleType("smoke")
    SpawnParticle(self.previewpos, Vec(), 0.25)
    -- Spawn falling smoke
    ParticleAlpha(0.2, 0.1)
    ParticleGravity(-100)
    ParticleRadius(0.2, 0.3)
    SpawnParticle(self.previewpos, Vec(), 1 / 2)

    -- Spawn glowing particle
    ParticleAlpha(0.05)
    ParticleEmissive(1)
    ParticleGravity(0)
    ParticleRadius(0.3)
    ParticleType("plain")
    SpawnParticle(self.previewpos, Vec(), 0.1)

end

---Spawns particles for the blink effect
function BlinkTool:_SpawnBlinkParticles()
    local cpos = GetCameraTransform().pos
    local dir = UiPixelToWorld(UiWorldToPixel(self.previewpos))
    local velocity = VecScale(dir,
        VecLength(VecSub(self.targetpos, self.sourcepos)) * 3 * self.BLINK_DURATION_DEFAULT / self.BLINK_DURATION)
    ParticleReset()
    ParticleAlpha(1, 0)
    ParticleEmissive(1)
    ParticleRadius(0.025)
    ParticleStretch(15, 0)
    ParticleType("plain")
    ParticleCollide(0)
    for i = 0, 8 do
        SpawnParticle(VecAdd(cpos,
            VecScale(VecCross(dir, DirRandom()), 2)),
            VecAdd(velocity, DirRandom()),
            0.25 + math.random() * 0.75 * self.BLINK_DURATION / self.BLINK_DURATION_DEFAULT)
    end
end

---Applies some post processing. Should only be called while blinking
function BlinkTool:_ApplyBlinkPostProcessing()
    local effect_intensity = 1 - (1 - (self.progress * 2 - 1) ^ 2) / 4
    SetPostProcessingProperty("colorbalance", effect_intensity, effect_intensity, 1)
    SetPostProcessingProperty("saturation", effect_intensity)
end

---Adds and enables the tool
function BlinkTool:Init()
    self.status = BlinkTool.STATUS_IDS.IDLE
    self.cooldown = nil
    self.cough_cooldown = nil

    RegisterTool(ID, "Blink", "MOD/vox/empty.vox")
    if not BlinkTool.KEYBIND then
        SetBool("game.tool." .. ID .. ".enabled", true)
    end
end

---Handles input, and executes other functions that must be called every frame
---or are called every frame for responsivity
---@param dt number
function BlinkTool:Tick(dt)
    -- Handle input
    if (self.KEYBIND or (not InputPressed("lmb") and self:_InHand())) and GetPlayerVehicle() == 0 then
        if (not self.KEYBIND and self:_InHand() and InputPressed("rmb") or self.KEYBIND and InputPressed(self.KEYBIND))
            and self:_IsIdling() then
            if self.cooldown then
                if not self.cough_cooldown then
                    self.cough_cooldown = self.COUGH_DURATION
                    PlaySound(self.SOUNDS.COUGH)
                    SetPlayerHealth(GetPlayerHealth() * 0.75)
                end
            else
                self:_StartPreview()
            end
        elseif (
            not self.KEYBIND and self:_InHand() and InputReleased("rmb") or self.KEYBIND and InputReleased(self.KEYBIND)
            ) and
            not self.cooldown and self:_IsPreviewing() then
            self:_StartBlink()
        end
    else
        self:_StartIdling()
    end

    if self:_IsPreviewing() then
        self:_DrawPreviewLights()

        local cam = GetCameraTransform()
        local look_dir = UiPixelToWorld(UiCenter(), UiMiddle())
        local hit, dist = QueryRaycast(cam.pos, look_dir, self.RANGE, 0, true)
        local eye_height = cam.pos[2] - GetPlayerTransform(false).pos[2]

        self.player_rot = cam.rot
        self.targetpos = VecAdd(cam.pos, VecScale(look_dir, dist))
        self.previewpos = VecAdd(self.targetpos, { 0, eye_height, 0 })
    elseif self:_IsBlinking() then -- Lock camera rotation and player movement
        SetPlayerTransform(Transform(GetPlayerTransform(false).pos, self.player_rot), true)
    end
end

---@param dt number
function BlinkTool:Update(dt)
    if self.cooldown then
        self.cooldown = self.cooldown - dt
        if self.cooldown <= 0 then
            self.cooldown = nil
        end
    end

    if self.cough_cooldown then
        self.cough_cooldown = self.cough_cooldown - dt
        if self.cough_cooldown <= 0 then
            self.cough_cooldown = nil
        end
    end

    if self:_IsPreviewing() then
        self:_SpawnPreviewParticles()
        PlayLoop(self.SOUNDS.PREVIEW_LOOP, self.previewpos, 0.5)
    elseif self:_IsBlinking() then
        self.progress = math.min(1, self.progress + dt / self.BLINK_DURATION)

        SetPlayerTransform(
            Transform(VecLerp(self.sourcepos, self.targetpos, 1 - (self.progress - 1) ^ 2),
                self.player_rot)
            , true)

        self:_ApplyBlinkPostProcessing()
        if self.progress == 1 then
            self:_StartIdling()
        end
    end
end

---@param dt number
function BlinkTool:Draw(dt)
    if self.cooldown and self:_IsIdling() then
        SetFloat("game.tool." .. ID .. ".ammo", self.cooldown + 1)
    else
        SetFloat("game.tool." .. ID .. ".ammo", 10000)
    end
end
