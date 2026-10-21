"""Run portable Lua regression checks using the installed Lua 5.4 library."""
import ctypes
import ctypes.util
import sys
from pathlib import Path

lib = ctypes.CDLL(ctypes.util.find_library('lua5.4'))
lib.luaL_newstate.restype = ctypes.c_void_p
lib.luaL_openlibs.argtypes = [ctypes.c_void_p]
lib.luaL_loadfilex.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p]
lib.luaL_loadfilex.restype = ctypes.c_int
lib.lua_pcallk.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int, ctypes.c_longlong, ctypes.c_void_p]
lib.lua_pcallk.restype = ctypes.c_int
lib.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
lib.lua_tolstring.restype = ctypes.c_char_p
lib.lua_close.argtypes = [ctypes.c_void_p]

for file in ['neoperro.lua', 'neoperro-full.lua', 'neoperro-runtime.lua', 'neoperro-config.lua', *sys.argv[1:]]:
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
