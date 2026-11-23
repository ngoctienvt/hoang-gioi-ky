// Original vector artwork for Hoang Gioi Ky. Run: node tools/generate-ui-icons.cjs [--assign]
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'assets/ui/icons');
fs.mkdirSync(output, { recursive: true });
const shapes = {
  wood: '<path d="M18 59 58 22 77 38 37 77Z" fill="{c}"/><path d="m27 59 34-29m-23 37 30-28"/><ellipse cx="29" cy="68" rx="11" ry="8" transform="rotate(42 29 68)" fill="#c3a572"/><path d="m26 65 6 6"/>',
  twig: '<path d="m26 77 36-57m-18 29-20-7m31-10 2-19m-17 45 23-7" fill="none" stroke="{c}" stroke-width="9"/><path d="m26 77 36-57" stroke="#e5c28a" stroke-width="2"/>',
  grass: '<path d="M47 79Q18 55 22 21q22 15 24 38Q39 25 61 14q9 30-7 49 10-28 26-29-3 32-25 45Z" fill="{c}"/><path d="m46 76-13-37m20 36 9-43" fill="none" stroke="#d3d09a"/>',
  stone: '<path d="m15 61 12-30 32-12 22 30-8 25-39 5Z" fill="{c}"/><path d="m27 31 20 24 34-6M47 55l-13 24" fill="none"/><path d="m32 33 24-9 11 16-20 7Z" fill="#ddd2b0" stroke="none" opacity=".35"/>',
  crystal: '<path d="m28 62 6-31 20-19 17 28-8 35-20 8Z" fill="{c}"/><path d="m54 12-7 42-4 29m4-29 24-14M34 31l13 23-19 8" fill="none" stroke="#deead5"/><path d="m69 64 7-10 8 14-9 12Z" fill="{c}"/>',
  axe: '<path d="m27 81 36-61" stroke="#aa8558" stroke-width="10"/><path d="m47 22 19-6 16 24-29 14-13-14Z" fill="{c}"/><path d="m65 18 13 21-23 12" fill="none" stroke="#e8dfc3"/><path d="m48 40 12 7m-15-1 12 7" stroke="#cbb98b"/>',
  pickaxe: '<path d="m28 82 31-60" stroke="#aa8558" stroke-width="10"/><path d="M16 33Q48 5 82 35L58 28 40 31Z" fill="{c}"/><path d="m45 28 14 7" stroke="#d6c49c"/>',
  shovel: '<path d="m28 79 25-43" stroke="#a88554" stroke-width="9"/><path d="m41 35 20-20 20 13-5 26-24 8Z" fill="{c}"/><path d="m55 41 14-17" stroke="#e4dab9"/>',
  hammer: '<path d="m27 80 31-56" stroke="#aa8558" stroke-width="10"/><path d="m34 21 16-10 34 23-15 22-36-22Z" fill="{c}"/><path d="m39 23 31 21" stroke="#d7cda9"/>',
  spear: '<path d="m20 82 44-52" stroke="#a88554" stroke-width="7"/><path d="m55 34 19-22 6 30-22 17-9-9Z" fill="{c}"/><path d="m60 45 14-33" stroke="#e0ddbd"/><path d="m47 51 13 9m-17-4 13 9" stroke="#d1bd8e"/>',
  sword: '<path d="m24 80 16-22" stroke="#a88554" stroke-width="9"/><path d="m39 54 7-18 28-23 2 23-28 28Z" fill="{c}"/><path d="m31 53 23 16" stroke="#bfa569"/>',
  torch: '<path d="m36 82 15-42" stroke="#a88554" stroke-width="13"/><path d="M39 50C10 32 48 29 48 9c23 14 32 36 12 48Z" fill="#d48646"/><path d="M44 49q-1-13 12-20 11 15-4 24Z" fill="#f5d38a" stroke="none"/>',
  fire: '<path d="m19 78 58-21m-54 3 54 19" stroke="#9b7950" stroke-width="10"/><path d="M35 64C8 42 44 32 48 9c31 27 41 46 13 57Z" fill="#cc7447"/><path d="M43 62q-10-14 10-29 17 20-1 31Z" fill="#f0ce7a" stroke="none"/>',
  rope: '<path d="M67 29C41 7 14 32 24 58S77 83 77 50 33 23 36 48s30 13 24-1" fill="none" stroke="{c}" stroke-width="11"/><path d="m24 47 11-4m-6 20 8-8m10 15 2-11m19 3-9-7m9-19-8 8" stroke="#edddb3" stroke-width="2"/>',
  fruit: '<path d="M48 30c-35-14-39 32-18 47 11 9 17 0 23 2 29 4 39-50 12-51Z" fill="{c}"/><path d="M48 32q-8-14 4-20m-1 15q9-23 26-9-12 17-26 9" fill="#8c9f64"/><path d="M27 44q-5 12 3 20" stroke="#f0d4aa" stroke-width="4" fill="none"/>',
  mushroom: '<path d="m39 49-5 29q13 9 28-2l-5-28" fill="#d3c19a"/><path d="M13 50C19 7 75 7 83 50q-34 15-70 0Z" fill="{c}"/><path d="M26 42q15-29 41-8" stroke="#dfc9a4" fill="none"/><path d="m43 59 6 15" stroke="#9b855f"/>',
  root: '<path d="M48 36Q12 51 27 76q16 15 24-3l17-34Z" fill="{c}"/><path d="m28 74-7 12m27-17 12 3M48 38Q23 20 38 14l17 20q-3-25 13-22l-6 25" fill="#879565"/><path d="m33 51 12 5m-15 5 11 4"/>',
  meat: '<path d="M22 63C7 37 38 17 62 25s27 32 7 45-35 13-47-7Z" fill="{c}"/><path d="M28 59C16 40 40 27 58 33s21 23 4 31-25 8-34-5Z" fill="#d3937c"/><ellipse cx="54" cy="48" rx="10" ry="8" fill="#e5d9b5"/>',
  fish: '<path d="m15 48 15-20 16 12q23-22 38 8-15 30-38 8L30 68Z" fill="{c}"/><path d="m52 38 1 20"/><circle cx="71" cy="46" r="3" fill="#1e2422"/>',
  bowl: '<path d="M16 48q3 31 32 33 30-2 33-33Z" fill="{c}"/><ellipse cx="48" cy="47" rx="33" ry="12" fill="#b99d67"/><path d="m30 44 9-5 11 10 13-8 7 6" fill="#859e63"/><path d="M33 28q-8-7 1-15m17 17q10-9 0-18m16 18q-8-7 1-15" fill="none" stroke="#b9c2ab"/>',
  pill: '<path d="m28 61 3-26h34l5 26q4 18-20 20-27 0-22-20Z" fill="{c}"/><path d="M36 35V21h23v14" fill="#bda776"/><path d="m33 16 28 0 0 7-28 0Z" fill="#90744e"/><path d="m48 43 12 15-12 15-12-15Z" fill="#e2d2a6"/><path d="m48 50 0 15m-5-7h10" stroke="{c}"/>',
  water: '<path d="M35 14h26v14l11 16v27q-24 16-48 0V44l11-16Z" fill="#8baca0"/><path d="M26 50q22 8 44 0v20q-22 13-44 0Z" fill="{c}"/><path d="M35 14h26v9H35Z" fill="#ab8d5d"/><path d="m36 40-4 8v16" stroke="#e4e7ce" fill="none"/>',
  feather: '<path d="M22 80q-3-48 51-66 18 42-32 58Z" fill="{c}"/><path d="m20 84 47-60m-27 40-9-16m20 2 19-3m-8-8-3-14" fill="none" stroke="#ddcfaa"/>',
  fur: '<path d="m24 15 17 15h14l17-15 10 19-14 16 8 28-25-7-23 9 2-30-16-17Z" fill="{c}"/><path d="m34 40 4 21m11-25-1 24m12-19-3 21" stroke="#d7c39a" fill="none"/>',
  armor: '<path d="m31 18 17 10 17-10 19 24-15 10-6 28H32l-6-28-13-10Z" fill="{c}"/><path d="m37 26 11 14 12-14M48 40v36M30 53h35m-34 9h33" fill="none" stroke="#c2b383"/>',
  hat: '<path d="m29 53 8-28 24-3 9 30" fill="{c}"/><ellipse cx="48" cy="57" rx="36" ry="15" fill="{c}"/><path d="m33 43 31-1m-31 12 32-2" stroke="#e0cf9e"/>',
  fang: '<path d="M25 19q11 48 46 57-15-24-15-58Z" fill="{c}"/><path d="M34 26q3 22 17 34" fill="none" stroke="#eae0bd"/>',
  lotus: '<path d="M48 73Q7 66 14 40q22-1 34 21-29-26-14-43 14 6 14 28 0-26 16-28 14 19-6 41 12-20 25-18 0 31-35 32Z" fill="{c}"/><path d="M48 70V39M30 48l18 22 19-22" fill="none" stroke="#e5d8bd"/>',
  talisman: '<path d="m29 12 39 7-9 65-39-7Z" fill="#d5bf83"/><path d="m34 23 20 3-12 13 16 2-22 17 17 2-11 13m1-42 6 36" fill="none" stroke="{c}" stroke-width="4"/>',
  paper: '<path d="m23 15 45 4 8 61-50-6Z" fill="{c}"/><path d="m32 31 25 2m-24 10 28 2m-27 10 20 2" stroke="#937c57"/>',
  chest: '<path d="m16 38 16-19h36l13 19v38H16Z" fill="{c}"/><path d="M17 45h63M32 20v56m34-56v56" stroke="#d2b477"/><path d="M42 40h14v19H42Z" fill="#c3aa6d"/><circle cx="49" cy="48" r="3"/>',
  furnace: '<path d="m29 80 3-17q-20-16-7-38h46q14 23-7 38l3 17Z" fill="{c}"/><path d="M22 24h52M36 17h24M39 10h18" stroke="#bdab78" stroke-width="5"/><path d="M36 48q0-15 14-19 17 17 8 27H38Z" fill="#d59452"/>',
  pot: '<path d="M25 31q-16 0-14 17h14m46-17q16 0 14 17H71M25 28v34q3 20 23 20 23 0 25-20V28Z" fill="{c}"/><path d="M21 28h56M34 20h28m-18-8h11" stroke="#c3b188" stroke-width="5"/>',
  bench: '<path d="m20 45 2 36m50-36 3 36" stroke="#94784e" stroke-width="9"/><path d="m12 36 18-13 54 11-9 17Z" fill="{c}"/><path d="m32 22 1 20m18-17 0 19m-19 18h43" stroke="#d2bb85"/>',
  altar: '<path d="m18 71 14-12V30l16-19 17 19v29l14 12v10H18Z" fill="{c}"/><path d="m48 28 11 15-11 15-11-15Z" fill="#8cbcac"/><path d="M28 69h40m-36-9h32" stroke="#c4b48a"/>',
  cage: '<path d="M19 33 32 17h32l14 16v45H19Z" fill="{c}"/><path d="M20 34h57M32 22v54m16-57v56m15-53v54M20 64h56" stroke="#ccb98c"/>',
  puppet: '<path d="M34 15h29l5 22-20 9-20-9Z" fill="{c}"/><path d="M33 47h30l7 21-22 12-23-12Z" fill="{c}"/><path d="m25 46-10 22m56-22 11 22m-45 5-9 12m29-12 9 12" stroke="#a38e65" stroke-width="7"/><path d="m37 28 7 3m9 0 7-3" stroke="#91d0b8" stroke-width="4"/>',
  gear: '<path d="m38 13 20 0 3 12 13-2 9 16-9 10 7 12-12 14-13-5-10 11-17-7 1-14-14-4-1-20 15-4Z" fill="{c}"/><circle cx="49" cy="47" r="15" fill="#252f2c"/><circle cx="49" cy="47" r="7" fill="#8fb5a2"/>',
  seed: '<path d="M25 74q-5-28 17-35 15 22-6 38Zm28 1Q42 49 64 33q24 23 4 42Z" fill="{c}"/><path d="M46 39q-16-27-25-14 5 17 25 14 2-28 22-23-1 20-22 23Z" fill="#88a16b"/>',
  egg: '<path d="M25 61q1-30 23-47 22 17 23 47 0 21-23 21T25 61Z" fill="{c}"/><path d="m35 43 5-10m-7 25 3 5" stroke="#e9dcb5" stroke-width="4"/>',
  essence: '<path d="M48 12q-2 22 20 34 21 32-12 37-40 5-34-24 2-10 12-20-1 24 9 16 9-7 5-43Z" fill="{c}"/><path d="M42 73q-14-12 6-24 19 16 5 24Z" fill="#d4dfb9"/>',
  heart: '<path d="M48 77 17 47C-1 17 38 9 48 31 63 7 96 24 80 48Z" fill="{c}"/><path d="m24 42 12 0 7-10 9 26 7-14h14" fill="none" stroke="#eed9b4"/>',
  eye: '<path d="M10 49Q47 6 86 49 48 91 10 49Z" fill="{c}"/><circle cx="48" cy="49" r="16" fill="#1b2926"/><path d="m48 35 6 14-6 14-6-14Z" fill="#d9ddb1"/>',
  book: '<path d="M48 25Q30 14 12 23v52q19-8 36 2 18-10 36-2V23Q65 14 48 25Z" fill="{c}"/><path d="M48 26v50m-26-40 16 2m-16 11 16 2m20-13 16-2m-16 15 16-2" stroke="#ead9b1"/>',
  beast: '<path d="m20 39 2-25 24 17 24-17 4 25 9 19-20 23H34L14 58Z" fill="{c}"/><path d="m27 47 13 5m16 0 13-5m-28 14 8 9 9-9" stroke="#e6d4aa" stroke-width="4"/>',
};
const groups = {
 wood:'wood hard_wood damp_wood frost_wood bamboo', twig:'twig twig_bush stake incense', grass:'grass reed herb soul_herb thunder_herb snow_moss volt_moss ancient_vine',
 stone:'stone flint gravel basalt carved_stone mud_clump ash charcoal resin ruin_shard dark_iron_ore cinnabar',
 crystal:'spirit_stone quartz rune_crystal thunder_crystal charged_thunder_crystal magma_crystal yin_soul_crystal ice_block eternal_ice snowball',
 axe:'flint_axe', pickaxe:'flint_pickaxe spirit_pickaxe', shovel:'shovel', hammer:'hammer', spear:'spear dark_iron_spear lightning_rod', sword:'broken_sword', torch:'torch soul_lantern',
 fire:'campfire firepit', rope:'rope', fruit:'spirit_fruit mutant_fruit ancient_fruit fire_berry berry_bush roasted_fruit pinecone',
 mushroom:'mushroom glow_mushroom ruin_mushroom roasted_mushroom', root:'wild_root water_root roasted_root steamed_roots',
 meat:'meat small_meat roasted_meat charred_food spoiled_food', fish:'ice_fish', bowl:'fruit_salad fruit_soup mushroom_stew spirit_feast detox_soup',
 water:'water_bottle plain_water spirit_water spirit_water_co_van spirit_water_huyen_bang spirit_water_loi_tri spirit_water_thanh_moc spirit_water_u_minh spirit_water_xich_viem',
 feather:'feather crow_feather fire_feather', fur:'fur monkey_fur thick_fur thunder_fur ice_wolf_pelt', armor:'grass_armor dark_iron_armor fur_coat cool_vest', hat:'straw_hat fur_hat', fang:'fang lava_scale',
 lotus:'snow_lotus fire_lotus', paper:'talisman_paper', chest:'chest talisman_chest ice_cellar', furnace:'alchemy_furnace alchemy_furnace_t2 refining_forge', pot:'cooking_pot hand_warmer',
 bench:'workbench talisman_desk farm', altar:'resurrection_altar awakening_altar guest_altar light_pillar water_array ice_structure', cage:'beast_cage filled_beast_cage',
 puppet:'puppet_chop puppet_mine puppet_haul', gear:'ancient_gear ancient_golem_core', seed:'seed spirit_rice_seed spirit_rice frost_rice', egg:'fire_egg',
 essence:'monster_core monster_core_low monster_core_mid monster_core_high minor_blood_essence heart_demon_essence ghost_general_core wraith_essence',
};
const byId = Object.fromEntries(Object.entries(groups).flatMap(([family, ids]) => ids.split(' ').map(id => [id, family])));
const ui = { health:'heart', stamina:'grass', dao:'essence', tools:'axe', light:'torch', survival:'grass', combat:'spear', buildings:'bench', talismans:'talisman', puppets:'puppet', book:'book', beast:'beast', sense:'eye', hand:'spear', body:'armor', head:'hat' };
function color(id, family) {
 if (/fire|magma|blood|health|warm/.test(id)) return '#b86a50';
 if (/ice|frost|snow|cool|huyen_bang/.test(id)) return '#9bb9bd';
 if (/thunder|volt|loi_tri/.test(id)) return '#b7a66a';
 if (/ghost|wraith|soul|yin|demon|u_minh|night/.test(id)) return '#9e8fad';
 if (/spirit|rune|dao|jade|thanh_moc|antidote/.test(id)) return '#79ad94';
 if (/dark_iron|basalt|char|ash|spoiled/.test(id)) return '#77796f';
 return ({grass:'#8c9c66', fruit:'#c6a563', mushroom:'#b88469', wood:'#a08760', twig:'#a08760', rope:'#bfa777', meat:'#ad7064', pill:'#8aa58b', feather:'#c7bca0', essence:'#87ab98', talisman:'#a35f49'})[family] || '#aba88b';
}
function svg(id, family) {
 const rank = /full_|_high|_t2/.test(id) ? 3 : /mid_|charged_/.test(id) ? 2 : /minor_|_low/.test(id) ? 1 : 0;
 const marks = Array.from({length:rank}, (_, i) => `<path d="m${35+i*12} 87 3-3 3 3-3 3Z" fill="#ead7a1" stroke="none"/>`).join('');
 return `<svg xmlns="http://www.w3.org/2000/svg" width="96" height="96" viewBox="0 0 96 96"><g stroke="#252b24" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">${shapes[family].replaceAll('{c}', color(id, family))}${marks}</g></svg>\n`;
}
const manifest = { version:1, dimensions:[96,96], background:'transparent', source:'Original code-authored SVG by Codex for Hoang Giới Ký, 2026-11-23; no third-party artwork.', license:'Project-owned original artwork; no external attribution required.', concept_is_ai_generated:true, runtime_is_ai_raster:false, assets:[] };
for (const filename of fs.readdirSync(path.join(root, 'data/items')).filter(x => x.endsWith('.tres'))) {
 const target = path.join(root, 'data/items', filename);
 let data = fs.readFileSync(target, 'utf8');
 const id = data.match(/^id = &"([^"]+)"/m)?.[1];
 if (!id) throw new Error(`Missing item id: ${filename}`);
 const family = byId[id] || (id.endsWith('_pill') ? 'pill' : id.endsWith('_talisman') ? 'talisman' : null);
 if (!family) throw new Error(`No intentional icon family for ${id}`);
 const asset = `assets/ui/icons/${id.replaceAll('_','-')}.svg`;
 fs.writeFileSync(path.join(root, asset), svg(id, family));
 manifest.assets.push({id, family, file:asset, technical_checks_passed:false, visual_approval:'pending-in-game'});
 if (process.argv.includes('--assign')) {
  if (!data.includes('id="ui_icon"')) {
   data = data.replace(/load_steps=(\d+)/, (_, n) => `load_steps=${Number(n)+1}`);
   data = data.replace('[resource]', `[ext_resource type="Texture2D" path="res://${asset}" id="ui_icon"]\n\n[resource]`);
   data = data.replace(/^script = ExtResource\("1"\)/m, '$&\nicon = ExtResource("ui_icon")');
   fs.writeFileSync(target, data);
  }
 }
}
for (const [id, family] of Object.entries(ui)) {
 const file = `assets/ui/icons/ui-${id}.svg`;
 fs.writeFileSync(path.join(root, file), svg(id, family));
 manifest.assets.push({id:`ui-${id}`,family,file,technical_checks_passed:false,visual_approval:'pending-in-game'});
}
fs.writeFileSync(path.join(root,'assets/ui/asset-manifest.json'), JSON.stringify(manifest,null,2)+'\n');
const cards = manifest.assets.map(a => `<article><img src="../../${a.file}" alt="${a.id}"><span>${a.id}</span></article>`).join('');
fs.writeFileSync(path.join(root,'plans/reports/ui-icons-261123-1548.html'), `<!doctype html><meta charset="utf-8"><title>Hoang Giới Ký · UI Icons</title><style>body{margin:32px;background:#171f1d;color:#e8dcbb;font:15px system-ui}h1{font-weight:500}p{color:#b6bba6}.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(120px,1fr));gap:12px}article{background:#29322b;border:1px solid #8b754c;padding:12px 4px;display:grid;justify-items:center;gap:8px}img{width:64px;height:64px}span{font-size:11px;text-align:center;overflow-wrap:anywhere}article:hover{background:#ece0c0;color:#252b24}</style><h1>HOANG GIỚI KÝ · Biểu tượng hoang cổ</h1><p>SVG 96 × 96 · nền trong suốt · hiển thị ở 64px · rê chuột để kiểm tra trên nền sáng. Các biến thể cùng họ chia sẻ hình khối.</p><main class="grid">${cards}</main>`);
console.log(`[UIAssets] Generated ${manifest.assets.length} icons; ${process.argv.includes('--assign')?'assigned ItemDef resources':'assets only'}.`);
