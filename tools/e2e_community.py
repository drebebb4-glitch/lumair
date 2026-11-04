import json, os, urllib.request, urllib.error

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
env = {}
for line in open(os.path.join(root, '.env'), encoding='utf-8'):
    line = line.strip()
    if line and not line.startswith('#') and '=' in line:
        k, v = line.split('=', 1)
        env[k] = v

URL = env['SUPABASE_URL']
ANON = env['SUPABASE_ANON_KEY']
SECRET = env['SUPABASE_SECRET_KEY']
EMAIL, PASS = 'lumair_e2e_3712@gmail.com', 'E2eTest123'
ok = True


def call(path, body=None, token=None, key=ANON, method='POST'):
    d = json.dumps(body).encode() if body is not None else None
    h = {'apikey': key, 'Content-Type': 'application/json'}
    if token:
        h['Authorization'] = f'Bearer {token}'
    req = urllib.request.Request(URL + path, data=d, headers=h, method=method)
    try:
        r = urllib.request.urlopen(req, timeout=30)
        raw = r.read().decode()
        return r.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read().decode()
        return e.code, (json.loads(raw) if raw else {})


s, r = call('/auth/v1/signup', {'email': EMAIL, 'password': PASS})
uid = r.get('user', {}).get('id')
seg = r.get('access_token', '')
print('1 signup:', s, '| session ada:', bool(seg), '| uid:', str(uid)[:8], '...')
ok &= s == 200 and bool(seg)

s, r = call('/rest/v1/reports', {
    'jenis': 'banjir', 'kota': 'Jakarta', 'deskripsi': 'E2E test - genangan 30cm',
    'lat': -6.2, 'lon': 106.82, 'penulis': 'E2E Tester', 'user_id': uid}, token=seg, method='POST')
print('2 insert laporan (RLS):', s, json.dumps(r)[:120] if s >= 400 else '(ok)')
ok &= s == 201

s, r = call('/rest/v1/reports?select=jenis,kota,deskripsi,penulis&limit=5', token=seg, method='GET')
print('3 baca laporan:', s, json.dumps(r)[:200])
ok &= s == 200 and len(r) >= 1

# cleanup: hapus akun test (laporan ikut terhapus, cascade)
if uid:
    s, _ = call(f'/auth/v1/admin/users/{uid}', token=SECRET, key=SECRET, method='DELETE')
    print('4 cleanup akun test:', s)
    ok &= s == 200

print('E2E KESIMPULAN:', 'SEMUA JALAN' if ok else 'ADA YANG GAGAL')
