"""Wrap the already-tested native payload for PolSec. No provider or customer keys."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parent


def build(source_release, output):
    metadata = json.loads((source_release / 'BUILD.json').read_text(encoding='utf-8'))
    source = (ROOT / 'neoperro-runtime.lua').read_bytes().replace(b'\r\n', b'\n')
    payload = (source_release / 'neoperro-native.obfuscated.lua').read_bytes()
    digest = hashlib.sha256(payload).hexdigest()
    if hashlib.sha256(source).hexdigest() != metadata['source_sha256']:
        raise SystemExit('Generated runtime differs from the tested source release. Rebuild and test first.')
    if digest != metadata['native_payload_sha256']:
        raise SystemExit('Native payload does not match the source release metadata.')
    payload.decode('utf-8')
    separator = '='
    while (']' + separator + ']').encode() in payload:
        separator += '='
    literal = ('[' + separator + '[').encode() + payload + (']' + separator + ']').encode()
    entry = (ROOT / 'neoperro-protection/polsec-entry.lua').read_bytes().replace(b'\r\n', b'\n')
    assert b'LRM_IsUserPremium' not in entry and b'FlowAuth' not in entry
    upload = entry.replace(b'__NEOPERRO_PAYLOAD_LITERAL__', literal).replace(b'__NEOPERRO_PAYLOAD_SHA256__', digest.encode())
    output.mkdir(parents=True, exist_ok=True)
    artifact = output / 'neoperro-polsec-upload.obfuscated.lua'
    artifact.write_bytes(upload)
    result = {
        'runtime_version': metadata['runtime_version'],
        'distribution': 'PolSec',
        'source_sha256': metadata['source_sha256'],
        'native_payload_sha256': digest,
        'upload_sha256': hashlib.sha256(upload).hexdigest(),
        'upload_bytes': len(upload),
        'prometheus_commit': metadata['prometheus_commit'],
        'gameplay_payload_changed': False,
        'authentication': 'PolSec generated loader and protected delivery; no invented client grant global',
        'integrity': 'SHA-256 payload check; not an authentication signature',
        'polsec_publication_verified': False,
        'polsec_authentication_tested': False,
    }
    (output / 'BUILD.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'upload': str(artifact), **result}, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--from-release', type=Path, default=ROOT.parent / 'releases/neoperro-1.3.22')
    parser.add_argument('--output', type=Path, default=ROOT.parent / 'releases/neoperro-1.3.22-polsec')
    args = parser.parse_args()
    build(args.from_release.resolve(), args.output.resolve())
