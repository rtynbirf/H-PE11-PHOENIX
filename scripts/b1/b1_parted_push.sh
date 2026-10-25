#!/bin/bash
# Партионный пуш блобов: 5 веток-партий, затем финальное дерево в main.
set -e
TOKEN=$(cat /home/z/my-project/.gh_token | tr -d '\r\n')
URL="https://x-access-token:${TOKEN}@github.com/rtynbirf/H-PE11-PHOENIX.git"
W=/home/z/my-project/b1/gitwork
cd "$W"
BATCH=21
TOTAL=103

# полный список записей (103 чанка; манифест добавится в финале)
python3 - <<'EOF' > all_lines.txt
import json
m = json.load(open('/home/z/my-project/b1/ISO_MANIFEST.json'))
repo_dir = m.get('repo_dir', 'artifacts/iso_26100.1_pro_ru')
for p in m['parts']:
    print(f"100644 blob {p['blob_sha1']}\t{repo_dir}/{p['name']}")
EOF

PREV=""
i=0; part=1
while [ $i -lt $TOTAL ]; do
  git read-tree FETCH_HEAD
  head -n $((i + BATCH)) all_lines.txt | git update-index --index-info
  TREE=$(git write-tree)
  if [ -z "$PREV" ]; then
    COMMIT=$(git commit-tree "$TREE" -m "PHOENIX11: ISO upload part $part (blobs on server) [Task 40]")
  else
    COMMIT=$(git commit-tree "$TREE" -p "$PREV" -m "PHOENIX11: ISO upload part $part (blobs on server) [Task 40]")
  fi
  echo "part $part: tree=${TREE:0:10} commit=${COMMIT:0:10} (строк $((i + BATCH)))"
  git push "$URL" "$COMMIT:refs/heads/iso_tmp_$part" 2>&1 | tail -1
  PREV=$COMMIT
  i=$((i + BATCH)); part=$((part + 1))
done
echo "LAST_COMMIT=$PREV" > /home/z/my-project/b1/last_part_commit.txt
echo "ALL_PARTS_PUSHED"
