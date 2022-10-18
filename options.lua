#include "constants.lua"
#include "registry.lua"

-- -------------------------------- Constants ------------------------------- --

SETTINGS_WIDTH = 600





-- -------------------------------- Functions ------------------------------- --

function GetAccentColor(alpha)
    return 0.4, 0.6, 1, alpha or 1
end

function GetWarningColor(alpha)
    return 1, 0.6, 0.6, alpha or 1
end

function GetForegroundColor(alpha)
    return 0.9, 0.9, 0.9, alpha or 1
end

function GetBackgroundColor(alpha)
    return 0.1, 0.1, 0.1, alpha or 1
end

---Wrapper for Teardown's UiSlider
---@param name string Slider name
---@param value number Current value
---@param min number Minimum value
---@param max number Maximum value
---@param size integer Size of the slider, in pixels
---@param default? number Default value, will be highlighted.
---@return number # New value
---@return boolean # True only if the slider was released
function Slider(name, value, min, max, size, default)
    local NAME_HEIGHT = 32
    local TOOLTIP_TEXT_HEIGHT = 20
    local NAME_MARGIN = 8
    local DOT_WIDTH, DOT_HEIGHT = UiGetImageSize("ui/common/dot.png")
    local ARROW_WIDTH, ARROW_HEIGHT = 18, 9
    local TOTAL_HEIGHT = NAME_HEIGHT + NAME_MARGIN + DOT_HEIGHT + ARROW_HEIGHT / 2 + TOOLTIP_TEXT_HEIGHT
    local MARGIN = 16

    -- Sometimes we get a -0, which does no harm except it looks bad.
    -- what?
    if value == 0 then
        value = 0
    end

    local delta = max - min
    local scale = size / delta
    local scaled = (value - min) * scale
    local res, done
    local next_point = { 0, TOTAL_HEIGHT + MARGIN }

    do
        UiPush()
        UiAlign("top")
        UiTranslate(-size / 2, 0)
        UiFont("bold.ttf", NAME_HEIGHT)
        UiColor(GetAccentColor())
        UiText(name)
        UiTranslate(0, NAME_HEIGHT + NAME_MARGIN)

        UiAlign("middle")
        UiColor(GetForegroundColor())
        if value == default then
            UiColor(GetAccentColor())
        end

        UiRect(scaled, 3)

        do
            UiPush()
            UiTranslate(scaled, 0)
            do -- Tooltip
                UiPush()
                do
                    UiPush()
                    UiTranslate(0, DOT_HEIGHT)
                    UiRotate(90)
                    UiAlign("middle center")
                    UiImage("ui/common/play.png")
                    UiPop()
                end
                UiAlign("top center")
                UiTranslate(0, DOT_HEIGHT + ARROW_HEIGHT / 2 - 1)
                UiFont("bold.ttf", TOOLTIP_TEXT_HEIGHT)
                local txt_width = UiGetTextSize(tostring(value))
                UiRect(math.max(txt_width, ARROW_WIDTH), TOOLTIP_TEXT_HEIGHT)
                UiColor(0, 0, 0)
                UiText(tostring(value))
                UiPop()
            end
            UiColor(0.2, 0.2, 0.2)
            UiRect(size - scaled, 3)
            UiPop()
        end
        UiAlign("center middle")
        res, done = UiSlider("ui/common/dot.png", "x", scaled, 0, delta * scale)
        UiPop()
    end
    UiTranslate(next_point[1], next_point[2])
    return res / scale + min, done
end

---Wrapper for Teardown's UiSlider, but for integer values.
---@param name string Slider name
---@param value integer Current value
---@param min integer Minimum value
---@param max integer Maximum value
---@param size integer Size of the slider, in pixels
---@param default? integer Default value, will be highlighted.
---@return integer # New value
---@return boolean # True only if the slider was released
function SliderI(name, value, min, max, size, default)
    local res, done = Slider(name, value, min, max, size, default)
    return math.ceil(res - 0.5), done
end

---Displays a checkbox
---@param name string Name to be displayed
---@param value boolean Current value of the property
---@param default? boolean Default value of the property
---@return boolean # New value of the property
function Checkbox(name, value, default)
    local TEXT_HEIGHT = 32
    local IMAGES = {
        -- This function assumes both images have 1:1 aspect ratio, but they can
        --  have different sizes
        [true] = "ui/common/box-solid-6.png",
        [false] = "ui/common/box-outline-fill-6.png"
    }
    local IMG_SZ = math.max((UiGetImageSize(IMAGES[true])), (UiGetImageSize(IMAGES[false])))
    local TEXT_MARGIN = 8
    local HEIGHT = math.max(TEXT_HEIGHT, IMG_SZ)
    local MARGIN = 16

    do
        UiPush()

        UiAlign("middle")
        UiTranslate(0, HEIGHT / 2)
        UiColor(GetAccentColor())

        do
            UiPush()
            if value ~= default then
                UiColor(GetForegroundColor())
            end

            if UiImageButton(IMAGES[value]) then
                value = not value
            end
            UiPop()
        end

        UiTranslate(IMG_SZ + TEXT_MARGIN, 0)
        UiFont("bold.ttf", TEXT_HEIGHT)
        UiText(name)

        UiPop()
    end

    UiTranslate(0, HEIGHT + MARGIN)

    return value
end

function Title(text)
    local TEXT_HEIGHT = 64
    local MARGIN = 32

    do
        UiPush()
        UiAlign("center top")
        UiFont("bold.ttf", TEXT_HEIGHT)
        UiText("Blink")
        UiPop()
    end

    UiTranslate(0, TEXT_HEIGHT + MARGIN)
end

function DoBackground()
    do
        UiPush()
        UiAlign("")
        UiTranslate(0, 0)
        UiColor(GetBackgroundColor())
        UiRect(UiWidth(), UiHeight())
        UiPop()
    end
end

function DoTitle()
    local dt = GetTimeStep()
    local title_offset = 0
    if PreviewProgress then
        if PreviewProgress >= 1 then
            PreviewProgress = nil
        else
            PreviewProgress = math.min(1, PreviewProgress + dt / Duration)

            title_offset = (1 - (PreviewProgress - 1) ^ 2) * Range * 10
        end

    end
    UiTranslate(title_offset, 0)
    local r, g, b, a = GetAccentColor()
    if PreviewProgress then
        a = a * (0.75 - PreviewProgress)
    end
    UiColor(r, g, b, a)
    Title("Blink")
    UiTranslate(-title_offset, 0)
end

function DoSliders()
    local range_r, duration_r
    Range, range_r = SliderI("Range", Range, 5, 100, SETTINGS_WIDTH, Registry:GetDefault(Registry.KEYS.RANGE))
    Cooldown = SliderI("Cooldown", Cooldown, 0, 60, SETTINGS_WIDTH, Registry:GetDefault(Registry.KEYS.COOLDOWN))
    Duration, duration_r = Slider("Duration", Duration, 0.1, 1, SETTINGS_WIDTH,
        Registry:GetDefault(Registry.KEYS.DURATION))
    Duration = math.ceil(Duration * 10 - 0.5) / 10

    if range_r or duration_r then
        PreviewProgress = 0
    end
end

function DoCheckboxes()
    UiTranslate(-SETTINGS_WIDTH / 2, 0)
    Shake = Checkbox("Camera shake (experimental)", Shake, Registry:GetDefault(Registry.KEYS.EXPERIMENTAL_SHAKE))
    UiTranslate(SETTINGS_WIDTH / 2, 0)
end

function DoButtons()
    local KEYBINDING_BTN_HEIGHT = 32
    local KEYBINDING_BTN_MARGIN = 16
    local EXIT_BUTTONS_HEIGHT = 28
    do
        UiPush()
        UiColor(GetForegroundColor())
        UiAlign("top center")
        UiFont("bold.ttf", KEYBINDING_BTN_HEIGHT)
        if UiTextButton("Key binding") then
            BindingModal = true
        end
        UiTranslate(0, KEYBINDING_BTN_HEIGHT + KEYBINDING_BTN_MARGIN)

        UiFont("bold.ttf", EXIT_BUTTONS_HEIGHT)
        do
            UiPush()
            UiAlign("top left")
            UiTranslate(-SETTINGS_WIDTH / 2, 0)
            if UiTextButton("Cancel") then
                Menu()
            end
            UiPop()
        end
        do
            UiPush()
            UiAlign("top right")
            UiTranslate(SETTINGS_WIDTH / 2, 0)
            if UiTextButton("Apply") then
                SaveSettings()
                Menu()
            end
            UiPop()
        end
        UiPop()
    end
end

function DoBindingModal()
    local HELP_MARGIN = 64
    local WARNING_MARGIN = 16
    local KEY_HEIGHT = 96

    do
        UiPush()
        UiColor(0, 0, 0, 0.5 - (BindingModalFade or 0) / 2)
        UiBlur(1 - (BindingModalFade or 0))
        UiRect(UiWidth(), UiHeight())

        do
            UiPush()
            UiAlign("center middle")
            UiTranslate(UiCenter(), UiMiddle())
            UiColor(GetAccentColor(1 - (BindingModalFade or 0)))
            UiFont("bold.ttf", KEY_HEIGHT)
            UiText(BoundKey)
            do
                UiPush()
                UiTranslate(0, KEY_HEIGHT / 2 + HELP_MARGIN)
                UiColor(GetForegroundColor(1 - (BindingModalFade or 0)))
                UiFont("regular.ttf", 64)
                UiText("Press a key", true)
                UiFont("regular.ttf", 24)
                UiText("Backspace to unbind", false)
                UiPop()
            end
            UiPop()
        end
        UiAlign("bottom center")
        UiTranslate(UiCenter(), UiHeight() - WARNING_MARGIN)
        UiColor(GetWarningColor(1 - (BindingModalFade or 0)))
        UiFont("regular.ttf", 20)
        UiText("If bound, the tool will be removed from the hotbar")
        UiPop()
    end

    local last_pressed_key = InputLastPressedKey()
    if last_pressed_key ~= "" and last_pressed_key ~= "esc" and not BindingModalFade then
        BindingModalFade = 0
        if last_pressed_key == "backspace" then
            BoundKey = ""
        else
            BoundKey = last_pressed_key
        end
    end

    if BindingModalFade then
        if BindingModalFade >= 1 then
            BindingModalFade = nil
            BindingModal = false
        else
            BindingModalFade = BindingModalFade + GetTimeStep() * 3
        end
    end

end

function SaveSettings()
    Registry:Set(Registry.KEYS.RANGE, Range)
    Registry:Set(Registry.KEYS.COOLDOWN, Cooldown)
    Registry:Set(Registry.KEYS.DURATION, Duration)
    Registry:Set(Registry.KEYS.KEYBIND, BoundKey)
    Registry:Set(Registry.KEYS.EXPERIMENTAL_SHAKE, Shake)
end

function LoadModules()
    ConstantsModule()
    RegistryModule()
end

function init()
    LoadModules()

    Range = Registry:Get(Registry.KEYS.RANGE)
    Cooldown = Registry:Get(Registry.KEYS.COOLDOWN)
    Duration = Registry:Get(Registry.KEYS.DURATION)
    BoundKey = Registry:Get(Registry.KEYS.KEYBIND)
    Shake = Registry:Get(Registry.KEYS.EXPERIMENTAL_SHAKE)

    BindingModal = false
    PreviewProgress = nil
    BindingModalFade = nil
end

function draw()
    DoBackground()

    if BindingModal then
        UiDisableInput()
    end

    do
        UiPush()
        UiTranslate(UiCenter(), 256)
        DoTitle()
        DoSliders()
        DoCheckboxes()
        DoButtons()
        UiPop()
    end

    UiEnableInput()

    if BindingModal then
        DoBindingModal()
    end
end
