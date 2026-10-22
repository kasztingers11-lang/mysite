"""Run portable Lua regression checks using the installed Lua 5.4 library."""
import ctypes
import ctypes.util
import sys
from pathlib import Path

files = ['neoperro.lua', 'neoperro-full.lua', 'neoperro-runtime.lua', 'neoperro-config.lua', *sys.argv[1:]]
library = ctypes.util.find_library('lua5.4')
if not library:
    # Native Windows commonly has no system Lua DLL. Lupa's explicit Lua 5.4
    # backend runs the same files/assertions, not a syntax-only substitute.
    try:
        from lupa.lua54 import LuaRuntime
    except ImportError:
        raise SystemExit('Install Lua 5.4 or Python lupa (lua54 backend) to run the regressions.')
    for file in files:
        lua = LuaRuntime()
        chunk = lua.eval('function(path) return assert(loadfile(path)) end')(str(Path(file)))
        if file in sys.argv[1:]:
            chunk()
        print(f'{file}: OK (Lua 5.4 via Lupa)')
    raise SystemExit(0)

lib = ctypes.CDLL(library)
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lib.luaL_loadfilex.restype = ctypes.c_int
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_pcallk.restype = ctypes.c_int
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]

for file in files:
    state = lib.luaL_newstate()
    lib.luaL_openlibs(state)
    code = lib.luaL_loadfilex(state, str(Path(file)).encode(), None)
    if not code and file in sys.argv[1:]:
        code = lib.lua_pcallk(state, 0, 0, 0, 0, None)
    if code:
        error = lib.lua_tolstring(state, -1, None).decode()
        raise SystemExit(f'{file}: {error}')
    lib.lua_close(state)
    print(f'{file}: OK')
