// 3D greenhouse. 1 unit = 10 cm. Everything is procedural (no model files to download).
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { buildPlant, disposePlant, plantKey } from './plant.js';

const POTS = [new THREE.Vector3(-3.1, 0, 0.2), new THREE.Vector3(1.3, 0, 0.2)];
const TANK = new THREE.Vector3(5.1, 0, -2.2);
const BOX = new THREE.Vector3(5.2, 0, 2.2);
const W = 7, D = 4.5, WALL = 11, RIDGE = 14;                 // greenhouse half-width, half-depth, heights
const CAM_HOME = new THREE.Vector3(15, 12, 25), CAM_TARGET = new THREE.Vector3(0, 5.6, 0);
const DOOR_X0 = -4.5, DOOR_X1 = -2.1, DOOR_H = 7.2;            // RFID door in the front wall (z = +D)
const READER = new THREE.Vector3(-1.45, 3.6, 4.5 + 0.42);       // RC522 reader, outside, right of the door
const TRACKER = new THREE.Vector3(9.7, -0.62, 0.6);            // solar tracker stand, outside on the ground
const PANEL_MAX = 60 * Math.PI / 180;                           // servo travel: 30°..150° around 90°
const LDR_TILT = 25 * Math.PI / 180;                            // each LDR faces 25° off the panel normal

const std = (color, o = {}) => new THREE.MeshStandardMaterial({ color, roughness: 0.8, ...o });
const lerp = (a, b, t) => a + (b - a) * t;

function makeRenderer(canvas) {
  const r = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false, preserveDrawingBuffer: true });
  r.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  r.toneMapping = THREE.ACESFilmicToneMapping;
  r.shadowMap.enabled = true;
  r.shadowMap.type = THREE.PCFSoftShadowMap;
  return r;
}

function makePot() {
  const g = new THREE.Group();
  const pot = new THREE.Mesh(new THREE.CylinderGeometry(1.05, 0.78, 1.5, 24, 1, true), std(0xb5623c, { side: THREE.DoubleSide }));
  pot.position.y = 0.75; pot.castShadow = true; pot.receiveShadow = true;
  const rim = new THREE.Mesh(new THREE.TorusGeometry(1.06, 0.07, 8, 24), std(0xa85633));
  rim.rotation.x = Math.PI / 2; rim.position.y = 1.5;
  const base = new THREE.Mesh(new THREE.CircleGeometry(0.78, 24), std(0x8f4a2d));
  base.rotation.x = -Math.PI / 2; base.position.y = 0.02;
  const soil = new THREE.Mesh(new THREE.CircleGeometry(1.0, 24), std(0x5a3d28, { roughness: 1 }));
  soil.rotation.x = -Math.PI / 2; soil.position.y = 1.36; soil.receiveShadow = true;
  const probe = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.9, 0.04), std(0x1d1f22));
  probe.position.set(0.62, 1.7, 0.3);
  const head = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.2, 0.08), std(0x2b4f9c));
  head.position.set(0.62, 2.2, 0.3);
  g.add(pot, rim, base, soil, probe, head);
  g.userData.soil = soil;
  return g;
}

export class FarmScene {
  constructor(canvas, labelsEl) {
    this.canvas = canvas; this.labelsEl = labelsEl;
    this.renderer = makeRenderer(canvas);
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0xbfe3f2);
    this.scene.fog = new THREE.Fog(0xbfe3f2, 45, 110);
    this.camera = new THREE.PerspectiveCamera(38, 1, 0.5, 200);
    this.camera.position.copy(CAM_HOME);
    this.controls = new OrbitControls(this.camera, canvas);
    Object.assign(this.controls, { enableDamping: true, dampingFactor: 0.08, enablePan: false,
      minDistance: 9, maxDistance: 60, maxPolarAngle: Math.PI * 0.49 });
    this.controls.target.copy(CAM_TARGET);
    this.clock = new THREE.Clock();
    this.active = true;
    this.state = null;
    this.plants = [null, null]; this.plantKeys = ['', ''];
    this.waterUntil = 0; this.lastTotal = null;
    this.fanSpeed = 0; this.sun = 0.8; this.sunTarget = 0.8;
    this.tags = {};
    this.build();
    this.resize();
    new ResizeObserver(() => this.resize()).observe(canvas.parentElement);
    this.renderer.setAnimationLoop(() => this.frame());
  }

  build() {
    const s = this.scene;
    this.hemi = new THREE.HemisphereLight(0xdff1ff, 0x7c8a5a, 1.0);
    this.sunLight = new THREE.DirectionalLight(0xfff1d6, 2.4);
    this.sunLight.castShadow = true;
    this.sunLight.shadow.mapSize.set(1024, 1024);
    Object.assign(this.sunLight.shadow.camera, { left: -13, right: 13, top: 16, bottom: -6, near: 1, far: 70 });
    this.sunLight.shadow.bias = -0.0015;
    s.add(this.hemi, this.sunLight, this.sunLight.target);

    // Ground and wooden bench
    this.ground = new THREE.Mesh(new THREE.CircleGeometry(90, 48), std(0x8fae74, { roughness: 1 }));
    this.ground.rotation.x = -Math.PI / 2; this.ground.position.y = -0.62; this.ground.receiveShadow = true;
    const bench = new THREE.Mesh(new THREE.BoxGeometry(W * 2 + 2.2, 0.6, D * 2 + 2.2), std(0xb99a6b));
    bench.position.y = -0.31; bench.receiveShadow = true;
    s.add(this.ground, bench);

    // Greenhouse: aluminium frame + glass
    const frame = std(0xeef0ea, { roughness: 0.45, metalness: 0.3 });
    const glass = new THREE.MeshStandardMaterial({ color: 0xcfe9f2, transparent: true, opacity: 0.13,
      roughness: 0.05, side: THREE.DoubleSide, depthWrite: false });
    const beam = (a, b, t = 0.2) => {
      const d = new THREE.Vector3().subVectors(b, a);
      const m = new THREE.Mesh(new THREE.BoxGeometry(t, d.length(), t), frame);
      m.position.copy(a).addScaledVector(d, 0.5);
      m.quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), d.normalize());
      m.castShadow = true;
      s.add(m);
    };
    const V = (x, y, z) => new THREE.Vector3(x, y, z);
    for (const x of [-W, W]) for (const z of [-D, D]) beam(V(x, 0, z), V(x, WALL, z));
    for (const z of [-D, D]) {
      beam(V(-W, 0, z), V(W, 0, z)); beam(V(-W, WALL, z), V(W, WALL, z));
      beam(V(-W, WALL, z), V(0, RIDGE, z)); beam(V(W, WALL, z), V(0, RIDGE, z));
      beam(V(0, 0, z), V(0, WALL, z), 0.12);
    }
    for (const x of [-W, W]) { beam(V(x, 0, -D), V(x, 0, D)); beam(V(x, WALL, -D), V(x, WALL, D)); }
    beam(V(0, RIDGE, -D), V(0, RIDGE, D));
    const pane = (w, h, pos, rot) => {
      const m = new THREE.Mesh(new THREE.PlaneGeometry(w, h), glass);
      m.position.copy(pos); m.rotation.set(...rot); m.renderOrder = 5; s.add(m);
    };
    pane(W * 2, WALL, V(0, WALL / 2, -D), [0, 0, 0]);
    // Front wall: glass around the RFID door opening
    pane(DOOR_X0 + W, WALL, V((-W + DOOR_X0) / 2, WALL / 2, D), [0, 0, 0]);
    pane(W - DOOR_X1, WALL, V((DOOR_X1 + W) / 2, WALL / 2, D), [0, 0, 0]);
    pane(DOOR_X1 - DOOR_X0, WALL - DOOR_H, V((DOOR_X0 + DOOR_X1) / 2, (WALL + DOOR_H) / 2, D), [0, 0, 0]);
    pane(D * 2, WALL, V(-W, WALL / 2, 0), [0, Math.PI / 2, 0]);
    pane(D * 2, WALL, V(W, WALL / 2, 0), [0, Math.PI / 2, 0]);
    const slope = Math.hypot(W, RIDGE - WALL), ang = Math.atan2(RIDGE - WALL, W);
    for (const sgn of [-1, 1]) {
      const m = new THREE.Mesh(new THREE.PlaneGeometry(slope, D * 2), glass);
      m.rotation.x = -Math.PI / 2; m.renderOrder = 5;
      const tilt = new THREE.Group();                    // lay the pane flat, then tilt it along the roof
      tilt.position.set(sgn * W / 2, (WALL + RIDGE) / 2, 0);
      tilt.rotation.z = -sgn * ang;
      tilt.add(m); s.add(tilt);
    }
    const floor = new THREE.Mesh(new THREE.PlaneGeometry(W * 2, D * 2), std(0xd8d2c0, { roughness: 1 }));
    floor.rotation.x = -Math.PI / 2; floor.position.y = 0.01; floor.receiveShadow = true;
    s.add(floor);

    // Pots and plants
    this.pots = POTS.map(p => { const pot = makePot(); pot.position.copy(p); s.add(pot); return pot; });

    // Reservoir (clear tank) + water + level sensor
    const tank = new THREE.Mesh(new THREE.BoxGeometry(2.2, 2.6, 2.2),
      new THREE.MeshStandardMaterial({ color: 0xe8f4f8, transparent: true, opacity: 0.22, roughness: 0.1, depthWrite: false }));
    tank.position.copy(TANK).y = 1.3; tank.renderOrder = 6;
    const edges = new THREE.LineSegments(new THREE.EdgesGeometry(tank.geometry), new THREE.LineBasicMaterial({ color: 0x7c8f96 }));
    edges.position.copy(tank.position);
    this.water = new THREE.Mesh(new THREE.BoxGeometry(2.06, 1, 2.06),
      new THREE.MeshStandardMaterial({ color: 0x3b8fd9, transparent: true, opacity: 0.72, roughness: 0.15 }));
    this.water.position.copy(TANK);
    const sonar = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 0.25, 12), std(0x22262b));
    sonar.position.copy(TANK).y = 2.75;
    const pump = new THREE.Mesh(new THREE.BoxGeometry(0.7, 0.55, 0.5), std(0x2c3238));
    pump.position.set(TANK.x - 1.55, 0.28, TANK.z);
    s.add(tank, edges, this.water, sonar, pump);

    // Irrigation tube with one drip nozzle per pot
    this.tubeMat = std(0x2b2f33, { roughness: 0.5 });
    this.nozzles = [];
    for (const p of POTS) {
      const nozzle = V(p.x + 0.45, 2.15, p.z - 0.5);
      const curve = new THREE.CatmullRomCurve3([V(TANK.x - 1.9, 0.3, TANK.z), V(p.x + 2.2, 0.12, p.z - 1.7),
        V(p.x + 1.25, 0.12, p.z - 1.3), V(p.x + 1.15, 1.9, p.z - 1.0), nozzle]);
      const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 30, 0.07, 6), this.tubeMat);
      s.add(tube);
      this.nozzles.push(nozzle);
    }
    this.drops = [];
    const dropGeo = new THREE.SphereGeometry(0.07, 6, 5);
    const dropMat = new THREE.MeshStandardMaterial({ color: 0x4fa3ee, emissive: 0x1b4f85, roughness: 0.2 });
    for (let i = 0; i < 22; i++) {
      const d = new THREE.Mesh(dropGeo, dropMat);
      d.visible = false; d.userData = { pot: i % 2, phase: Math.random() };
      s.add(d); this.drops.push(d);
    }

    // Extraction fan on the back wall
    this.fan = new THREE.Group();
    this.fan.position.set(-3.6, 8.4, -D + 0.12);
    const ring = new THREE.Mesh(new THREE.TorusGeometry(1.25, 0.14, 8, 28), std(0x30363b, { metalness: 0.4 }));
    const backPlate = new THREE.Mesh(new THREE.CircleGeometry(1.25, 24), std(0x9aa3a8, { transparent: true, opacity: 0.35 }));
    this.blades = new THREE.Group();
    for (let i = 0; i < 5; i++) {
      const b = new THREE.Mesh(new THREE.BoxGeometry(0.42, 1.05, 0.05), std(0x4b565c, { metalness: 0.3 }));
      b.position.y = 0.6; b.rotation.y = 0.5;
      const h = new THREE.Group(); h.rotation.z = i * Math.PI * 2 / 5; h.add(b); this.blades.add(h);
    }
    const hub = new THREE.Mesh(new THREE.CylinderGeometry(0.22, 0.22, 0.2, 12).rotateX(Math.PI / 2), std(0x23282c));
    this.fan.add(ring, backPlate, this.blades, hub);
    s.add(this.fan);

    // Sensors of the dossier: DHT22 (shaded wall), BH1750 (light, on top of a post), flame sensor, Arduino bridge
    this.dht = new THREE.Group();
    const dhtBody = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.75, 0.22), std(0xf2f2ee));
    for (let i = 0; i < 4; i++) {
      const slot = new THREE.Mesh(new THREE.BoxGeometry(0.34, 0.05, 0.03), std(0x9aa0a4));
      slot.position.set(0, 0.22 - i * 0.14, 0.12); this.dht.add(slot);
    }
    this.dht.add(dhtBody);
    this.dht.position.set(W - 0.2, 6.4, -1.4); this.dht.rotation.y = -Math.PI / 2;
    const luxPost = new THREE.Mesh(new THREE.CylinderGeometry(0.06, 0.06, 4.6, 6), frame);
    luxPost.position.set(-5.9, 2.3, -3.4);
    this.luxSensor = new THREE.Mesh(new THREE.BoxGeometry(0.55, 0.12, 0.4), std(0x2d5fae));
    this.luxSensor.position.set(-5.9, 4.66, -3.4);
    const luxDome = new THREE.Mesh(new THREE.SphereGeometry(0.11, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), std(0xf4f4f4, { roughness: 0.2 }));
    luxDome.position.set(-5.9, 4.72, -3.4);
    this.flameSensor = new THREE.Group();
    const fsBoard = new THREE.Mesh(new THREE.BoxGeometry(0.6, 0.06, 0.3), std(0x1c4e9c));
    const fsEye = new THREE.Mesh(new THREE.SphereGeometry(0.08, 10, 8), std(0x111111, { roughness: 0.1 }));
    fsEye.position.set(-0.26, 0.06, 0);
    this.flameSensor.add(fsBoard, fsEye);
    this.flameSensor.position.set(BOX.x + 1.25, 2.4, BOX.z + 1.2);
    const fsPost = new THREE.Mesh(new THREE.CylinderGeometry(0.04, 0.04, 2.4, 6), frame);
    fsPost.position.set(BOX.x + 1.25, 1.2, BOX.z + 1.2);
    const arduino = new THREE.Mesh(new THREE.BoxGeometry(0.9, 0.12, 0.62), std(0x0f7c8c));
    arduino.position.set(BOX.x - 0.2, 0.06, BOX.z - 1.15);
    const usb = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([V(BOX.x - 0.2, 0.1, BOX.z - 0.84),
      V(BOX.x - 0.1, 0.25, BOX.z - 0.7), V(BOX.x, 0.5, BOX.z - 0.6)]), 8, 0.035, 5), std(0x222222));
    const probeWire = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([V(BOX.x - 0.6, 0.08, BOX.z - 1.2),
      V(2.8, 0.06, -1.4), V(POTS[1].x + 0.62, 0.06, POTS[1].z - 0.9), V(POTS[1].x + 0.62, 2.25, POTS[1].z + 0.3)]), 30, 0.03, 4), std(0x3b3b3b));
    s.add(this.dht, luxPost, this.luxSensor, luxDome, this.flameSensor, fsPost, arduino, usb, probeWire);

    // Flames (only during a fire alarm): a few flickering cones near the flame sensor
    this.flames = new THREE.Group();
    this.flames.position.set(BOX.x - 2.6, 0, BOX.z + 2.2);
    for (let i = 0; i < 5; i++) {
      const f = new THREE.Mesh(new THREE.ConeGeometry(0.22 + 0.06 * (i % 2), 1.0 + 0.25 * i % 0.8, 10),
        new THREE.MeshBasicMaterial({ color: i % 2 ? 0xffb02e : 0xff4b1f, transparent: true, opacity: 0.85 }));
      f.position.set(Math.cos(i * 1.3) * 0.25, 0.5, Math.sin(i * 1.3) * 0.25);
      this.flames.add(f);
    }
    this.flames.visible = false;
    s.add(this.flames);

    // Control box (Raspberry Pi 3B) + buzzer
    const box = new THREE.Mesh(new THREE.BoxGeometry(1.7, 1.0, 1.2), std(0x2f7a4a));
    box.position.copy(BOX).y = 0.5; box.castShadow = true;
    this.led = new THREE.Mesh(new THREE.SphereGeometry(0.08, 8, 6), new THREE.MeshStandardMaterial({ color: 0x5fd38d, emissive: 0x5fd38d, emissiveIntensity: 2 }));
    this.led.position.set(BOX.x - 0.55, 1.03, BOX.z + 0.35);
    this.buzzer = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.26, 0.22, 16), std(0x16181a));
    this.buzzer.position.set(BOX.x + 0.4, 1.11, BOX.z);
    this.buzzRings = [0, 1].map(() => {
      const r = new THREE.Mesh(new THREE.TorusGeometry(0.4, 0.035, 6, 24),
        new THREE.MeshBasicMaterial({ color: 0xe5392f, transparent: true, opacity: 0 }));
      r.rotation.x = Math.PI / 2; r.position.copy(this.buzzer.position).y += 0.15; s.add(r); return r;
    });
    s.add(box, this.led, this.buzzer);

    // Raspberry Pi Camera module on a post, watching the plants, ribbon cable down to the Pi
    const post = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.07, 7.4, 6), frame);
    post.position.set(-6.2, 3.7, 3.7);
    this.cam = new THREE.Group();
    this.cam.position.set(-6.2, 7.5, 3.7);
    const pcb = new THREE.Mesh(new THREE.BoxGeometry(0.62, 0.6, 0.04), std(0x1f7a3a, { roughness: 0.55 }));
    const holes = [[-1, -1], [-1, 1], [1, -1], [1, 1]].map(([x, y]) => {
      const h = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.035, 0.05, 8).rotateX(Math.PI / 2), std(0xd9c27a, { metalness: 0.6 }));
      h.position.set(x * 0.24, y * 0.23, 0); return h;
    });
    const lensBlock = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.22, 0.12), std(0x16181a));
    lensBlock.position.set(0, 0.06, 0.08);
    const lens = new THREE.Mesh(new THREE.CylinderGeometry(0.075, 0.075, 0.06, 16).rotateX(Math.PI / 2), std(0x05070a, { roughness: 0.05, metalness: 0.5 }));
    lens.position.set(0, 0.06, 0.16);
    const connector = new THREE.Mesh(new THREE.BoxGeometry(0.5, 0.1, 0.07), std(0xe8e2d0));
    connector.position.set(0, -0.26, -0.05);
    this.camLed = new THREE.Mesh(new THREE.SphereGeometry(0.045, 8, 6), new THREE.MeshStandardMaterial({ color: 0x5fd38d, emissive: 0x5fd38d, emissiveIntensity: 2 }));
    this.camLed.position.set(0.21, 0.2, 0.04);
    this.cam.add(pcb, ...holes, lensBlock, lens, connector, this.camLed);
    this.cam.lookAt(-0.9, 4, 0);
    const ribbonMat = std(0xf0eee6, { roughness: 0.6 });
    const ribbon = (pts) => {
      for (let i = 0; i < pts.length - 1; i++) {
        const a = pts[i], b = pts[i + 1], len = a.distanceTo(b);
        const m = new THREE.Mesh(new THREE.BoxGeometry(0.26, 0.012, len), ribbonMat);
        const vertical = Math.abs(b.y - a.y) > 0.9 * len;
        m.matrix.lookAt(a, b, vertical ? V(0, 0, 1) : V(0, 1, 0));
        m.quaternion.setFromRotationMatrix(m.matrix);
        m.position.copy(a).lerp(b, 0.5);
        s.add(m);
      }
    };
    ribbon([V(-6.2, 7.15, 3.6), V(-6.2, 0.03, 3.6), V(BOX.x - 0.4, 0.03, 3.6), V(BOX.x - 0.4, 0.03, BOX.z + 0.62), V(BOX.x - 0.4, 0.7, BOX.z + 0.62)]);
    s.add(post, this.cam);

    // RFID door: wooden frame, glazed leaf hinged on the left, RC522 reader + red/green LED outside
    const wood = std(0x5b4632, { roughness: 0.9 });
    const doorFrame = [[DOOR_X0, DOOR_H / 2, 0.16, DOOR_H], [DOOR_X1, DOOR_H / 2, 0.16, DOOR_H], [(DOOR_X0 + DOOR_X1) / 2, DOOR_H, DOOR_X1 - DOOR_X0 + 0.16, 0.16]];
    for (const [x, y, w, h] of doorFrame) {
      const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, 0.22), wood);
      m.position.set(x, y, D); m.castShadow = true; s.add(m);
    }
    this.door = new THREE.Group();                         // pivot on the hinge side
    this.door.position.set(DOOR_X0 + 0.1, 0, D);
    const leafW = DOOR_X1 - DOOR_X0 - 0.2, leafH = DOOR_H - 0.15;
    const leafGlass = new THREE.Mesh(new THREE.PlaneGeometry(leafW - 0.3, leafH - 0.3), glass);
    leafGlass.position.set(leafW / 2, leafH / 2, 0); leafGlass.renderOrder = 5;
    this.door.add(leafGlass);
    for (const [x, y, w, h] of [[0.07, leafH / 2, 0.14, leafH], [leafW - 0.07, leafH / 2, 0.14, leafH],
      [leafW / 2, 0.07, leafW, 0.14], [leafW / 2, leafH - 0.07, leafW, 0.14], [leafW / 2, leafH * 0.45, leafW, 0.1]]) {
      const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, 0.1), wood);
      m.position.set(x, y, 0); m.castShadow = true; this.door.add(m);
    }
    const handle = new THREE.Mesh(new THREE.BoxGeometry(0.08, 0.5, 0.12), std(0xc9ccd0, { metalness: 0.7, roughness: 0.3 }));
    handle.position.set(leafW - 0.3, 3.4, 0.12);
    this.door.add(handle);
    s.add(this.door);

    const readerPost = new THREE.Mesh(new THREE.BoxGeometry(0.22, READER.y + 0.3, 0.22), wood);
    readerPost.position.set(READER.x, (READER.y + 0.3) / 2, READER.z - 0.16);
    this.reader = new THREE.Group();
    this.reader.position.copy(READER);
    const rBoard = new THREE.Mesh(new THREE.BoxGeometry(0.95, 1.25, 0.05), std(0x1d4fa8, { roughness: 0.5 }));
    const antenna = new THREE.LineSegments(new THREE.EdgesGeometry(new THREE.PlaneGeometry(0.7, 0.62)), new THREE.LineBasicMaterial({ color: 0xc9d8f4 }));
    antenna.position.set(0, 0.22, 0.03);
    const waves = [0.12, 0.2, 0.28].map(r => {
      const m = new THREE.Mesh(new THREE.TorusGeometry(r, 0.012, 4, 20, Math.PI * 0.6), new THREE.MeshBasicMaterial({ color: 0xffffff }));
      m.position.set(0, 0.14, 0.035); m.rotation.z = Math.PI * 0.2; return m;
    });
    const chip = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.22, 0.04), std(0x111316));
    chip.position.set(0.12, -0.36, 0.04);
    const pins = new THREE.Mesh(new THREE.BoxGeometry(0.8, 0.08, 0.1), std(0x1a1a1a));
    pins.position.set(0, -0.56, 0.05);
    this.rfidLed = new THREE.Mesh(new THREE.SphereGeometry(0.075, 10, 8), new THREE.MeshStandardMaterial({ color: 0xe5392f, emissive: 0xe5392f, emissiveIntensity: 1.5 }));
    this.rfidLed.position.set(-0.32, -0.38, 0.06);
    this.reader.add(rBoard, antenna, ...waves, chip, pins, this.rfidLed);
    this.badge = new THREE.Group();                         // blue key fob that flies to the reader on a tap
    const fob = new THREE.Mesh(new THREE.CylinderGeometry(0.26, 0.26, 0.07, 20).rotateX(Math.PI / 2), std(0x2f6fd6, { roughness: 0.4 }));
    const fobTab = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.24, 0.07), fob.material);
    fobTab.position.y = 0.24;
    const fobRing = new THREE.Mesh(new THREE.TorusGeometry(0.13, 0.025, 6, 16), std(0xbfc4c8, { metalness: 0.8 }));
    fobRing.position.y = 0.48;
    this.fobParts = [fob, fobTab, fobRing];
    this.card = new THREE.Mesh(new THREE.BoxGeometry(0.85, 0.54, 0.03), std(0xf4f4f0));   // unknown white card
    this.badge.add(fob, fobTab, fobRing, this.card);
    this.badge.visible = false;
    s.add(readerPost, this.reader, this.badge);
    this.access = { phase: 'idle', t0: 0, ok: true, granted: 0 };
    this.doorAngle = 0;

    // Solar tracker: panel on a servo horn, one LDR on each side, sitting on a black stand outside
    this.tracker = new THREE.Group();
    this.tracker.position.copy(TRACKER);
    const stand = new THREE.Mesh(new THREE.BoxGeometry(2.0, 1.3, 1.6), std(0x1d1f24, { roughness: 0.9 }));
    stand.position.y = 0.65; stand.castShadow = true; stand.receiveShadow = true;
    const servo = new THREE.Mesh(new THREE.BoxGeometry(0.42, 0.85, 0.82), std(0x18191c));
    servo.position.set(0, 1.72, 0);
    const servoLabel = new THREE.Mesh(new THREE.BoxGeometry(0.43, 0.3, 0.5), std(0x2c2f35));
    servoLabel.position.set(0, 1.6, 0);
    const shaft = new THREE.Mesh(new THREE.CylinderGeometry(0.09, 0.09, 0.3, 12).rotateX(Math.PI / 2), std(0xd8d8d8, { metalness: 0.7 }));
    shaft.position.set(0, 2.18, 0.28);
    const servoWire = new THREE.Mesh(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([V(0, 1.4, -0.42), V(0, 1.2, -0.9), V(-0.3, 0.2, -1.2), V(-1.6, -0.05, -1.4)]), 20, 0.04, 5), std(0xd87a1e));
    this.panel = new THREE.Group();                          // rotates about z (sun moves east-west along x)
    this.panel.position.set(0, 2.62, 0.28);
    const cells = new THREE.Mesh(new THREE.BoxGeometry(2.4, 0.07, 1.7), std(0x0d1a2e, { roughness: 0.25, metalness: 0.4 }));
    const grid = [];
    for (let i = -2; i <= 2; i++) grid.push(V(i * 0.48, 0.04, -0.82), V(i * 0.48, 0.04, 0.82));
    for (const z of [-0.42, 0, 0.42]) grid.push(V(-1.17, 0.04, z), V(1.17, 0.04, z));
    const gridLines = new THREE.LineSegments(new THREE.BufferGeometry().setFromPoints(grid), new THREE.LineBasicMaterial({ color: 0x5d6f86 }));
    const rim2 = new THREE.LineSegments(new THREE.EdgesGeometry(cells.geometry), new THREE.LineBasicMaterial({ color: 0xc9cdd2 }));
    this.panel.add(cells, gridLines, rim2);
    this.ldrs = [-1, 1].map(side => {                        // side -1 = left (west-facing), +1 = right
      const g = new THREE.Group();
      g.position.set(side * 1.34, 0.02, 0);
      const base = new THREE.Mesh(new THREE.BoxGeometry(0.26, 0.08, 0.36), std(0x2b2f35));
      const cell = new THREE.Mesh(new THREE.CylinderGeometry(0.1, 0.1, 0.07, 14), std(0xe9a23b, { emissive: 0x000000 }));
      cell.position.y = 0.07; cell.rotation.z = -side * LDR_TILT;
      g.add(base, cell); g.userData.cell = cell;
      this.panel.add(g); return g;
    });
    const horn = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.5, 0.12), std(0xf2f2f2));
    horn.position.set(0, 2.38, 0.36);
    this.tracker.add(stand, servo, servoLabel, shaft, horn, servoWire, this.panel);
    s.add(this.tracker);
    this.panelAngle = -1.0; this.ldrVals = [0, 0];

    // Click / tap the RFID reader (or the door) to badge in
    this.raycaster = new THREE.Raycaster();
    let down = null;
    const canvas = this.canvas;
    canvas.addEventListener('pointerdown', e => { down = [e.clientX, e.clientY]; });
    canvas.addEventListener('pointerup', e => {
      if (!down || Math.hypot(e.clientX - down[0], e.clientY - down[1]) > 6) return;
      const r = canvas.getBoundingClientRect();
      const p = new THREE.Vector2(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
      this.raycaster.setFromCamera(p, this.camera);
      if (this.raycaster.intersectObjects([this.reader, this.door], true).length) this.tapBadge(true);
    });
    this.rfidTag = { el: document.createElement('div'), pos: READER.clone().add(V(0, 0.95, 0)), visible: true, fixed: true };
    this.rfidTag.el.className = 'tag sensor rfid';
    this.rfidTag.el.innerHTML = '<span>RFID RC522</span><button data-ok="1" title="Tap an authorised badge">✓ Badge</button><button data-ok="0" title="Tap an unknown card">✗ Unknown</button>';
    this.rfidTag.el.addEventListener('click', e => { const b = e.target.closest('button'); if (b) this.tapBadge(b.dataset.ok === '1'); });
    this.labelsEl.appendChild(this.rfidTag.el);
    this.tags.rfidChip = this.rfidTag;

    // Fire beacon (only lit during a fire alarm)
    this.beacon = new THREE.PointLight(0xff2a1f, 0, 40, 1.4);
    this.beacon.position.set(0, RIDGE - 1, 0);
    s.add(this.beacon);
  }

  tapBadge(ok) {
    if (this.access.phase !== 'idle') return;
    this.access = { phase: 'approach', t0: this.clock.elapsedTime, ok, granted: this.access.granted };
    this.fobParts.forEach(m => m.visible = ok);
    this.card.visible = !ok;
  }

  tag(id, text, pos, cls = '') {
    let t = this.tags[id];
    if (!t) {
      t = this.tags[id] = { el: document.createElement('div'), pos: new THREE.Vector3() };
      this.labelsEl.appendChild(t.el);
    }
    t.el.className = 'tag ' + cls; t.el.textContent = text; t.pos.copy(pos); t.visible = true;
  }

  update(st) {
    this.state = st;
    const s = st.sensors || {};
    const anomaly = st.vision && st.vision.status === 'leaf_anomaly';
    (st.plants || []).forEach((g, i) => {
      const key = plantKey(g, anomaly && i === 0);
      if (key !== this.plantKeys[i]) {
        if (this.plants[i]) { this.scene.remove(this.plants[i]); disposePlant(this.plants[i]); }
        const p = buildPlant(g, i + 1, { anomaly: anomaly && i === 0 });
        p.position.copy(POTS[i]).y = 1.36;
        this.scene.add(p);
        this.plants[i] = p; this.plantKeys[i] = key;
      }
    });
    // Soil colour (one shared probe): dark when wet, pale when dry
    if (s.soil_pct != null) {
      const t = Math.max(0, Math.min(1, (s.soil_pct - 20) / 70));
      this.pots.forEach(p => p.userData.soil.material.color.setRGB(lerp(0.62, 0.2, t), lerp(0.47, 0.13, t), lerp(0.32, 0.08, t)));
    }
    const lvl = Math.max(0.02, (s.water_level_pct ?? 50) / 100);
    this.water.scale.y = lvl * 2.5; this.water.position.y = 0.04 + lvl * 2.5 / 2;
    const pulses = st.irrigation.pulses_total;                 // a new pulse -> show the drip for a moment
    if (st.actuators.pump || (this.lastTotal !== null && pulses > this.lastTotal)) this.waterUntil = performance.now() + 4000;
    this.lastTotal = pulses;
    this.sunTarget = Math.max(0, Math.min(1, (s.light || 0) / 38000));
    this.hour = s.hour ?? 12;

    // Floating labels
    const V = (x, y, z) => new THREE.Vector3(x, y, z);
    Object.values(this.tags).forEach(t => { if (!t.fixed) t.visible = false; });
    if (s.soil_raw != null) this.tag('pot1', `Soil probe · ${Math.round(s.soil_pct)}% (${Math.round(s.soil_raw)} raw)`, POTS[1].clone().add(V(0.6, 3.0, 0.3)), s.soil_raw > 600 ? 'alert' : '');
    this.tag('pot0', 'Plant A', POTS[0].clone().add(V(0, 0.1, 1.5)), 'quiet');
    this.tag('pot0b', 'Plant B', POTS[1].clone().add(V(0, 0.1, 1.5)), 'quiet');
    this.tag('tank', `Tank ${Math.round(s.water_level_pct ?? 0)}%`, TANK.clone().setY(3.3), st.alarms.tank_low ? 'alert' : '');
    if (s.air_temp != null) this.tag('dht', `DHT22 · ${s.air_temp.toFixed(1)} °C · ${Math.round(s.air_hum)}%`, this.dht.position.clone().add(V(0, 0.8, 0)), 'sensor');
    if (s.light != null) this.tag('lux', `BH1750 · ${s.light >= 1000 ? (s.light / 1000).toFixed(1) + 'k' : Math.round(s.light)} lx`, this.luxSensor.position.clone().add(V(0, 0.5, 0)), 'sensor');
    this.tag('flame', st.alarms.fire ? 'Flame sensor: FIRE' : 'Flame sensor', this.flameSensor.position.clone().add(V(0, 0.45, 0)), st.alarms.fire ? 'alert' : 'sensor');
    this.tag('pi', st.irrigation.locked ? 'Raspberry Pi · pump locked' : 'Raspberry Pi · edge AI', BOX.clone().setY(1.55), st.irrigation.locked ? 'alert' : 'quiet');
    if (st.actuators.fan) this.tag('fan', 'Fan on (tree 2)', this.fan.position.clone().add(V(0, 1.7, 0)), 'on');
    if (performance.now() < this.waterUntil) this.tag('pump', 'Watering · 5 s pulse (tree 1)', POTS[1].clone().add(V(1.6, 4.0, -0.6)), 'on');
    if (st.vision.status === 'fire') this.tag('cam', 'Camera: FIRE', this.cam.position.clone().setY(8.4), 'alert');
    else if (anomaly) this.tag('cam', 'Camera: leaf anomaly', this.cam.position.clone().setY(8.4), 'alert');
    else this.tag('cam', 'Pi Camera · YOLO11n', this.cam.position.clone().setY(8.3), 'quiet');
    if (st.actuators.buzzer) this.tag('buzz', 'Buzzer', BOX.clone().add(V(-1.1, 1.9, 0)), 'alert');
  }

  // Solar tracker, same logic as the Arduino sketch: read both LDRs, step the servo toward the brighter one,
  // hold inside a dead band; at night (both LDRs dark) park facing east, ready for sunrise.
  animateTracker(dt) {
    const sp = this.sunLight.position;
    const sunAng = Math.atan2(-sp.x, sp.y);                       // angle of the sun in the panel's rotation plane
    const read = side => {
      const facing = this.panelAngle - side * LDR_TILT;            // left LDR leans west (+), right leans east (-)
      return Math.round(30 + 990 * this.sun * Math.max(0, Math.cos(sunAng - facing)));
    };
    const L = read(-1), R = read(1);
    this.ldrVals = [L, R];
    const speed = 0.7 * dt;                                       // ~40°/s servo slew
    if (Math.max(L, R) < 120) this.panelAngle += Math.sign(-1.0 - this.panelAngle) * Math.min(speed * 0.4, Math.abs(-1.0 - this.panelAngle));
    else if (Math.abs(L - R) > 12) this.panelAngle += Math.sign(L - R) * speed;
    this.panelAngle = Math.max(-PANEL_MAX, Math.min(PANEL_MAX, this.panelAngle));
    this.panel.rotation.z = this.panelAngle;
    this.ldrs.forEach((g, i) => g.userData.cell.material.emissive.setRGB(([L, R][i] / 1023) * 0.6, ([L, R][i] / 1023) * 0.35, 0));
    const servoDeg = Math.round(90 + this.panelAngle * 180 / Math.PI);
    this.tag('solar', `Solar tracker · servo ${servoDeg}° · LDR L ${L} / R ${R}`, TRACKER.clone().add(new THREE.Vector3(0, 4.1, 0)), 'sensor');
    this.tags.solar.fixed = true;
  }

  // RFID access: the badge flies to the reader, the RC522 reads it, the LED turns green and the door opens
  // for 4 s (authorised) or the LED blinks red (unknown card).
  animateDoor(t) {
    const a = this.access, k = t - a.t0, far = READER.clone().add(new THREE.Vector3(0.4, -0.3, 2.6)), near = READER.clone().setZ(READER.z + 0.22);
    let ledOn = false, ledGreen = false, open = 0;
    if (a.phase !== 'idle') {
      this.badge.visible = k < 2.0;
      const f = k < 0.6 ? k / 0.6 : k < 1.2 ? 1 : Math.max(0, 1 - (k - 1.2) / 0.8);
      this.badge.position.copy(far).lerp(near, f * f * (3 - 2 * f));
      this.badge.rotation.set(0, 0, Math.sin(k * 3) * 0.15);
      if (k >= 0.6) {
        if (a.ok) { ledGreen = true; ledOn = k < 6.6; open = k < 1.6 ? (k - 0.6) : k < 5.6 ? 1 : Math.max(0, 1 - (k - 5.6)); }
        else ledOn = k < 2.4 && Math.floor((k - 0.6) * 6) % 2 === 0;
      }
      if (a.ok && k >= 0.6 && a.phase === 'approach') { a.phase = 'granted'; a.granted++; }
      if (a.phase === 'approach' && k >= 0.6) a.phase = 'denied';
      if (k > (a.ok ? 6.8 : 2.6)) a.phase = 'idle';
    }
    if (a.phase === 'idle') this.badge.visible = false;
    this.door.rotation.y = -1.35 * open * open * (3 - 2 * open);
    const c = ledGreen && ledOn ? 0x34c759 : 0xe5392f;
    this.rfidLed.material.color.setHex(c); this.rfidLed.material.emissive.setHex(c);
    this.rfidLed.material.emissiveIntensity = ledOn ? 3 : (ledGreen ? 1.5 : 1.2);
    const state = a.phase === 'granted' ? ['Access granted · door open', 'on'] : a.phase === 'denied' ? ['Unknown card · access denied', 'alert'] : null;
    if (state) { this.tag('door', state[0], new THREE.Vector3((DOOR_X0 + DOOR_X1) / 2, 6.0, D + 0.4), state[1]); this.tags.door.fixed = true; }
    else if (this.tags.door) this.tags.door.visible = false;
  }

  resetView() {
    const k = this.camera.aspect < 0.8 ? 1.12 : 1;       // stand further back on a portrait phone
    this.camera.position.copy(CAM_TARGET).addScaledVector(CAM_HOME.clone().sub(CAM_TARGET), k);
    this.controls.target.copy(CAM_TARGET);
  }

  resize() {
    const p = this.canvas.parentElement, w = p.clientWidth, h = p.clientHeight;
    if (!w || !h) return;
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h;
    this.camera.fov = w / h < 0.8 ? 50 : 38;            // portrait phones need a wider view
    this.camera.updateProjectionMatrix();
    if (!this.placed) { this.placed = true; this.resetView(); }
  }

  frame() {
    if (!this.active) return;
    const dt = Math.min(this.clock.getDelta(), 0.1), t = this.clock.elapsedTime, st = this.state;
    const now = performance.now();

    // Day / night
    this.sun = lerp(this.sun, this.sunTarget, Math.min(1, dt * 2));
    const sky = new THREE.Color(0x0e1a2b).lerp(new THREE.Color(0xbfe3f2), Math.min(1, this.sun * 1.6));
    this.scene.background.copy(sky); this.scene.fog.color.copy(sky);
    this.hemi.intensity = 0.38 + 0.9 * this.sun;
    this.sunLight.intensity = 0.05 + 2.6 * this.sun;
    const a = ((this.hour ?? 12) - 6) / 13 * Math.PI;
    this.sunLight.position.set(Math.cos(a) * 26, 8 + Math.sin(Math.max(0.1, Math.min(Math.PI - 0.1, a))) * 26, 14);
    this.ground.material.color.setRGB(lerp(0.1, 0.56, this.sun), lerp(0.16, 0.68, this.sun), lerp(0.14, 0.45, this.sun));
    this.animateTracker(dt);
    this.animateDoor(t);

    if (st) {
      const act = st.actuators;
      this.fanSpeed = lerp(this.fanSpeed, act.fan ? 16 : 0, dt * 1.5);
      this.blades.rotation.z -= this.fanSpeed * dt;
      this.flames.visible = st.alarms.fire;
      if (st.alarms.fire) this.flames.children.forEach((f, i) => {
        f.scale.set(1, 0.75 + 0.35 * Math.abs(Math.sin(t * (7 + i) + i)), 1);
        f.position.y = f.scale.y * 0.5; f.rotation.y = t * (1 + i * 0.3);
      });

      const watering = now < this.waterUntil;
      this.tubeMat.color.setHex(watering ? 0x2f6fb0 : 0x2b2f33);
      for (const d of this.drops) {
        d.visible = watering;
        if (!watering) continue;
        const n = this.nozzles[d.userData.pot];
        const f = (t * 1.6 + d.userData.phase) % 1;
        d.position.set(n.x + Math.sin(d.userData.phase * 40) * 0.12 - 0.15 * f, n.y - f * f * 0.75, n.z + Math.cos(d.userData.phase * 31) * 0.12 + 0.2 * f);
      }

      const sway = 0.012 + (act.fan ? 0.03 : 0);
      this.plants.forEach((p, i) => { if (p) { p.rotation.z = Math.sin(t * 1.3 + i) * sway; p.rotation.x = Math.cos(t * 1.1 + i * 2) * sway; } });

      this.buzzRings.forEach((r, i) => {
        const f = (t * 1.4 + i * 0.5) % 1;
        r.scale.setScalar(1 + f * 3); r.material.opacity = act.buzzer ? (1 - f) * 0.9 : 0;
      });
      this.beacon.intensity = st.alarms.fire ? 140 * (0.5 + 0.5 * Math.sin(t * 9)) : 0;
      const v = st.vision.status;
      const c = v === 'fire' ? 0xff3b30 : v === 'leaf_anomaly' || v === 'checking' ? 0xffb020 : v === 'unavailable' || v === 'disabled' ? 0x777777 : 0x5fd38d;
      this.camLed.material.color.setHex(c); this.camLed.material.emissive.setHex(c);
    }

    this.controls.update();
    this.renderer.render(this.scene, this.camera);

    // Project labels to the screen
    const w = this.canvas.clientWidth, h = this.canvas.clientHeight, v3 = new THREE.Vector3();
    for (const tg of Object.values(this.tags)) {
      v3.copy(tg.pos).project(this.camera);
      const show = tg.visible && v3.z < 1;
      tg.el.style.display = show ? '' : 'none';
      if (show) {
        const half = tg.el.offsetWidth / 2 + 6;                       // keep the label fully on screen
        tg.el.style.left = Math.max(half, Math.min(w - half, (v3.x + 1) / 2 * w)) + 'px';
        tg.el.style.top = ((1 - v3.y) / 2 * h) + 'px';
      }
    }
  }
}

// Small turntable viewer for the growth preview
export class PlantPreview {
  constructor(canvas) {
    this.canvas = canvas;
    this.renderer = makeRenderer(canvas);
    this.renderer.setClearColor(0xe4ecea);
    this.scene = new THREE.Scene();
    this.scene.add(new THREE.HemisphereLight(0xffffff, 0x8a8a70, 1.3));
    const sun = new THREE.DirectionalLight(0xfff2dd, 2.2);
    sun.position.set(6, 14, 9); sun.castShadow = true;
    Object.assign(sun.shadow.camera, { left: -6, right: 6, top: 15, bottom: -2 });
    this.scene.add(sun);
    const ground = new THREE.Mesh(new THREE.CircleGeometry(5, 40), std(0xd3ccb6, { roughness: 1 }));
    ground.rotation.x = -Math.PI / 2; ground.receiveShadow = true;
    this.scene.add(ground);
    this.turn = new THREE.Group();
    this.turn.add(makePot());
    this.scene.add(this.turn);
    this.camera = new THREE.PerspectiveCamera(34, 1, 0.5, 100);
    this.active = false; this.plant = null; this.key = ''; this.h = 2;
    this.clock = new THREE.Clock();
    new ResizeObserver(() => this.resize()).observe(canvas);
    this.renderer.setAnimationLoop(() => this.frame());
  }
  set(g) {
    const key = plantKey(g, false);
    if (key === this.key) return;
    this.key = key;
    if (this.plant) { this.turn.remove(this.plant); disposePlant(this.plant); }
    this.plant = buildPlant(g, 3);
    this.plant.position.y = 1.36;
    this.turn.add(this.plant);
    this.h = this.plant.userData.height + 1.4;
  }
  resize() {
    const w = this.canvas.clientWidth, h = this.canvas.clientHeight;
    if (!w || !h) return;
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h; this.camera.updateProjectionMatrix();
  }
  frame() {
    if (!this.active) return;
    this.turn.rotation.y += this.clock.getDelta() * 0.35;
    const dist = Math.max(7, this.h * 1.8 / Math.min(1, this.camera.aspect * 1.1));
    this.camera.position.set(0, this.h * 0.95 + 2.2, dist);      // look slightly down on the plant
    this.camera.lookAt(0, this.h * 0.56, 0);
    this.renderer.render(this.scene, this.camera);
  }
}
