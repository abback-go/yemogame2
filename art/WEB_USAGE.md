# 웹 게임용 스프라이트 시트 사양

## 파일

| 파일 | 용도 |
|---|---|
| `temple_maiden_sheet.png` | 스프라이트 시트 (864 × 1924, RGBA) |
| `temple_maiden_anim.json` | 프레임 인덱스 · FPS · 루프 정의 |
| `temple_maiden_atlas.json` | TexturePacker JSON Hash — Phaser 3 / PixiJS 아틀라스 |
| `gif/*.gif` | 동작별 프리뷰 |

기존 6동작과 창대쉬 6방향이 **한 장에 통합**되어 있습니다. 셀 크기와 피벗이 하나뿐이라 엔진 설정이 한 번으로 끝납니다.

## 시트 사양

```
frameWidth   144
frameHeight  148
columns      6
rows         13
pivot        x=51, y=110      (셀 좌상단 기준 픽셀)
pivot 정규화  x=0.3542, y=0.7432
```

- 캐릭터 높이 약 96px
- 팔레트 24색 (기존/신규 공통)
- 반투명 픽셀 **0개**
- 셀 경계에 닿는 픽셀 **0개** — 텍스처 블리딩 없음

셀이 커진 이유는 창대쉬입니다. 창이 대각선으로 길게 뻗어서 이전 108×116으로는 잘렸습니다.

## 애니메이션

| 이름 | 인덱스 | 프레임 | FPS | 루프 | 비고 |
|---|---|---|---|---|---|
| idle | 0–5 | 6 | 8 | ○ | |
| walk | 6–9 | 4 | 10 | ○ | |
| jump | 12–16 | 5 | 12 | × | 물리 매핑 권장 |
| attack | 18–21 | 4 | 16 | × | 휘두르기 |
| dash | 24–27 | 4 | 18 | × | 지상 대시 |
| hurt | 30–35 | 6 | 10 | × | |
| **run** | **36–38** | **3** | **15** | **○** | **기본 이동** |
| charge | 42–44 | 3 | 14 | × | 창대쉬 체공 충전 |
| sdash_right | 48–49 | 2 | 20 | × | 수평 → |
| sdash_upright | 54–55 | 2 | 20 | × | 대각 ↗ |
| sdash_downright | 60–61 | 2 | 20 | × | 대각 ↘ |
| sdash_up | 66–67 | 2 | 20 | × | 수직 ↑ |
| sdash_down | 72–73 | 2 | 20 | × | 수직 ↓ |

인덱스는 `row × 6 + col` 기준입니다. 빈 셀이 번호를 차지하므로 위 표의 값을 그대로 쓰세요. 아틀라스를 쓰면 `idle_00`, `sdash_up_01` 같은 이름으로 접근하고 빈 프레임이 없습니다.

## 창대쉬 상태 전이

```
공중에서 입력 → charge (36→38, 약 0.2초 정지)
              → 방향 확정 시 해당 sdash 행 재생
              → 돌진 종료 후 jump 낙하 프레임 또는 idle
```

`charge` 3프레임은 **제자리에 멈춘 상태**입니다. 재생 중 중력을 0으로 두세요. 안 그러면 그림은 정지인데 캐릭터가 떨어져서 어긋납니다.

왼쪽 방향은 좌우 반전으로 만듭니다. `sdash_upright`를 반전하면 ↖, `sdash_downright`를 반전하면 ↙가 됩니다. **상하 반전은 쓰지 마세요** — 캐릭터가 거꾸로 보입니다. ↑와 ↓는 별도 행으로 있습니다.

## Phaser 3

```js
// 아틀라스 방식 (권장 — 빈 프레임 없음)
this.load.atlas('maiden', 'temple_maiden_sheet.png', 'temple_maiden_atlas.json');

this.anims.create({ key: 'idle',
  frames: this.anims.generateFrameNames('maiden',
    { prefix: 'idle_', start: 0, end: 5, zeroPad: 2 }),
  frameRate: 8, repeat: -1 });

this.anims.create({ key: 'charge',
  frames: this.anims.generateFrameNames('maiden',
    { prefix: 'charge_', start: 0, end: 2, zeroPad: 2 }),
  frameRate: 14, repeat: 0 });

// 격자 방식
this.load.spritesheet('maiden', 'temple_maiden_sheet.png',
  { frameWidth: 144, frameHeight: 148 });
this.anims.create({ key: 'sdash_up',
  frames: this.anims.generateFrameNumbers('maiden', { start: 66, end: 67 }),
  frameRate: 20, repeat: 0 });
```

픽셀 보간 끄기 — 안 하면 도트가 뭉개집니다.

```js
const game = new Phaser.Game({ pixelArt: true, /* ... */ });
sprite.setOrigin(0.3542, 0.7432);
```

## Canvas 2D

```js
ctx.imageSmoothingEnabled = false;

const FW = 144, FH = 148, COLS = 6;
const PIVX = 51, PIVY = 110;

function drawFrame(ctx, img, index, x, y, scale = 1, flip = false) {
  const sx = (index % COLS) * FW;
  const sy = Math.floor(index / COLS) * FH;
  ctx.save();
  ctx.translate(x, y);
  if (flip) ctx.scale(-1, 1);
  ctx.drawImage(img, sx, sy, FW, FH,
                -PIVX * scale, -PIVY * scale, FW * scale, FH * scale);
  ctx.restore();
}
```

`scale`은 정수배(2, 3, 4)만 쓰세요. 소수 배율은 픽셀 폭이 불균등해집니다.

## 점프

프레임 순차 재생 대신 `velocity.y`에 매핑하세요.

```js
let f;
if      (vy < -4) f = 14;   // RISING
else if (vy <  1) f = 15;   // 정점 부근
else              f = 16;   // FALLING
```

## 이펙트

시트에 잔상·속도선·빛·충전 게이지가 없습니다. 의도된 것입니다.

- 공격 이펙트 → `attack` 20번 프레임 타이밍
- 창대쉬 잔상 → 이전 프레임을 알파 낮춰 겹쳐 그리기
- 충전 게이지 → `charge` 재생 시간에 맞춰 코드로

이렇게 해야 무기 강화·속성 변화를 스프라이트 재작업 없이 처리할 수 있습니다.

## 정렬 검증 결과

| 행 | 몸통 중심 편차 x / y | 셀 경계 침범 |
|---|---|---|
| idle | 1.2 / 0.6 | 0 |
| walk | 3.5 / 3.1 | 0 |
| jump | 12.4 / 21.4 | 0 |
| run | 2.3 / 21.4 | 0 |
| attack | 1.9 / 6.1 | 0 |
| dash | 21.1 / 5.1 | 0 |
| hurt | 11.8 / 17.6 | 0 |
| charge | 0.2 / 0.2 | 0 |
| sdash_* | 0.1~1.8 / 0.4~1.2 | 0 |

jump·dash·hurt의 큰 편차는 동작 자체가 몸을 크게 움직이기 때문이며 정상입니다. 발 기준선은 전부 정렬되어 있습니다.

## 알려진 한계

- **walk 4프레임** — 원본 6프레임 중 2개가 중복이라 제외
- **jump 5프레임** — 정점 자세 1개가 의상 누락으로 제외
- **dash 4프레임** — 뒤 2개가 중복·미완성이라 제외
- **찌르기 공격 미생성** — 휘두르기 한 종류만
- 창대쉬는 오른쪽 기준만 있음 (좌측은 반전으로 생성)
