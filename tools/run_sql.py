import json, os, sys, urllib.request

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
env = {}
for line in open(os.path.join(root, '.env'), encoding='utf-8'):
    line = line.strip()
    if line and not line.startswith('#') and '=' in line:
        k, v = line.split('=', 1)
        env[k] = v

script = sys.argv[1] if len(sys.argv) > 1 else 'schema'
sql = open(os.path.join(root, 'supabase', f'{script}.sql'), encoding='utf-8').read()
ref = env['SUPABASE_REF']
tok = env['SUPABASE_ACCESS_TOKEN']

req = urllib.request.Request(
    f'https://api.supabase.com/v1/projects/{ref}/database/query',
    data=json.dumps({'query': sql}).encode(),
    headers={'Authorization': f'Bearer {tok}', 'Content-Type': 'application/json'},
    method='POST')
try:
    body = urllib.request.urlopen(req, timeout=60).read().decode()
    print('OK' if body == '[]' else body[:800])
except urllib.error.HTTPError as e:
    print('HTTP', e.code, e.read().decode()[:800])
