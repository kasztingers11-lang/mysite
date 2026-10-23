"""Exercise the generated upload with mock grants; never contact FlowAuth or read a key."""
from pathlib import Path
import argparse
import hashlib
import json
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--release', type=Path, default=root.parent / 'releases/neoperro-1.3.12')
args = parser.parse_args()
release = args.release.resolve()
upload = (release / 'neoperro-flowauth-upload.obfuscated.lua').read_text(encoding='utf-8')
payload = (release / 'neoperro-native.obfuscated.lua').read_text(encoding='utf-8')
metadata = json.loads((release / 'BUILD.json').read_text(encoding='utf-8'))
assert hashlib.sha256(payload.encode()).hexdigest() == metadata['native_payload_sha256']
assert hashlib.sha256(upload.encode()).hexdigest() == metadata['upload_sha256']


def hash_bytes(source, algorithm):
    assert algorithm == 'sha256'
    return hashlib.sha256(source.encode('utf-8')).hexdigest()


def run_guard(source, grant, crypt_present=True, compiler_ok=True):
    lua = LuaRuntime()
    lua.globals().__protected_hash = hash_bytes
    run = lua.eval('''function(source, grant, cryptPresent, compilerOK)
        local hash, compilations = __protected_hash, 0
        local environment = {error=error, type=type, pcall=pcall, LRM_IsUserPremium=grant}
        if cryptPresent then environment.crypt={hash=function(s,a) return hash(s,a) end} end
        environment.loadstring=function()
            compilations=compilations+1
            if compilerOK then return function()return 'payload-started'end end
            return nil,'synthetic compile rejection'
        end
        local fn=assert(load(source,'protected-guard','t',environment))
        local ok,result=pcall(fn)
        return ok,result,compilations
    end''')
    return run(source, grant, crypt_present, compiler_ok)


for invalid in [None, False, 'true', 1]:
    ok, message, compiled = run_guard(upload, invalid)
    assert not ok and 'valid key' in message and compiled == 0
tampered = upload.replace(payload, payload + ' ', 1)
assert tampered != upload
ok, message, compiled = run_guard(tampered, True)
assert not ok and 'integrity check failed' in message and compiled == 0
ok, message, compiled = run_guard(upload, True, crypt_present=False)
assert not ok and 'SHA-256' in message and compiled == 0
ok, message, compiled = run_guard(upload, True, compiler_ok=False)
assert not ok and 'cannot compile' in message and compiled == 1
ok, message, compiled = run_guard(upload, True)
assert ok and message == 'payload-started' and compiled == 1
print('Protected entry: 4 denied mock grants, changed payload, missing hash, compile failure and valid integrity paths pass')

lua = LuaRuntime()
lua.globals().__protected_hash = hash_bytes
lua.globals().__protected_path = str(release / 'neoperro-flowauth-upload.obfuscated.lua').replace('\\', '/')
test = (root / 'tests/runtime.spec.lua').read_text(encoding='utf-8')
old = """local function loadRuntime(config, file)
    env.neoperro=Core.copy(config or Defaults)
    return assert(loadfile(file or 'neoperro-src/runtime.lua','t',env))()
end"""
new = """local protectedHash,protectedPath=__protected_hash,__protected_path
env.crypt={hash=function(s,a)return protectedHash(s,a)end}
env.LRM_IsUserPremium=true -- Local synthetic fixture; not a FlowAuth authorization result.
env.loadstring=function(source,name)return load(source,name,'t',env)end
local protectedLoads=0
local function loadRuntime(config, file)
    env.neoperro=Core.copy(config or Defaults)
    protectedLoads=protectedLoads+1
    if protectedLoads>1 then file=protectedPath end
    return assert(loadfile(file or 'neoperro-src/runtime.lua','t',env))()
end"""
assert test.count(old) == 1
lua.execute(test.replace(old, new))
print('Entire runtime suite passes against the protected upload after the initial mock intro fixture')

starter = (root / 'neoperro-flowauth.lua').read_text(encoding='utf-8')
assert starter.startswith('script_key = "FLOW-REPLACE-WITH-YOUR-KEY";')
assert 'raw.githubusercontent.com' not in starter
assert '56265b6f33860b070090db29d343e59a.lua' in starter and starter.rstrip().endswith('(script_key)')
LuaRuntime().eval('function(source)return assert(load(source))end')(starter)
lua = LuaRuntime()
lua.execute('function getgenv()return _G end')
lua.execute((root / 'neoperro-config.lua').read_text(encoding='utf-8'))
baseline = lua.globals().neoperro
lua.execute(starter.split('\nloadstring(game:HttpGet(', 1)[0])
equal = lua.eval("dofile('neoperro-src/core.lua').equal")
assert equal(baseline, lua.globals().neoperro), 'Explanations must not change a single configuration value'
print('FlowAuth starter syntax/order/placeholder/public loader checks pass; provider authentication was not tested')
