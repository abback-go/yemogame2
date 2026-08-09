/* 신전 수련장 맵 — CI 검증 래퍼
 *
 * 실제 검증 로직은 proto/index.html 안의 runTests()에 있다(사지방 PC에서도
 * 브라우저만으로 T키를 눌러 돌릴 수 있게 하기 위함). 이 스크립트는 헤드리스로
 * 그 함수를 호출해 결과를 종료코드로 바꿔주는 얇은 래퍼일 뿐이다.
 *
 * 사용: node verify-map.mjs        (playwright 필요)
 *      브라우저에서: index.html 열고 T
 */
import { chromium } from "playwright";
import { pathToFileURL } from "node:url";
import { resolve, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const page_url = pathToFileURL(resolve(here, "index.html")).href;

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || "/opt/pw-browsers/chromium",
});
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const errors = [];
page.on("pageerror", (e) => errors.push("PAGEERROR: " + e.message));
page.on("console", (m) => { if (m.type() === "error") errors.push("CONSOLE: " + m.text()); });

await page.goto(page_url);
await page.waitForFunction(() => !!window.__MAP__, { timeout: 10000 });
await page.waitForTimeout(400);

const r = await page.evaluate(() => {
  const M = window.__MAP__;
  /* ★ FX(타격감 레이어)는 순수 시각 레이어라는 계약이다(index.html 10.55 계약 1·3).
     계약이 깨지면 실주행 하네스(도달 실측·층 경계 이탈)의 결과가 FX 유무로 갈린다.
     그래서 **양쪽에서 돌려 결과가 완전히 같은지**까지 검사한다. */
  const tests = (M.FX.enabled = true,  M.runTests());
  const fxOff = (M.FX.enabled = false, M.runTests());
  M.FX.enabled = true;
  return {
    tests,
    fxOff: fxOff.map((t) => ({ n: t.n, ok: t.ok, d: t.d })),
    reach: M.REACH,
    counts: {
      floors: M.FLOORS.length, geo: M.WORLD_GEO.length, spearFaces: M.SPEAR_FACES.length,
      hazards: M.HAZARDS.length, checkpoints: M.CHECKPOINTS.length, portals: M.PORTALS.length,
      targets: M.TARGETS.length, collectibles: M.COLLECTIBLES.length, plans: M.PLANS.length,
    },
    world: M.WORLD,
    audit: { free: M.auditGates().free.length, razor: M.auditGates().razor.length },
  };
});

// 전 층 렌더 스윕 (렌더 예외 검출)
for (let n = 1; n <= r.counts.floors; n++) {
  await page.evaluate((k) => window.__MAP__.focusFloor(k), n);
  await page.waitForTimeout(220);
}
await page.evaluate(() => window.__MAP__.overview());
await page.waitForTimeout(350);
for (const k of ["l", "k", "g", "p", "h", "t"]) { await page.keyboard.press(k); await page.waitForTimeout(120); }
await page.evaluate(() => { window.__MAP__.cam.tzoom = 6; });  await page.waitForTimeout(300);
await page.evaluate(() => { window.__MAP__.cam.tzoom = 200; }); await page.waitForTimeout(300);

await browser.close();

const pass = r.tests.filter((t) => t.ok).length;
const fxPass = r.fxOff.filter((t) => t.ok).length;
const fxSame = JSON.stringify(r.tests.map((t) => [t.n, t.ok, t.d])) ===
               JSON.stringify(r.fxOff.map((t) => [t.n, t.ok, t.d]));
console.log("world", JSON.stringify(r.world));
console.log("counts", JSON.stringify(r.counts));
console.log("reach", Object.fromEntries(Object.entries(r.reach).map(([k, v]) => [k, +v.toFixed(3)])));
console.log(`audit: free ${r.audit.free} / razor ${r.audit.razor}`);
console.log("");
for (const t of r.tests) console.log(`  ${t.ok ? "PASS" : "FAIL"}  ${t.n}${t.d ? "  | " + t.d : ""}`);
console.log(`\n${pass}/${r.tests.length} passed`);
console.log(`FX OFF 재실행: ${fxPass}/${r.fxOff.length} passed · 결과 ${fxSame ? "완전 동일" : "★불일치"}`);
if (!fxSame)
  for (let i = 0; i < r.tests.length; i++)
    if (r.tests[i].ok !== r.fxOff[i].ok || r.tests[i].d !== r.fxOff[i].d)
      console.log(`  DIFF ${r.tests[i].n}\n    ON  ${r.tests[i].ok} ${r.tests[i].d}\n    OFF ${r.fxOff[i].ok} ${r.fxOff[i].d}`);
if (errors.length) { console.log("\nruntime errors:"); errors.forEach((e) => console.log("  " + e)); }

process.exit(pass === r.tests.length && fxPass === r.fxOff.length && fxSame && errors.length === 0 ? 0 : 1);
