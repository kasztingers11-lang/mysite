"""Test the PolSec bootstrap and native runtime without contacting its service."""
from pathlib import Path
import hashlib
import json
from lupa.lua54 import LuaRuntime

root = Path(__file__).resolve().parent.parent
release = root.parent / 'releases/neoperro-1.3.22-polsec'
upload_path = release / 'neoperro-polsec-upload.obfuscated.lua'
upload = upload_path.read_text(encoding='utf-8')
metadata = json.loads((release / 'BUILD.json').read_text(encoding='utf-8'))
payload = (root.parent / 'releases/neoperro-1.3.22/neoperro-native.obfuscated.lua').read_text(encoding='utf-8')
assert hashlib.sha256(upload.encode()).hexdigest() == metadata['upload_sha256']
assert hashlib.sha256(payload.encode()).hexdigest() == metadata['native_payload_sha256']
assert 'LRM_IsUserPremium' not in upload and 'FlowAuth' not in upload


def hash_bytes(source, algorithm):
    assert algorithm == 'sha256'
    return hashlib.sha256(source.encode()).hexdigest()


lua = LuaRuntime()
lua.globals().__hash = hash_bytes
lua.globals().__digest = metadata['native_payload_sha256']
run = lua.eval('''function(source, prior, hasHash, compilerOK)
    local compilations,applies=0,0
    local environment={type=type,pcall=pcall,error=error,os=os,neoperro={marker='edited-table'}}
    environment.getgenv=function()return environment end
    if hasHash then environment.crypt={hash=function(s,a)return __hash(s,a)end}end
    if prior then
        environment.__neoperroRuntimeV1={Alive=true,Distribution=prior,ProtectedBuild=__digest,
            ApplyConfig=function(self,config)assert(config.marker=='edited-table');applies=applies+1;return self end}
    end
    environment.loadstring=function()
        compilations=compilations+1
        if compilerOK then return function(config)
            assert(config==environment.neoperro,'Payload receives captured user configuration')
            return {Alive=true,Version='1.3.22'}
        end end
    end
    local ok,result=pcall(assert(load(source,'polsec-entry','t',environment)))
    return ok,result,compilations,applies
end''')
for prior in [None, 'FlowAuth', 'PolSec']:
    ok, result, compiled, applied = run(upload, prior, True, True)
    assert ok and result.Distribution == 'PolSec'
    assert compiled == (0 if prior == 'PolSec' else 1)
    assert applied == (1 if prior == 'PolSec' else 0)
tampered = upload.replace(payload, payload + ' ', 1)
assert tampered != upload
ok, result, compiled, _ = run(tampered, None, True, True)
assert not ok and 'integrity check failed' in result and compiled == 0
ok, result, compiled, _ = run(upload, None, False, True)
assert not ok and 'SHA-256' in result and compiled == 0
ok, result, compiled, _ = run(upload, None, True, False)
assert not ok and 'cannot compile' in result and compiled == 1
print('PolSec bootstrap: cold load, correct-provider reuse, foreign-provider replacement, integrity/hash/compile errors pass')

lua = LuaRuntime()
lua.globals().__protected_hash = hash_bytes
lua.globals().__protected_path = str(upload_path).replace('\\', '/')
test = (root / 'tests/runtime.spec.lua').read_text(encoding='utf-8')
old = """local function loadRuntime(config, file)
    env.neoperro=Core.copy(config or Defaults)
    return assert(loadfile(file or 'neoperro-src/runtime.lua','t',env))()
end"""
new = """local protectedHash,protectedPath=__protected_hash,__protected_path
env.crypt={hash=function(s,a)return protectedHash(s,a)end}
env.loadstring=function(source,name)return load(source,name,'t',env)end
local protectedLoads=0
local function loadRuntime(config, file)
    env.neoperro=Core.copy(config or Defaults)
    protectedLoads=protectedLoads+1
    if protectedLoads>1 then
        file=protectedPath
        if env.__neoperroRuntimeV1 then env.__neoperroRuntimeV1.ProtectedBuild=nil end
    end
    return assert(loadfile(file or 'neoperro-src/runtime.lua','t',env))()
end"""
assert test.count(old) == 1
lua.execute(test.replace(old, new))
print('Complete runtime suite passes through the PolSec upload after the initial mock intro fixture')
print('No real PolSec authorization, provider obfuscation or live gameplay was tested')
