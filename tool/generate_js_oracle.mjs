// Run from this package: node tool/generate_js_oracle.mjs ../taiyin-lite
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { readFileSync, writeFileSync } from 'node:fs';
const root = resolve(process.argv[2] ?? '../taiyin-lite');
const b = await import(pathToFileURL(resolve(root, 'packages/bazi/dist/index.js')));
const e = await import(pathToFileURL(resolve(root, 'src/index.js')));
const charts = [];
for (const [i, year] of [-500, 0, 500, 1500, 1582, 1900, 2000, 2026, 2099, 3000].entries()) {
  for (const clockMode of ['civil', 'mean-solar', 'true-solar']) {
    for (const ratHourMode of Object.values(e.RAT_HOUR_MODE)) {
      const input = { year, month: 2, day: 19, hour: 23, minute: 30, second: 12.5, offsetMinutes: i % 2 ? 345 : 480 };
      const options = { clockMode, ratHourMode, longitudeDeg: 75, gender: i % 2,
        qiYunTimeModel: i % 3, daYunBoundaryModel: (i + 1) % 3 };
      const chart = b.BaziChart.fromZonedTime(new e.ZonedTime(input), options);
      const q = chart.getQiYun();
      charts.push({ input, options, pillars: chart.pillars, virtualTime: chart.birthCivilTime,
        qiYun: { direction: q.direction, interval: q.jieIntervalDays, start: q.startJdUT1 },
        decades: chart.getDaYunTable().map(d => [d.pillar,d.startVirtualAge,d.endVirtualAge,d.startJdUT1,d.endJdUT1]) });
    }
  }
}
const arbitrary = [];
for (let i=0; i<24; i++) {
  const pillars = Object.fromEntries(['year','month','day','hour'].map((k,j)=>[k,b.packPillar(((i*17+j*13)%60)%10,((i*17+j*13)%60)%12)]));
  const chart=b.analyzePillars(pillars);
  for (const gender of [null,0,1]) {
    const words=[];
    for(let targetKind=0;targetKind<13;targetKind++) for(let p=0;p<60;p++) {
      words.push(String(b.collectTargetShenSha(chart,b.packPillar(p%10,p%12),targetKind,{gender:gender??undefined})));
    }
    arbitrary.push({pillars,gender,words});
  }
}
writeFileSync('test/fixtures/js-parity.json', JSON.stringify({source:'bazi-lite '+JSON.parse(readFileSync(resolve(root,'packages/bazi/package.json'))).version,charts,arbitrary})+'\n');
console.log(`${charts.length} clock/fortune charts; ${arbitrary.length*13*60} target Shen-Sha comparisons`);
