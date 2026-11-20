// Procedural tomato plant. 1 scene unit = 10 cm.
// The plant is rebuilt from a small "growth" record (height, leaves, trusses, fruits, ripeness, wilt, vigor),
// so the same code draws the live plants and the growth preview.
import * as THREE from 'three';

const STAGES = [[0, 'Seedling'], [14, 'Vegetative growth'], [25, 'Flowering'],
                [40, 'Fruit set'], [60, 'Ripening'], [80, 'Harvest']];
export const STAGE_NAMES = STAGES.map(s => s[1]);

// Same formula as growth_estimate() in app/server/controller.py
export function growthAt(dat, vigor = 1, soil = 85) {
  const v = 0.55 + 0.45 * vigor;
  const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
  return {
    stage: STAGES.filter(s => dat >= s[0]).pop()[1],
    height_cm: +((10 + 115 * (1 - Math.exp(-dat / 35))) * v).toFixed(1),
    leaves: Math.floor(Math.min(26, 4 + dat * 0.55) * (0.7 + 0.3 * vigor)),
    trusses: dat >= 25 ? clamp(Math.floor((dat - 25) / 7) + 1, 0, 5) : 0,
    fruits: dat >= 40 ? Math.floor(clamp((dat - 40) * 0.7, 0, 14) * v) : 0,
    ripeness: +clamp((dat - 60) / 20, 0, 1).toFixed(2),
    wilt: +clamp((70 - soil) / 40, 0, 1).toFixed(2),
    vigor,
  };
}

function rng(seed) {
  let s = seed >>> 0;
  return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; };
}

// ---- shared geometry / materials ---------------------------------------------------------
function leafletGeometry() {
  const s = new THREE.Shape();
  s.moveTo(0, 0);
  s.bezierCurveTo(0.2, 0.36, 0.72, 0.32, 1, 0);
  s.bezierCurveTo(0.72, -0.32, 0.2, -0.36, 0, 0);
  const g = new THREE.ShapeGeometry(s, 6);
  g.rotateX(-Math.PI / 2);
  g.computeVertexNormals();          // normals must agree with the triangle winding for double-sided lighting
  return g;
}
const LEAFLET = leafletGeometry();
const SPHERE = new THREE.SphereGeometry(1, 14, 10);
const RACHIS = new THREE.CylinderGeometry(0.5, 1, 1, 5).rotateZ(-Math.PI / 2).translate(0.5, 0, 0);

const mat = (color, extra = {}) => new THREE.MeshStandardMaterial({ color, roughness: 0.75, ...extra });
const M = {
  stem: mat(0x4f8a3c),
  stake: mat(0xc9a56a),
  flower: mat(0xf2d21f, { emissive: 0x4a3d00 }),
  sick: mat(0xa8873a, { side: THREE.DoubleSide }),
  calyx: mat(0x3d7a32),
};
const leafMats = new Map();
function leafMaterial(vigor, shade) {
  const key = `${Math.round(vigor * 10)}_${shade}`;
  if (!leafMats.has(key)) {
    const healthy = new THREE.Color([0x2f7d3a, 0x3a8c40, 0x286f35][shade]);
    const tired = new THREE.Color(0xa7a53c);
    const c = healthy.lerp(tired, (1 - vigor) * 0.85);
    // a little self-light stands in for light shining through the leaf, so undersides are not black
    leafMats.set(key, mat(c, { side: THREE.DoubleSide, emissive: c.clone().multiplyScalar(0.2) }));
  }
  return leafMats.get(key);
}
const fruitMats = new Map();
function fruitMaterial(r) {
  const key = Math.round(r * 10);
  if (!fruitMats.has(key)) {
    const c = r < 0.5
      ? new THREE.Color(0x6aa53c).lerp(new THREE.Color(0xe9a02c), r * 2)
      : new THREE.Color(0xe9a02c).lerp(new THREE.Color(0xd0271d), (r - 0.5) * 2);
    fruitMats.set(key, mat(c, { roughness: 0.35 }));
  }
  return fruitMats.get(key);
}

function compoundLeaf(len, material, rand) {
  const g = new THREE.Group();
  const rachis = new THREE.Mesh(RACHIS, M.stem);
  rachis.scale.set(len, 0.035, 0.035);
  g.add(rachis);
  const add = (x, yaw, size) => {
    const m = new THREE.Mesh(LEAFLET, material);
    m.position.set(x, 0, 0);
    m.rotation.set((rand() - 0.5) * 1.1, yaw, -0.12 - rand() * 0.25);
    m.scale.setScalar(size);
    m.castShadow = true;
    g.add(m);
  };
  add(len * 0.9, 0, len * 0.62);                                   // terminal leaflet
  const pairs = len > 1.1 ? 3 : 2;
  for (let p = 0; p < pairs; p++) {
    const x = len * (0.3 + 0.52 * p / pairs);
    const size = len * (0.52 - 0.05 * p);
    add(x, 1.05, size);
    add(x, -1.05, size);
  }
  return g;
}

export function buildPlant(g, seed = 1, opts = {}) {
  const rand = rng(seed * 7919 + 13);
  const plant = new THREE.Group();
  const h = Math.max(0.8, g.height_cm / 10);
  const wilt = g.wilt || 0, vigor = g.vigor ?? 1;

  // Stem: a gentle curve; a wilting plant leans a little
  const pts = [];
  const lean = wilt * 0.12;
  for (let i = 0; i <= 5; i++) {
    const t = i / 5;
    pts.push(new THREE.Vector3((rand() - 0.5) * 0.12 * h * t + lean * h * t * t, h * t, (rand() - 0.5) * 0.12 * h * t));
  }
  const curve = new THREE.CatmullRomCurve3(pts);
  const stem = new THREE.Mesh(new THREE.TubeGeometry(curve, 14, 0.05 + h * 0.011, 6), M.stem);
  stem.castShadow = true;
  stem.userData.own = true;
  plant.add(stem);

  if (h > 2.2) {                                                    // support stake once it is tall
    const sh = h + 0.8;
    const stake = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, sh, 5), M.stake);
    stake.position.set(-0.22, sh / 2, 0.12);
    stake.userData.own = true;
    plant.add(stake);
  }

  // Leaves, golden-angle spiral up the stem
  const n = Math.max(2, g.leaves);
  const baseLen = Math.min(2.7, 0.6 + h * 0.21);
  const sick = new Set();
  if (opts.anomaly) [0.35, 0.5, 0.62].forEach(f => sick.add(Math.floor(n * f)));
  for (let i = 0; i < n; i++) {
    const t = n === 1 ? 0.5 : i / (n - 1);
    const len = baseLen * (0.42 + 0.58 * Math.sin(Math.PI * Math.min(1, (1 - t) * 1.1 + 0.08)));
    const material = sick.has(i) ? M.sick : leafMaterial(vigor, i % 3);
    const leaf = compoundLeaf(len, material, rand);
    const p = curve.getPoint(0.1 + 0.88 * t);
    const holder = new THREE.Group();
    holder.position.copy(p);
    holder.rotation.y = i * 2.39996 + rand() * 0.4;
    leaf.rotation.z = 0.5 - t * 0.15 - wilt * 1.25 - (sick.has(i) ? 0.35 : 0);   // droop when thirsty
    holder.add(leaf);
    plant.add(holder);
  }

  // Trusses: flowers first, then fruits (lowest trusses fruit and ripen first)
  let fruitsLeft = g.fruits;
  for (let k = 0; k < g.trusses; k++) {
    const p = curve.getPoint(Math.min(0.9, 0.28 + 0.13 * k));
    const holder = new THREE.Group();
    holder.position.copy(p);
    holder.rotation.y = k * 2.1 + 0.8;
    const arm = new THREE.Mesh(RACHIS, M.stem);
    arm.scale.set(0.55, 0.03, 0.03);
    arm.rotation.z = -0.5;
    holder.add(arm);
    const here = Math.min(fruitsLeft, 3);
    fruitsLeft -= here;
    if (here > 0) {
      const ripe = Math.max(0, Math.min(1, g.ripeness * 1.7 - k * 0.22));
      const size = 0.15 + 0.2 * Math.min(1, g.fruits / 9) * (1 - k * 0.08);
      for (let f = 0; f < here; f++) {
        const fr = new THREE.Mesh(SPHERE, fruitMaterial(ripe));
        fr.scale.set(size, size * 0.9, size);
        fr.position.set(0.42 + (f % 2) * 0.22, -0.3 - f * size * 0.9, (f - 1) * size * 0.9);
        fr.castShadow = true;
        holder.add(fr);
        const cal = new THREE.Mesh(SPHERE, M.calyx);
        cal.scale.set(size * 0.5, size * 0.18, size * 0.5);
        cal.position.copy(fr.position).y += size * 0.85;
        holder.add(cal);
      }
    } else {
      for (let f = 0; f < 4; f++) {
        const fl = new THREE.Mesh(SPHERE, M.flower);
        fl.scale.set(0.085, 0.05, 0.085);
        fl.position.set(0.4 + (f % 2) * 0.16, -0.26 - (f >> 1) * 0.14, (f - 1.5) * 0.09);
        holder.add(fl);
      }
    }
    plant.add(holder);
  }
  plant.userData.height = h;
  return plant;
}

export function disposePlant(plant) {
  plant.traverse(o => { if (o.userData.own && o.geometry) o.geometry.dispose(); });
}

// A key that changes only when the plant should visibly change
export function plantKey(g, anomaly) {
  return [Math.round(g.height_cm / 2), g.leaves, g.trusses, g.fruits,
          Math.round(g.ripeness * 10), Math.round(g.wilt * 8), Math.round(g.vigor * 10), anomaly ? 1 : 0].join('|');
}
