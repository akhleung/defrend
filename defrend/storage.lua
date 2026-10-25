local storage = {}

local M = {}

function M.put(key, value)
    storage[key] = value
end

function M.peek(key)
    return storage[key]
end

function M.remove(key)
    local value = storage[key]
    storage[key] = nil
    return value
end

return M
