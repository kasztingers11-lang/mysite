if LRM_IsUserPremium ~= true then
    error('[neoperro] Start through the FlowAuth loader with a valid key.', 0)
end

local payload = __NEOPERRO_PAYLOAD_LITERAL__
local expected = '__NEOPERRO_PAYLOAD_SHA256__'
if type(crypt) ~= 'table' or type(crypt.hash) ~= 'function' or type(loadstring) ~= 'function' then
    error('[neoperro] This protected build requires SHA-256 and source compilation support.', 0)
end
local ok, digest = pcall(function() return crypt.hash(payload, 'sha256') end)
if not ok or type(digest) ~= 'string' or digest:lower() ~= expected then
    error('[neoperro] Protected payload integrity check failed.', 0)
end
local program = loadstring(payload, '@neoperro-protected')
if type(program) ~= 'function' then
    error('[neoperro] Protected build cannot compile in this executor.', 0)
end
payload, expected = nil, nil
return program()
