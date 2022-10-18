function RegistryModule()

    ---@class Registry
    ---@field KEYS table<string, Registry.Key>
    ---@field _PERSISTENT string Path to the mod's persistent keys. Includes a trailing dot!
    Registry = {
    }

    ---@alias Registry.Key.type "int" | "float" | "str" | "bool"

    ---@class Registry.Key
    ---@field key string
    ---@field type Registry.Key.type
    ---@field default boolean|string|number
    Registry.Key = {}

    ---@param key string
    ---@param type Registry.Key.type
    ---@param default any
    ---@return table
    function Registry.Key:New(key, type, default)
        return { key = key, type = type, default = default }
    end

    Registry.KEYS = {
        RANGE = Registry.Key:New("range", "float", 15),
        COOLDOWN = Registry.Key:New("cooldown", "float", 15),
        DURATION = Registry.Key:New("duration", "float", 0.5),
        KEYBIND = Registry.Key:New("keybind", "string", ""),
        EXPERIMENTAL_SHAKE = Registry.Key:New("experimental.shake", "bool", false)
    }

    Registry._PERSISTENT = "savegame.mod." .. Constants.MODID .. "."

    ---Reads a value from the mod's persistent registry
    ---@param key Registry.Key Key to be read from
    ---@return any value
    ---@nodiscard
    function Registry:Get(key)
        local fullkey = self._PERSISTENT .. key.key
        local getters = {
            int = GetInt,
            float = GetFloat,
            string = GetString,
            bool = GetBool
        }

        return HasKey(fullkey) and getters[key.type](fullkey) or key.default
    end

    ---Writes a value to the mod's persistent registry
    ---@param key Registry.Key Key to be written to
    ---@param value boolean|string|number Value to be written
    function Registry:Set(key, value)
        local SETTERS = {
            int = SetInt,
            float = SetFloat,
            string = SetString,
            bool = SetBool
        }

        SETTERS[key.type](self._PERSISTENT .. key.key, value)
    end

    ---Gets the default value of a key
    ---@param key Registry.Key
    ---@return any
    function Registry:GetDefault(key)
        return key.default
    end

    return Registry

end
