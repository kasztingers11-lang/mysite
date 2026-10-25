"""Build a native-code obfuscated upload and editable FlowAuth starter. No keys are read."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parent
PROMETHEUS_COMMIT = 'a4efc5f381c50ae2a111bdbb9272fa3203685be3'
LOADER = 'https://flowauth.net/v1/loaders/56265b6f33860b070090db29d343e59a.lua'


def explain_table(config):
    help_text = json.loads((ROOT / 'neoperro-protection/table-help.json').read_text(encoding='utf-8'))
    parents = {}
    lines = []
    for line in config.splitlines():
        match = re.match(r"^(\s*)\['([^']+)'\]\s*=", line)
        if match:
            indent, key = match.groups()
            level = len(indent) // 4
            parents[level] = key
            path = '/'.join(parents[i] for i in range(1, level + 1))
            section = help_text['sections'].get(path)
            if section:
                lines.append(indent + '-- ' + section)
            text = help_text['paths'].get(path)
            if not text and ('{' not in line or key in {'Keybind', 'RandomDelay', 'Players', 'Name', 'GroundShotCheck'}):
                text = help_text['defaults'].get(key)
            if path.endswith('/Toggle/Enabled'):
                text = 'Use the on/off key for this feature.'
            if not text and key == 'Color':
                text = 'Red, green and blue, from 0 to 255.' if '/2d-Circle/' in path else 'First color is the box; second is its outline.'
            if not text and key == 'Size' and path.startswith('2d-Box/'):
                text = 'Fixed Height/Width around the character. The drawing follows perspective.'
            if not text and path.startswith('Gun Specifications/') and level == 3 and parents[2] != 'Ranges':
                text = 'Character-relative Height/Width for this gun in this range; switches instantly.'
            if text:
                line = line.ljust(80) + ' -- ' + text
        lines.append(line)
    return '\n'.join(lines)


def build(prometheus, output):
    from lupa.lua51 import LuaRuntime

    actual = subprocess.check_output(['git', '-C', str(prometheus), 'rev-parse', 'HEAD'], text=True).strip()
    if actual != PROMETHEUS_COMMIT:
        raise SystemExit('Prometheus checkout does not match the reviewed pinned commit.')
    if subprocess.check_output(['git', '-C', str(prometheus), 'status', '--porcelain', '--untracked-files=no'], text=True).strip():
        raise SystemExit('Prometheus tracked files differ from the reviewed commit.')
    source = (ROOT / 'neoperro-runtime.lua').read_bytes().replace(b'\r\n', b'\n')
    lua = LuaRuntime(encoding=None)
    transform = lua.eval(b'''function(root, config, source)
        arg = {}
        package.path = root .. '/src/?.lua;' .. root .. '/src/?/init.lua;' .. package.path
        local originalTostring = tostring
        tostring = function(value)
            if type(value) == 'number' then return string.format('%.17g', value) end
            return originalTostring(value)
        end
        local prometheus = require('prometheus')
        prometheus.Logger.logLevel = 0
        local settings = assert(loadfile(config))()
        return prometheus.Pipeline:fromConfig(settings):apply(source, 'neoperro-runtime.lua')
    end''')
    payload = transform(str(prometheus).replace('\\', '/').encode(),
                        str(ROOT / 'neoperro-protection/prometheus.lua').replace('\\', '/').encode(), source)
    payload.decode('utf-8')
    digest = hashlib.sha256(payload).hexdigest()
    separator = '='
    while (']' + separator + ']').encode() in payload:
        separator += '='
    literal = ('[' + separator + '[').encode() + payload + (']' + separator + ']').encode()
    entry = (ROOT / 'neoperro-protection/entry.lua').read_bytes().replace(b'\r\n', b'\n')
    protected = entry.replace(b'__NEOPERRO_PAYLOAD_LITERAL__', literal).replace(b'__NEOPERRO_PAYLOAD_SHA256__', digest.encode())
    output.mkdir(parents=True, exist_ok=True)
    artifact = output / 'neoperro-flowauth-upload.obfuscated.lua'
    artifact.write_bytes(protected)
    native = output / 'neoperro-native.obfuscated.lua'
    native.write_bytes(payload)
    config = (ROOT / 'neoperro-config.lua').read_text(encoding='utf-8')
    starter = ('script_key = "FLOW-REPLACE-WITH-YOUR-KEY";\n\n'
               '-- Put your own key above. Edit the table, then run this whole file.\n'
               '-- Prediction can lead a moving player in X, Y and Z. Auto ignores Value.\n'
               '-- Empty Whitelist lists allow everyone. There is no assignment cap.\n'
               '-- Crouch, lying and emote pose measurements run automatically.\n'
               '-- Table replacements and nested edits apply in this session, checked four times per second.\n'
               '-- Manual Value calibrates at the current ping; later ping changes adapt the lead.\n'
               '-- The intro plays once per client session. There are no intro settings.\n'
               '-- P: Silent toggle | M: Assist toggle | hold Q: Assist | V: Trigger toggle | hold RMB: Trigger | E: stop.\n\n')
    starter += explain_table(config).rstrip() + '\n\n'
    tail = (ROOT / 'neoperro-src/loader-tail.lua').read_text(encoding='utf-8')
    tail = (tail.replace('__NEOPERRO_VERSION__', '1.3.24')
                .replace('__NEOPERRO_DISTRIBUTION__', 'FlowAuth')
                .replace('__NEOPERRO_LOADER_URL__', LOADER)
                .replace('__NEOPERRO_CLEAR_KEY__', 'script_key = nil -- Configuration updates use the already-running session.')
                .replace('__NEOPERRO_KEY_ARGUMENT__', 'script_key'))
    starter += tail
    (ROOT / 'neoperro-flowauth.lua').write_text(starter, encoding='utf-8')
    (output / 'neoperro-flowauth.lua').write_text(starter, encoding='utf-8')
    (output / 'neoperro-flowauth-loader.lua').write_text(tail, encoding='utf-8')
    metadata = {
        'runtime_version': '1.3.24', 'prometheus_commit': PROMETHEUS_COMMIT,
        'source_sha256': hashlib.sha256(source).hexdigest(),
        'native_payload_sha256': digest,
        'upload_sha256': hashlib.sha256(protected).hexdigest(),
        'source_bytes': len(source), 'native_payload_bytes': len(payload), 'upload_bytes': len(protected),
        'native_vm_virtualization': False, 'debug_hooks_or_busy_loop_traps': False,
        'guard': 'FlowAuth signed grant when provider-protected; SHA-256 payload integrity; clean errors',
        'flowauth_end_to_end_tested': False,
    }
    (output / 'BUILD.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'upload': str(artifact), 'starter': str(output / 'neoperro-flowauth.lua'), **metadata}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--prometheus', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT.parent / 'releases/neoperro-1.3.24')
    args = parser.parse_args()
    build(args.prometheus.resolve(), args.output.resolve())
