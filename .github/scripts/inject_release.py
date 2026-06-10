"""Reads /tmp/release.json and injects BAKED_RELEASE into _site/index.html."""
import json

with open('/tmp/release.json') as f:
    raw = f.read().strip()

try:
    release = json.loads(raw)
    if not isinstance(release, dict) or 'tag_name' not in release:
        raise ValueError('no release')
    baked = f'const BAKED_RELEASE = {json.dumps(release)};'
    print('Baked release:', release['tag_name'])
except Exception:
    baked = ''
    print('No release found — download cards will show fallback')

with open('_site/index.html') as f:
    html = f.read()

html = html.replace('/* __BAKED_RELEASE__ */', baked)

with open('_site/index.html', 'w') as f:
    f.write(html)
