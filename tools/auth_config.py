import json, os, sys, urllib.request

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
env = {}
for line in open(os.path.join(root, '.env'), encoding='utf-8'):
    line = line.strip()
    if line and not line.startswith('#') and '=' in line:
        k, v = line.split('=', 1)
        env[k] = v

ref, tok = env['SUPABASE_REF'], env['SUPABASE_ACCESS_TOKEN']
payload = None
if len(sys.argv) > 1:
    with open(sys.argv[1], encoding='utf-8') as f:
        payload = f.read()
ratio = json.loads(payload) if payload else None

method = 'PUT' if payload else 'GET'
req = urllib.request.Request(
    f'https://api.supabase.com/v1/projects/{ref}/config/auth',
    data=json.dumps(ratio).encode() if ratio else None,
    headers={'Authorization': f'Bearer {tok}', 'Content-Type': 'application/json'},
    method=method)
try:
    body = urllib.request.urlopen(req, timeout=60).read().decode()
    cfg = json.loads(body)
    keys = ['mailer_autoconfirm', 'mailer_otp_enabled', 'disable_signup',
            'mailer_enable_signups', 'external_email_enabled']
    print(json.dumps({k: cfg.get(k) for k in keys if k in cfg}, indent=1))
except urllib.error.HTTPError as e:
    print('HTTP', e.code, e.read().decode()[:500])
