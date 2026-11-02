#!/usr/bin/env node
/*
 * Builds every launcher icon, launch image and in-app logo file from the
 * brand SVGs in assets/brand/. Run it again whenever the logo changes.
 *
 * One-time setup (outside the repo is fine):
 *   npm i --no-save @resvg/resvg-js@2.6.2 opentype.js@1.3.4 pngjs@7.0.0
 * Then, from the repo root:
 *   node tool/brand/generate_brand_assets.cjs
 * (Set NODE_PATH to the folder holding node_modules if it is elsewhere.)
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { Resvg } = require('@resvg/resvg-js');
const opentype = require('opentype.js');
const { PNG } = require('pngjs');
const { execFileSync } = require('child_process');

const root = path.resolve(__dirname, '..', '..');
const brandDir = path.join(root, 'assets', 'brand');
const fontPath = path.join(root, 'assets', 'fonts', 'cairo', 'Cairo-Bold.ttf');

// ---------------------------------------------------------------- palette
const BRAND = '#00639A';
const DARK_BG = '#0F1419';
const WHITE = '#FFFFFF';
const STAGING = '#F57C00';

// ------------------------------------------------------------- mark shape
// The mark lives in a 50x65 box whose origin is (25, 21).
const MARK_D = 'M25 86V46a25 25 0 0 1 50 0v40H63V46a13 13 0 0 0-26 0v40Z';
const MARK_BOX = { x: 25, y: 21, w: 50, h: 65 };

/** Mark drawn with its center at (cx, cy) and the given height. */
function markSvg({ cx, cy, height, fill, small = false }) {
  const s = height / MARK_BOX.h;
  const tx = cx - (MARK_BOX.x + MARK_BOX.w / 2) * s;
  const ty = cy - (MARK_BOX.y + MARK_BOX.h / 2) * s;
  const dot = small
    ? '<circle cx="54" cy="62" r="6.5"/>'
    : '<circle cx="55" cy="62" r="5"/>';
  return (
    `<g transform="translate(${r(tx)} ${r(ty)}) scale(${r(s)})" fill="${fill}">` +
    `<path d="${MARK_D}"/>${dot}</g>`
  );
}

const r = (n) => Math.round(n * 10000) / 10000;

// ------------------------------------------------------- staging S badge
const font = opentype.loadSync(fontPath);

/** Path data for a centered "S" inside a circle of radius `radius`. */
function badgeLetter(cx, cy, radius) {
  const size = radius * 1.45;
  const glyph = font.getPath('S', 0, 0, size);
  const box = glyph.getBoundingBox();
  const dx = cx - (box.x1 + box.x2) / 2;
  const dy = cy - (box.y1 + box.y2) / 2;
  const moved = font.getPath('S', dx, dy, size);
  return moved.toPathData(3);
}

function badgeSvg({ cx, cy, radius, fill = STAGING, letter = WHITE }) {
  return (
    `<circle cx="${cx}" cy="${cy}" r="${radius}" fill="${fill}"/>` +
    `<path d="${badgeLetter(cx, cy, radius)}" fill="${letter}"/>`
  );
}

// ---------------------------------------------------------------- render
function svgDoc(size, body, viewBox = `0 0 ${size} ${size}`) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}">${body}</svg>`;
}

/** Renders SVG text to PNG; `opaque` drops the alpha channel (App Store). */
function renderPng(svg, outFile, { width, height, opaque = false }) {
  const resvg = new Resvg(svg, {
    fitTo: height ? { mode: 'height', value: height } : { mode: 'width', value: width },
    font: { loadSystemFonts: false },
  });
  const rendered = resvg.render();
  let buffer = rendered.asPng();
  if (opaque) {
    const png = PNG.sync.read(buffer);
    buffer = PNG.sync.write(png, { colorType: 2, inputHasAlpha: true });
  }
  fs.mkdirSync(path.dirname(outFile), { recursive: true });
  fs.writeFileSync(outFile, buffer);
}

function writeText(file, text) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, text.replace(/\r?\n/g, '\n'));
}

// ------------------------------------------------------------------- iOS
const IOS = path.join(root, 'ios', 'Runner', 'Assets.xcassets');
const ICON = 1024;
// Same proportions as onair_app_icon.svg: the mark is 43% of the icon height.
const ICON_MARK = 440.3;
const iosBadge = { cx: 772, cy: 252, radius: 118 };

function iosIcon({ bg, mark, staging, badgeFill, badgeLetterFill }) {
  let body = `<rect width="${ICON}" height="${ICON}" fill="${bg}"/>`;
  body += markSvg({ cx: 512, cy: 512, height: ICON_MARK, fill: mark });
  if (staging) {
    body += badgeSvg({ ...iosBadge, fill: badgeFill, letter: badgeLetterFill });
  }
  return svgDoc(ICON, body);
}

function iosIconSet(name, staging) {
  const dir = path.join(IOS, `${name}.appiconset`);
  // Drop the old per-size PNGs; a single 1024 image now covers every size.
  if (fs.existsSync(dir)) {
    for (const f of fs.readdirSync(dir)) {
      if (f.endsWith('.png')) fs.rmSync(path.join(dir, f), { force: true });
    }
  }
  const variants = [
    // Default (light) home screen.
    { file: 'AppIcon.png', bg: BRAND, mark: WHITE, badgeFill: STAGING, badgeLetterFill: WHITE },
    // iOS 18+ dark home screen.
    { file: 'AppIcon-Dark.png', bg: DARK_BG, mark: WHITE, badgeFill: STAGING, badgeLetterFill: WHITE },
    // iOS 18+ tinted home screen: grayscale; the system applies the
    // colour the user picked.
    { file: 'AppIcon-Tinted.png', bg: '#000000', mark: WHITE, badgeFill: '#9A9A9A', badgeLetterFill: '#000000' },
  ];
  for (const v of variants) {
    renderPng(iosIcon({ ...v, staging }), path.join(dir, v.file), {
      width: ICON,
      opaque: true,
    });
  }
  const images = [
    { filename: 'AppIcon.png', idiom: 'universal', platform: 'ios', size: '1024x1024' },
    {
      appearances: [{ appearance: 'luminosity', value: 'dark' }],
      filename: 'AppIcon-Dark.png',
      idiom: 'universal',
      platform: 'ios',
      size: '1024x1024',
    },
    {
      appearances: [{ appearance: 'luminosity', value: 'tinted' }],
      filename: 'AppIcon-Tinted.png',
      idiom: 'universal',
      platform: 'ios',
      size: '1024x1024',
    },
  ];
  writeText(
    path.join(dir, 'Contents.json'),
    JSON.stringify({ images, info: { author: 'xcode', version: 1 } }, null, 2) + '\n',
  );
}

// Launch screen mark: 88 pt tall, white over LaunchBackground.
const LAUNCH_MARK_HEIGHT = 88;
const LAUNCH_MARK_WIDTH = Math.round((LAUNCH_MARK_HEIGHT * MARK_BOX.w) / MARK_BOX.h);

function iosLaunchImage() {
  const dir = path.join(IOS, 'LaunchImage.imageset');
  for (const f of fs.readdirSync(dir)) {
    if (f.endsWith('.png')) fs.rmSync(path.join(dir, f));
  }
  const svg = fs.readFileSync(path.join(brandDir, 'onair_mark_white.svg'), 'utf8');
  for (const [scale, suffix] of [[1, ''], [2, '@2x'], [3, '@3x']]) {
    renderPng(svg, path.join(dir, `LaunchImage${suffix}.png`), {
      height: LAUNCH_MARK_HEIGHT * scale,
    });
  }
}

// --------------------------------------------------------------- Android
const ANDROID_MAIN = path.join(root, 'android', 'app', 'src', 'main', 'res');
const ANDROID_STAGING = path.join(root, 'android', 'app', 'src', 'staging', 'res');
const DENSITIES = { mdpi: 1, hdpi: 1.5, xhdpi: 2, xxhdpi: 3, xxxhdpi: 4 };

// Adaptive icon: 108dp canvas, 66dp safe circle. The mark is 34dp tall so
// it reads at the same weight as the iOS icon once the launcher masks it.
const ADAPTIVE = 108;
const ADAPTIVE_MARK = 34;
const adaptiveBadge = { cx: 70, cy: 38, radius: 8.5 };

function vectorGroup({ cx, cy, height, color, small = false }) {
  const s = height / MARK_BOX.h;
  const tx = cx - (MARK_BOX.x + MARK_BOX.w / 2) * s;
  const ty = cy - (MARK_BOX.y + MARK_BOX.h / 2) * s;
  const dot = small ? 'M47.5,62a6.5,6.5 0,1 0,13 0a6.5,6.5 0,1 0,-13 0Z' : 'M50,62a5,5 0,1 0,10 0a5,5 0,1 0,-10 0Z';
  return `    <group
        android:translateX="${r(tx)}"
        android:translateY="${r(ty)}"
        android:scaleX="${r(s)}"
        android:scaleY="${r(s)}">
        <path
            android:fillColor="${color}"
            android:pathData="${MARK_D}" />
        <path
            android:fillColor="${color}"
            android:pathData="${dot}" />
    </group>
`;
}

function vectorDoc({ dp, viewport, body, comment }) {
  return `<?xml version="1.0" encoding="utf-8"?>
<!-- ${comment} Generated by tool/brand/generate_brand_assets.cjs. -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="${dp.w}dp"
    android:height="${dp.h}dp"
    android:viewportWidth="${viewport.w}"
    android:viewportHeight="${viewport.h}">
${body}</vector>
`;
}

function vectorBadge(color, letterColor) {
  const { cx, cy, radius } = adaptiveBadge;
  return `    <path
        android:fillColor="${color}"
        android:pathData="M${cx - radius},${cy}a${radius},${radius} 0,1 0,${radius * 2},0a${radius},${radius} 0,1 0,${-radius * 2},0Z" />
    <path
        android:fillColor="${letterColor}"
        android:pathData="${badgeLetter(cx, cy, radius)}" />
`;
}

function androidVectors() {
  const size = { w: ADAPTIVE, h: ADAPTIVE };
  const mark = (color) =>
    vectorGroup({ cx: 54, cy: 54, height: ADAPTIVE_MARK, color });

  writeText(
    path.join(ANDROID_MAIN, 'drawable', 'ic_launcher_foreground.xml'),
    vectorDoc({ dp: size, viewport: size, body: mark(WHITE), comment: 'Adaptive icon foreground.' }),
  );
  // Android 13+ themed icons: the launcher recolours this silhouette to
  // match the wallpaper / Material You palette.
  writeText(
    path.join(ANDROID_MAIN, 'drawable', 'ic_launcher_monochrome.xml'),
    vectorDoc({ dp: size, viewport: size, body: mark(WHITE), comment: 'Themed (monochrome) icon.' }),
  );
  writeText(
    path.join(ANDROID_STAGING, 'drawable', 'ic_launcher_foreground.xml'),
    vectorDoc({
      dp: size,
      viewport: size,
      body: mark(WHITE) + vectorBadge(STAGING, WHITE),
      comment: 'Staging adaptive icon foreground.',
    }),
  );
  writeText(
    path.join(ANDROID_STAGING, 'drawable', 'ic_launcher_monochrome.xml'),
    vectorDoc({
      dp: size,
      viewport: size,
      body: mark(WHITE) + vectorBadge(WHITE, '#00000000'),
      comment: 'Staging themed (monochrome) icon.',
    }),
  );

  // Launch screen mark (pre Android 12 window background).
  writeText(
    path.join(ANDROID_MAIN, 'drawable', 'launch_logo.xml'),
    vectorDoc({
      dp: { w: LAUNCH_MARK_WIDTH, h: LAUNCH_MARK_HEIGHT },
      viewport: { w: MARK_BOX.w, h: MARK_BOX.h },
      body: vectorGroup({ cx: 25, cy: 32.5, height: MARK_BOX.h, color: WHITE }),
      comment: 'Launch screen mark.',
    }),
  );
  // Android 12+ splash icon: 288dp canvas, content inside the 192dp circle.
  writeText(
    path.join(ANDROID_MAIN, 'drawable', 'splash_icon.xml'),
    vectorDoc({
      dp: { w: 288, h: 288 },
      viewport: { w: 288, h: 288 },
      body: vectorGroup({ cx: 144, cy: 144, height: LAUNCH_MARK_HEIGHT, color: WHITE }),
      comment: 'Android 12+ splash screen icon.',
    }),
  );
  // Status bar notification icon: a white silhouette on 24dp.
  writeText(
    path.join(ANDROID_MAIN, 'drawable', 'ic_stat_onair.xml'),
    vectorDoc({
      dp: { w: 24, h: 24 },
      viewport: { w: 24, h: 24 },
      body: vectorGroup({ cx: 12, cy: 12, height: 20, color: WHITE, small: true }),
      comment: 'Notification small icon.',
    }),
  );
}

// Legacy launcher PNGs for Android 7.x (API 24-25), which has no adaptive icons.
function androidLegacy(resDir, staging) {
  const badge = staging
    ? badgeSvg({ cx: 772, cy: 252, radius: 150 })
    : '';
  const square =
    `<rect width="1024" height="1024" rx="190" fill="${BRAND}"/>` +
    markSvg({ cx: 512, cy: 512, height: ICON_MARK, fill: WHITE }) +
    badge;
  const round =
    `<circle cx="512" cy="512" r="512" fill="${BRAND}"/>` +
    markSvg({ cx: 512, cy: 512, height: ICON_MARK, fill: WHITE }) +
    badge;
  for (const [density, factor] of Object.entries(DENSITIES)) {
    const dir = path.join(resDir, `mipmap-${density}`);
    fs.rmSync(path.join(dir, 'ic_launcher.png'), { force: true });
    // 48dp icon with a 2dp keyline margin, like the Material legacy grid.
    const px = 48 * factor;
    const pad = 2 * factor;
    const view = `${-1024 * (pad / (px - 2 * pad))} ${-1024 * (pad / (px - 2 * pad))} ${1024 * (px / (px - 2 * pad))} ${1024 * (px / (px - 2 * pad))}`;
    renderPng(svgDoc(1024, square, view), path.join(dir, 'ic_launcher.png'), { width: px });
    renderPng(svgDoc(1024, round, view), path.join(dir, 'ic_launcher_round.png'), { width: px });
  }
}

// ----------------------------------------------------------------- stores
function storeIcons() {
  const dir = path.join(brandDir, 'store');
  const svg = fs.readFileSync(path.join(brandDir, 'onair_app_icon.svg'), 'utf8');
  // Google Play: 512x512, full bleed, Play applies the mask.
  renderPng(svg, path.join(dir, 'play_store_icon_512.png'), { width: 512, opaque: true });
  // App Store Connect uses the 1024 icon from the iOS asset catalog.
  renderPng(svg, path.join(dir, 'app_store_icon_1024.png'), { width: 1024, opaque: true });
}

// ------------------------------------------------------- Dart logo data
// Flattens each brand SVG into (path data, affine transform) pairs so the
// app can draw the logo as crisp vectors in any colour.
function parseTransform(value) {
  let m = [1, 0, 0, 1, 0, 0];
  const re = /(translate|scale)\(([^)]*)\)/g;
  let match;
  while ((match = re.exec(value || ''))) {
    const nums = match[2].trim().split(/[\s,]+/).map(Number);
    const t =
      match[1] === 'translate'
        ? [1, 0, 0, 1, nums[0], nums[1] ?? 0]
        : [nums[0], 0, 0, nums[1] ?? nums[0], 0, 0];
    m = multiply(m, t);
  }
  return m;
}

function multiply(a, b) {
  return [
    a[0] * b[0] + a[2] * b[1],
    a[1] * b[0] + a[3] * b[1],
    a[0] * b[2] + a[2] * b[3],
    a[1] * b[2] + a[3] * b[3],
    a[0] * b[4] + a[2] * b[5] + a[4],
    a[1] * b[4] + a[3] * b[5] + a[5],
  ];
}

function flattenSvg(file) {
  const text = fs.readFileSync(path.join(brandDir, file), 'utf8');
  const viewBox = /viewBox="([^"]+)"/.exec(text)[1].split(/\s+/).map(Number);
  const stack = [[1, 0, 0, 1, 0, 0]];
  const shapes = [];
  const tag = /<(\/?)(g|path|circle)\b([^>]*?)(\/?)>/g;
  let match;
  while ((match = tag.exec(text))) {
    const [, closing, name, attrs] = match;
    const attr = (key) => (new RegExp(`\\b${key}="([^"]*)"`).exec(attrs) || [])[1];
    const top = stack[stack.length - 1];
    if (name === 'g') {
      if (closing) stack.pop();
      else stack.push(multiply(top, parseTransform(attr('transform'))));
      continue;
    }
    const matrix = multiply(top, parseTransform(attr('transform')));
    let d;
    let mark;
    if (name === 'circle') {
      const cx = Number(attr('cx'));
      const cy = Number(attr('cy'));
      const rad = Number(attr('r'));
      d = `M${cx - rad} ${cy}a${rad} ${rad} 0 1 0 ${2 * rad} 0a${rad} ${rad} 0 1 0 ${-2 * rad} 0Z`;
      mark = true;
    } else {
      d = attr('d');
      mark = d === MARK_D;
    }
    shapes.push({ d, matrix: matrix.map(r), mark });
  }
  return { viewBox, shapes };
}

function dartLogoData() {
  const lockups = {
    mark: flattenSvg('onair_mark.svg'),
    markSmall: flattenSvg('onair_mark_small.svg'),
    logo: flattenSvg('onair_logo.svg'),
    logoArabic: flattenSvg('onair_logo_ar.svg'),
  };
  const lines = [
    '// GENERATED by tool/brand/generate_brand_assets.cjs from assets/brand/.',
    '// Do not edit by hand: change the SVGs and run the script again.',
    '',
    "part of 'on_air_logo.dart';",
    '',
  ];
  for (const [name, { viewBox, shapes }] of Object.entries(lockups)) {
    lines.push(`const _${name} = _LogoArt(`);
    lines.push(`  viewBox: Rect.fromLTWH(${viewBox.join(', ')}),`);
    lines.push('  shapes: [');
    for (const s of shapes) {
      lines.push('    _LogoShape(');
      lines.push(`      '${s.d}',`);
      lines.push(`      [${s.matrix.join(', ')}],`);
      if (s.mark) lines.push('      isMark: true,');
      lines.push('    ),');
    }
    lines.push('  ],');
    lines.push(');');
    lines.push('');
  }
  const dartFile = path.join(root, 'lib', 'design_system', 'brand', 'on_air_logo_art.dart');
  writeText(dartFile, lines.join('\n'));
  execFileSync('dart', ['format', dartFile], {
    stdio: 'inherit',
    shell: process.platform === 'win32',
  });
}

// ------------------------------------------------------------------- run
iosIconSet('AppIcon', false);
iosIconSet('AppIcon-Staging', true);
iosLaunchImage();
androidVectors();
androidLegacy(ANDROID_MAIN, false);
androidLegacy(ANDROID_STAGING, true);
storeIcons();
dartLogoData();
console.log('Brand assets generated.');
