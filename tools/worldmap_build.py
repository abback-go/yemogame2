#!/usr/bin/env python3
"""월드맵 빌드 파이프라인: 검증 → 병합 → godot 데이터 / 기획 문서 / HTML 지도 생성.

사용: python3 tools/worldmap_build.py [--check-only]
"""
import json, os, sys, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REG_DIR = os.path.join(ROOT, 'docs', 'world', 'regions')
REGION_ORDER = ['sch','gon','cyn','min','for','mir','lig','bel','sky','old','spr','tid','sun','kni','kil','mkt','roa']

REGION_COLORS = {
  'sch':'#e8c66a','gon':'#d99a5b','cyn':'#8a93a6','min':'#c2a06a','for':'#7a6fb8',
  'mir':'#f0d9a0','lig':'#b78ae0','bel':'#9fd8e8','sky':'#8ecff0','old':'#a9b7a0',
  'spr':'#e8a9a0','tid':'#6fb8b0','sun':'#5f9fd0','kni':'#c05f5f','kil':'#e07a50',
  'mkt':'#c9a7e8','roa':'#a08f7a',
}
# 월드 배치: 각 지역 박스의 좌상단(셀 단위). x: 서→동, y: 하늘→심부
ORIGINS = {
  'sky': (20, 0),  'lig': (31, 9),  'bel': (46, 10),
  'old': (27, 17), 'sch': (10, 15), 'spr': (29, 24), 'tid': (37, 21),
  'kni': (3, 10),  'mir': (0, 17),  'roa': (0, 31),  'cyn': (23, 26),
  'gon': (15, 28), 'mkt': (46, 32), 'sun': (38, 30),
  'min': (12, 37), 'kil': (14, 51), 'for': (27, 38),
}
CELL = 30

TECH_STAGES = [
  [],  # 0단계: 시작 킷(대시·부유)만
  ['이단점프'],
  ['벽달리기'],
  ['얼음 발판'],
  ['활공'],
  ['물잠'],
  ['비행'],
]
# 상태/열쇠의 해금 출처: 그 방에 도달하면 해당 게이트가 열린다
UNLOCK_SOURCES = {
  '상태:서쪽 다리 개통': 'kni_hall',
  '상태:수문 개방': 'mir_waterway_gate',
  '상태:광산 심장 안정': 'min_heart',
  '상태:언 갱도 개통': 'bel_adit_south',
  '상태:등불나무 개화': 'for_lantern_boss',
  '상태:직통 승강기': 'mir_furnace_heart',
  '상태:폭풍 잠잠': 'lig_storm_eye',
  '상태:종탑의 결말': 'bel_bell_tower',
  '상태:바람의 인정': 'sky_summit',
  '상태:권양기 수리': 'min_vein_camp',
  '상태:남문 개방': 'mir_shadow_alley',
  '상태:달시장 터·거울': 'mir_moon_site',
  '상태:달시장 터·조수': 'tid_moon_site',
  '열쇠:거인의 자장가': 'min_camp',
  '열쇠:씨앗 램프': 'for_village',
  '열쇠:태양로 인장': 'mir_bureau',
  '열쇠:목장주의 허가': 'lig_village',
  '열쇠:종지기의 장갑': 'bel_sign_school',
  '열쇠:세 사당의 예': 'sky_wind_shrine',
  '열쇠:사서의 신뢰': 'sch_lib_gate',
}
FREE_GATES = {'none', '비밀', '상태:썰물', '상태:보름밤', '기초:불', '기초:물', '기초:바람'}
START_ROOM = 'sch_dorm_room'

def load():
    regions = {}
    for rid in REGION_ORDER:
        p = os.path.join(REG_DIR, rid + '.json')
        with open(p, encoding='utf-8') as f:
            regions[rid] = json.load(f)
    return regions

def validate(regions):
    errs, warns = [], []
    rooms = {}
    for rid, reg in regions.items():
        for r in reg['rooms']:
            if r['id'] in rooms:
                errs.append(f"중복 방 id: {r['id']}")
            rooms[r['id']] = dict(r, region=rid)
    # 이름 중복
    names = {}
    for r in rooms.values():
        names.setdefault(r['name_kr'], []).append(r['id'])
    for n, ids in names.items():
        if len(ids) > 1:
            warns.append(f"이름 중복 '{n}': {', '.join(ids)}")
    # 좌표 충돌 (지역 내)
    for rid, reg in regions.items():
        seen = {}
        for r in reg['rooms']:
            key = (r['gx'], r['gy'])
            if key in seen:
                errs.append(f"[{rid}] 좌표 충돌 {key}: {seen[key]} / {r['id']}")
            seen[key] = r['id']
    # exit 대상 존재 + 왕복 기재
    for r in rooms.values():
        for e in r['exits']:
            t = e['to']
            if t not in rooms:
                errs.append(f"{r['id']} → 존재하지 않는 방 {t}")
                continue
            if e.get('oneway'):
                continue
            back = [x for x in rooms[t]['exits'] if x['to'] == r['id']]
            if not back:
                errs.append(f"왕복 누락: {r['id']} → {t} (역방향 없음, oneway 아님)")
    # 게이트 어휘 점검
    known_gates = set(FREE_GATES) | set(UNLOCK_SOURCES) | {g for st in TECH_STAGES for g in st}
    for r in rooms.values():
        for e in r['exits']:
            if e['gate'] not in known_gates:
                errs.append(f"미정의 게이트 '{e['gate']}' @ {r['id']} → {e['to']}")
    # 보스 앞 거점
    for rid, reg in regions.items():
        for r in reg['rooms']:
            if r['type'] == 'boss':
                nbr_bench = False
                for e in r['exits']:
                    t = rooms.get(e['to'])
                    if t and ('bench' in t.get('flags', [])):
                        nbr_bench = True
                for other in rooms.values():
                    if any(e['to'] == r['id'] for e in other['exits']) and 'bench' in other.get('flags', []):
                        nbr_bench = True
                if not nbr_bench:
                    errs.append(f"[{rid}] 보스 {r['id']} 인접 거점 없음")
    # 막다른 방 보상 (soft)
    for r in rooms.values():
        deg = len(r['exits']) + sum(1 for o in rooms.values() for e in o['exits'] if e['to'] == r['id'] and e.get('oneway'))
        if len(r['exits']) == 1 and r['type'] in ('field', 'transit', 'hub'):
            warns.append(f"막다른 일반 방(보상 확인 필요): {r['id']} ({r['name_kr']})")
    return rooms, errs, warns

def bfs_progression(rooms):
    """이동술 단계별 도달 가능 집합. 반환: [(stage, newly, total)], unreachable, room_stage"""
    report = []
    reach = set()
    techs = set()
    unlocked = set()
    room_stage = {}
    def expand():
        frontier = [START_ROOM] if START_ROOM not in reach else list(reach)
        if START_ROOM not in reach:
            reach.add(START_ROOM)
        changed = True
        while changed:
            changed = False
            # 상태/열쇠 해금
            for gate, src in UNLOCK_SOURCES.items():
                if gate not in unlocked and src in reach:
                    unlocked.add(gate); changed = True
            for r_id in list(reach):
                for e in rooms[r_id]['exits']:
                    g = e['gate']
                    ok = g in FREE_GATES or g in techs or g in unlocked
                    if ok and e['to'] not in reach:
                        reach.add(e['to']); changed = True
    for stage, new_techs in enumerate(TECH_STAGES):
        for t in new_techs:
            techs.add(t)
        before = len(reach)
        expand()
        for rid in reach:
            room_stage.setdefault(rid, stage)
        report.append((stage, len(reach) - before, len(reach)))
    unreachable = [r for r in rooms if r not in reach]
    return report, unreachable, room_stage

def world_pos(regions):
    pos = {}
    for rid, reg in regions.items():
        ox, oy = ORIGINS[rid]
        min_gx = min(r['gx'] for r in reg['rooms'])
        min_gy = min(r['gy'] for r in reg['rooms'])
        for r in reg['rooms']:
            pos[r['id']] = ((ox + r['gx'] - min_gx) * CELL, (oy + r['gy'] - min_gy) * CELL)
    return pos

def region_bounds(regions, pos):
    b = {}
    for rid, reg in regions.items():
        xs = [pos[r['id']][0] for r in reg['rooms']]
        ys = [pos[r['id']][1] for r in reg['rooms']]
        b[rid] = (min(xs), min(ys), max(xs), max(ys))
    return b

def check_overlaps(bounds):
    warns = []
    ids = list(bounds)
    for i in range(len(ids)):
        for j in range(i + 1, len(ids)):
            a, c = bounds[ids[i]], bounds[ids[j]]
            pad = CELL
            if a[0] < c[2] + pad and a[2] + pad > c[0] and a[1] < c[3] + pad and a[3] + pad > c[1]:
                warns.append(f"지역 박스 겹침: {ids[i]} ↔ {ids[j]}")
    return warns

def main():
    regions = load()
    rooms, errs, warns = validate(regions)
    report, unreachable, room_stage = bfs_progression(rooms)
    pos = world_pos(regions)
    bounds = region_bounds(regions, pos)
    overlap = check_overlaps(bounds)

    print(f"지역 {len(regions)}개 / 방 {len(rooms)}개")
    for s, new, tot in report:
        label = '+'.join(TECH_STAGES[s]) or '시작 킷'
        print(f"  단계 {s} ({label}): +{new} → 누적 {tot}")
    if unreachable:
        errs.append(f"도달 불가 방 {len(unreachable)}개: {', '.join(unreachable[:12])}...")
    for w in overlap: print('겹침 경고:', w)
    if warns:
        print('\n-- 경고 --')
        for w in warns: print(' ⚠', w)
    if errs:
        print('\n-- 오류 --')
        for e in errs: print(' ✗', e)
        sys.exit(1)
    print('\n검증 통과 ✅')
    if '--check-only' in sys.argv:
        return

    # ---------- godot/data/world_map.json ----------
    out = {
        'meta': {'title': '대협곡 세계 — 월드맵 v1', 'room_total': len(rooms),
                 'tech_order': [t for st in TECH_STAGES for t in st]},
        'regions': [], 'rooms': [],
    }
    for rid in REGION_ORDER:
        reg = regions[rid]
        out['regions'].append({
            'id': rid, 'name': reg['name_kr'], 'element': reg['element'],
            'identity': reg['identity'], 'palette': reg['palette'], 'music': reg['music'],
            'color': REGION_COLORS[rid], 'region_magic': reg['region_magic'],
            'boss_key_story': reg['boss_key_story'], 'state_change': reg['region_state_change'],
            'unique_enemy': reg['unique_enemy'], 'local_loops': reg['local_loops'],
            'bounds': bounds[rid],
        })
        for r in reg['rooms']:
            x, y = pos[r['id']]
            out['rooms'].append({
                'id': r['id'], 'region': rid, 'name': r['name_kr'], 'concept': r['concept'],
                'type': r['type'], 'subzone': r.get('subzone', ''), 'size': r['size'],
                'flags': r.get('flags', []), 'x': x, 'y': y,
                'stage': room_stage.get(r['id'], 6),
                'exits': r['exits'],
            })
    # 간선(중복 제거) — 뷰어용
    edge_seen = set()
    edges = []
    for r in rooms.values():
        for e in r['exits']:
            key = tuple(sorted([r['id'], e['to']]))
            oneway = bool(e.get('oneway'))
            if key in edge_seen and not oneway:
                continue
            edge_seen.add(key)
            edges.append({'a': r['id'], 'b': e['to'], 'gate': e['gate'],
                          'oneway': oneway,
                          'cross': rooms[e['to']]['region'] != r['region']})
    out['edges'] = edges
    out['meta']['stage_report'] = [
        {'stage': s, 'techs': TECH_STAGES[s], 'new': new, 'total': tot} for s, new, tot in report]
    gd_path = os.path.join(ROOT, 'godot', 'data', 'world_map.json')
    os.makedirs(os.path.dirname(gd_path), exist_ok=True)
    with open(gd_path, 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print('생성:', os.path.relpath(gd_path, ROOT))

    # ---------- docs/world-map.md ----------
    md = []
    md.append('# 월드맵 마스터 문서 — 대협곡 세계\n')
    md.append('> 생성원: `docs/world/overview.md`(원칙 — 손으로 관리) + `docs/world/regions/*.json`(지역별 원본) → `tools/worldmap_build.py`가 검증·병합.')
    md.append('> 수정은 원본에서 하고 스크립트를 다시 돌릴 것. 이 문서와 `godot/data/world_map.json`은 산출물.\n')
    ov_path = os.path.join(ROOT, 'docs', 'world', 'overview.md')
    if os.path.isfile(ov_path):
        with open(ov_path, encoding='utf-8') as f:
            md.append(f.read())
        md.append('\n---\n')
    md.append(f"**규모: {len(regions)}개 지역 / {len(rooms)}방** (기획서 §5.7 예산 185~260의 최대 확장판 — 컷 라인: 종의 계곡 24방 + 비밀 일부)\n")
    md.append('## 진행 단계별 개방 (검증 결과)\n')
    md.append('| 단계 | 해금 이동술 | 새로 열림 | 누적 도달 |')
    md.append('|---|---|---|---|')
    for s, new, tot in report:
        md.append(f"| {s} | {'+'.join(TECH_STAGES[s]) or '시작 킷(대시·부유)'} | +{new} | {tot} |")
    md.append('')
    md.append('## 지역별 상세\n')
    for rid in REGION_ORDER:
        reg = regions[rid]
        md.append(f"### {reg['name_kr']} (`{rid}`) — {len(reg['rooms'])}방")
        md.append(f"- **정체성**: {reg['identity']}")
        md.append(f"- **속성**: {reg['element']} / **팔레트**: {reg['palette']} / **음악**: {reg['music']}")
        md.append(f"- **고유 적**: {reg['unique_enemy']}")
        if reg['region_magic']:
            md.append('- **지역 마법**: ' + ', '.join(f"{m['name']} — {m['effect']}" for m in reg['region_magic']))
        md.append(f"- **보스 열쇠(로컬 스토리)**: {reg['boss_key_story']}")
        md.append(f"- **클리어 후 변화**: {reg['region_state_change']}")
        for lp in reg['local_loops']:
            md.append(f"- 루프: {lp}")
        md.append('')
        md.append('| id | 방 | 유형 | 구획 | 컨셉 | 연결 |')
        md.append('|---|---|---|---|---|---|')
        for r in reg['rooms']:
            exits = '; '.join(
                f"→{e['to']}" + (f"({e['gate']})" if e['gate'] != 'none' else '') + ('[일방]' if e.get('oneway') else '')
                for e in r['exits'])
            fl = (' `' + ','.join(r['flags']) + '`') if r.get('flags') else ''
            md.append(f"| {r['id']} | **{r['name_kr']}**{fl} | {r['type']} | {r.get('subzone','')} | {r['concept']} | {exits} |")
        md.append('')
    md_path = os.path.join(ROOT, 'docs', 'world-map.md')
    with open(md_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(md))
    print('생성:', os.path.relpath(md_path, ROOT))

    # ---------- HTML 지도 ----------
    data_js = json.dumps(out, ensure_ascii=False)
    tpl_path = os.path.join(ROOT, 'tools', 'map_template.html')
    with open(tpl_path, encoding='utf-8') as f:
        tpl = f.read()
    html_out = tpl.replace('/*__DATA__*/null', data_js)
    map_path = os.path.join(ROOT, 'docs', 'world', 'map.html')
    with open(map_path, 'w', encoding='utf-8') as f:
        f.write(html_out)
    print('생성:', os.path.relpath(map_path, ROOT))

if __name__ == '__main__':
    main()
