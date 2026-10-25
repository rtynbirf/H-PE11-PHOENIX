#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Продолжение финализации: блобы уже в gitwork/.git/objects — собрать индекс, дерево, коммит, push.
import json, base64, subprocess, sys, hashlib
import urllib.request

TOKEN = open('/home/z/my-project/.gh_token').read().strip()
W = '/home/z/my-project/b1/gitwork'

def sh(args, inp=None):
    data = inp.encode() if isinstance(inp, str) else inp
    r = subprocess.run(args, input=data, capture_output=True, cwd=W)
    if r.returncode != 0:
        print('FAIL:', ' '.join(args), r.stderr.decode()[:300], flush=True)
        sys.exit(1)
    return r.stdout.decode().strip()

m = json.load(open('/home/z/my-project/b1/ISO_MANIFEST.json'))
repo_dir = m.get('repo_dir', 'artifacts/iso_26100.1_pro_ru')
lines = [f"100644 blob {p['blob_sha1']}\t{repo_dir}/{p['name']}" for p in m['parts']]
man_bytes = json.dumps(m, indent=1).encode()
man_sha = sh(['git', 'hash-object', '-w', '--stdin'], inp=man_bytes)
lines.append(f"100644 blob {man_sha}\t{repo_dir}/MANIFEST.json")

sh(['git', 'update-index', '--index-info'], inp='\n'.join(lines) + '\n')
TREE = sh(['git', 'write-tree'])
print('tree:', TREE[:12], flush=True)
PARENT = sh(['git', 'rev-parse', 'FETCH_HEAD'])
msg = ('PHOENIX11: WILLIAM B1 ISO 26100.1_PROFESSIONAL_X64_RU-RU.ISO '
       '(26300.9807 ru-RU Pro, 26H2, uupdump converter v0.7.3, 103 чанка x 40MiB, '
       'sha256 f08f504ee044e83942b79660b773021ebadf66b3d45195f2156237a2a771e1c0) [Task 40]')
COMMIT = sh(['git', 'commit-tree', TREE, '-p', PARENT, '-m', msg])
print('commit:', COMMIT[:12], flush=True)
url = f'https://x-access-token:{TOKEN}@github.com/rtynbirf/H-PE11-PHOENIX.git'
r = subprocess.run(['git', 'push', url, f'{COMMIT}:refs/heads/main'], cwd=W, capture_output=True)
print('push rc:', r.returncode, flush=True)
print(r.stdout.decode()[-200:], r.stderr.decode()[-300:], flush=True)
sys.exit(0 if r.returncode == 0 else 1)
