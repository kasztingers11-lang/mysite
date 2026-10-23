-- Execution starts here. Table edits reuse this client session; new builds load normally.
local neoperroEnvironment = getgenv()
local neoperroRuntime = neoperroEnvironment.__neoperroRuntimeV1
if type(neoperroRuntime) == 'table' and neoperroRuntime.Alive
    and neoperroRuntime.Version == '__NEOPERRO_VERSION__'
    and neoperroRuntime.Distribution == '__NEOPERRO_DISTRIBUTION__' and type(neoperroRuntime.ApplyConfig) == 'function' then
    __NEOPERRO_CLEAR_KEY__
    neoperroRuntime:ApplyConfig(neoperroEnvironment.neoperro)
    print(string.format('[neoperro] Table updated in %.2f ms.', neoperroRuntime.LastConfigMs))
else
    local started = os.clock()
    local source = game:HttpGet('__NEOPERRO_LOADER_URL__')
    local fetched = os.clock()
    local program = loadstring(source, '@neoperro-loader')
    assert(type(program) == 'function', '[neoperro] Loader could not compile.')
    source = nil
    local compiled = os.clock()
    program(__NEOPERRO_KEY_ARGUMENT__)
    local finished = os.clock()
    print(string.format('[neoperro] Startup: download %.0f ms, loader compile %.0f ms, loader return %.0f ms.',
        (fetched - started) * 1000, (compiled - fetched) * 1000, (finished - compiled) * 1000))
end
