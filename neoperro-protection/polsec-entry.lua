-- Upload this through PolSec; its generated loader supplies authentication.
local started = os.clock()
local payload = __NEOPERRO_PAYLOAD_LITERAL__
local expected = '__NEOPERRO_PAYLOAD_SHA256__'
if type(crypt) ~= 'table' or type(crypt.hash) ~= 'function' or type(loadstring) ~= 'function' then
    error('[neoperro] This protected build requires SHA-256 and source compilation support.', 0)
end
local ok, digest = pcall(function() return crypt.hash(payload, 'sha256') end)
if not ok or type(digest) ~= 'string' or digest:lower() ~= expected then
    error('[neoperro] Protected payload integrity check failed.', 0)
end
local hashed = os.clock()
local environment = type(getgenv) == 'function' and getgenv() or _G
local previous = environment and environment.__neoperroRuntimeV1
if type(previous) == 'table' and previous.Alive and previous.Distribution == 'PolSec' and previous.ProtectedBuild == expected
    and type(previous.ApplyConfig) == 'function' then
    payload = nil
    return previous:ApplyConfig(environment.neoperro)
end
local program = loadstring(payload, '@neoperro-protected')
if type(program) ~= 'function' then
    error('[neoperro] Protected build cannot compile in this executor.', 0)
end
local compiled = os.clock()
payload = nil
local runtime = program(environment and environment.neoperro)
if type(runtime) == 'table' then
    runtime.Distribution = 'PolSec'
    runtime.ProtectedBuild = expected
    runtime.StartupProtection = {HashMs = (hashed - started) * 1000,
        CompileMs = (compiled - hashed) * 1000, InitializeMs = (os.clock() - compiled) * 1000}
end
return runtime
