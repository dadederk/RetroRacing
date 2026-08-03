#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, readFileSync, readdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

const root = process.cwd();
const sourceCatalog = join(root, "AssetSources/RuntimeFootprint2026-08-02/RetroRacingShared/Assets.xcassets");
const catalog = join(root, "RetroRacing/RetroRacingShared/Assets.xcassets");

function ensureDirectory(path) {
  mkdirSync(path, { recursive: true });
}

function imageInfo(path) {
  const output = execFileSync("identify", ["-format", "%w %h", path], { encoding: "utf8" });
  const [width, height] = output.trim().split(/\s+/).map(Number);
  return { width, height, longEdge: Math.max(width, height) };
}

function resizeOrCopy(source, destination, maxLongEdge) {
  ensureDirectory(dirname(destination));
  const info = imageInfo(source);
  if (info.longEdge <= maxLongEdge) {
    copyFileSync(source, destination);
    return;
  }
  execFileSync("magick", [
    source,
    "-auto-orient",
    "-filter",
    "Lanczos",
    "-resize",
    `${maxLongEdge}x${maxLongEdge}>`,
    "-depth",
    "8",
    destination,
  ]);
}

function convertTo8Bit(source, destination) {
  ensureDirectory(dirname(destination));
  const temporaryDestination = destination + ".tmp.png";
  execFileSync("magick", [
    source,
    "-auto-orient",
    "-depth",
    "8",
    "PNG32:" + temporaryDestination,
  ]);
  renameSync(temporaryDestination, destination);
}

function clearPNGs(imageset) {
  for (const entry of readdirSync(imageset, { withFileTypes: true })) {
    if (entry.isFile() && entry.name.toLowerCase().endsWith(".png")) {
      rmSync(join(imageset, entry.name));
    }
  }
}

function writeContents(imageset, images, properties) {
  const body = {
    images,
    info: {
      author: "xcode",
      version: 1,
    },
  };
  if (properties) {
    body.properties = properties;
  }
  writeFileSync(join(imageset, "Contents.json"), JSON.stringify(body, null, 2) + "\n");
}

function optimizeImageset(relativeImageset, sourceFilename, variants, properties) {
  const source = join(sourceCatalog, relativeImageset, sourceFilename);
  const imageset = join(catalog, relativeImageset);
  clearPNGs(imageset);
  const images = [];
  for (const variant of variants) {
    const filename = `${relativeImageset.replace(/.*\/|\.imageset/g, "")}-${variant.name}.png`;
    resizeOrCopy(source, join(imageset, filename), variant.maxLongEdge);
    images.push({
      filename,
      idiom: variant.idiom,
      ...(variant.scale ? { scale: variant.scale } : {}),
    });
  }
  writeContents(imageset, images, properties);
}

function optimizeSpriteImageset(relativeImageset, sources, caps) {
  const imageset = join(catalog, relativeImageset);
  clearPNGs(imageset);
  const images = [];
  for (const variant of caps) {
    const sourceFilename = sources[variant.source];
    const source = join(sourceCatalog, relativeImageset, sourceFilename);
    const assetBase = relativeImageset.replace(/.*\/|\.imageset/g, "");
    const filename = `${assetBase}-${variant.idiom}.png`;
    resizeOrCopy(source, join(imageset, filename), variant.maxLongEdge);
    images.push({ filename, idiom: variant.idiom });
  }
  writeContents(imageset, images);
}

const shareResultVariants = [
  { name: "iphone-2x", idiom: "iphone", scale: "2x", maxLongEdge: 512 },
  { name: "iphone-3x", idiom: "iphone", scale: "3x", maxLongEdge: 768 },
  { name: "ipad-2x", idiom: "ipad", scale: "2x", maxLongEdge: 512 },
  { name: "mac-1x", idiom: "mac", scale: "1x", maxLongEdge: 256 },
  { name: "mac-2x", idiom: "mac", scale: "2x", maxLongEdge: 512 },
];

for (const name of ["WinWithFriend", "LoseWithFriend", "Tie", "Rematch", "ConnectionLost"]) {
  optimizeImageset(
    `${name}.imageset`,
    `${name}.png`,
    shareResultVariants,
    { "template-rendering-intent": "original" }
  );
}

const templateIconVariants = [];
templateIconVariants.push(
  { name: "iphone-1x", idiom: "iphone", scale: "1x", maxLongEdge: 96 },
  { name: "iphone-2x", idiom: "iphone", scale: "2x", maxLongEdge: 192 },
  { name: "iphone-3x", idiom: "iphone", scale: "3x", maxLongEdge: 256 },
  { name: "mac-1x", idiom: "mac", scale: "1x", maxLongEdge: 96 },
  { name: "mac-2x", idiom: "mac", scale: "2x", maxLongEdge: 192 }
);
templateIconVariants.push(
  { name: "ipad-1x", idiom: "ipad", scale: "1x", maxLongEdge: 96 },
  { name: "ipad-2x", idiom: "ipad", scale: "2x", maxLongEdge: 192 }
);

for (const name of ["GetReady", "WaitingForFriendToFinish", "WaitingForFriendToJoin"]) {
  optimizeImageset(`Icons/${name}.imageset`, `${name}.png`, templateIconVariants);
}

const profileVariants = [];
profileVariants.push(
  { name: "iphone-1x", idiom: "iphone", scale: "1x", maxLongEdge: 160 },
  { name: "iphone-2x", idiom: "iphone", scale: "2x", maxLongEdge: 320 },
  { name: "iphone-3x", idiom: "iphone", scale: "3x", maxLongEdge: 480 },
  { name: "mac-1x", idiom: "mac", scale: "1x", maxLongEdge: 160 },
  { name: "mac-2x", idiom: "mac", scale: "2x", maxLongEdge: 320 }
);
profileVariants.push(
  { name: "ipad-1x", idiom: "ipad", scale: "1x", maxLongEdge: 160 },
  { name: "ipad-2x", idiom: "ipad", scale: "2x", maxLongEdge: 320 }
);
profileVariants.push({ name: "tv", idiom: "tv", scale: "1x", maxLongEdge: 480 });
optimizeImageset("profilePicRetroRapid.imageset", "profilePicRetroRapid.png", profileVariants);

const controlVariants = [];
controlVariants.push(
  { name: "iphone-1x", idiom: "iphone", scale: "1x", maxLongEdge: 256 },
  { name: "iphone-2x", idiom: "iphone", scale: "2x", maxLongEdge: 512 },
  { name: "iphone-3x", idiom: "iphone", scale: "3x", maxLongEdge: 768 },
  { name: "mac-1x", idiom: "mac", scale: "1x", maxLongEdge: 256 },
  { name: "mac-2x", idiom: "mac", scale: "2x", maxLongEdge: 512 }
);
controlVariants.push(
  { name: "ipad-1x", idiom: "ipad", scale: "1x", maxLongEdge: 256 },
  { name: "ipad-2x", idiom: "ipad", scale: "2x", maxLongEdge: 512 }
);
controlVariants.push({ name: "tv", idiom: "tv", scale: "1x", maxLongEdge: 512 });
for (const [relativeImageset, sourceFilename] of [
  ["Sprites/ButtonUp.imageset", "ButtonUp.png"],
  ["Sprites/ButtonDown.imageset", "ButtonDown.png"],
  ["Sprites/HeyHo.imageset", "HeyHo.png"],
]) {
  optimizeImageset(relativeImageset, sourceFilename, controlVariants);
}

const spriteCaps = [
  { idiom: "iphone", source: "universal", maxLongEdge: 768 },
  { idiom: "ipad", source: "universal", maxLongEdge: 768 },
  { idiom: "mac", source: "universal", maxLongEdge: 1024 },
  { idiom: "tv", source: "tv", maxLongEdge: 512 },
  { idiom: "watch", source: "watch", maxLongEdge: 256 },
];
const lifeCaps = [
  { idiom: "iphone", source: "universal", maxLongEdge: 256 },
  { idiom: "ipad", source: "universal", maxLongEdge: 256 },
  { idiom: "mac", source: "universal", maxLongEdge: 256 },
  { idiom: "tv", source: "tv", maxLongEdge: 256 },
  { idiom: "watch", source: "watch", maxLongEdge: 64 },
];

for (const definition of [
  {
    path: "Sprites/LCD/playersCar-LCD.imageset",
    sources: { universal: "PlayerCar.png", watch: "PlayerCar 1.png", tv: "PlayerCar 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/LCD/rivalsCar-LCD.imageset",
    sources: { universal: "RivalCar2.png", watch: "RivalCar2 1.png", tv: "RivalCar2 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/LCD/crash-LCD.imageset",
    sources: { universal: "CRASH.png", watch: "CRASH 1.png", tv: "CRASH 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/LCD/life-LCD.imageset",
    sources: { universal: "LIVES.png", watch: "LIVES 1.png", tv: "LIVES 2.png" },
    caps: lifeCaps,
  },
  {
    path: "Sprites/GameBoy/playersCar-GameBoy.imageset",
    sources: { universal: "playersCar-GameBoy.png", watch: "playersCar-GameBoy 1.png", tv: "playersCar-GameBoy 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/GameBoy/rivalsCar-GameBoy.imageset",
    sources: { universal: "rivalsCar-GameBoy.png", watch: "rivalsCar-GameBoy 1.png", tv: "rivalsCar-GameBoy 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/GameBoy/crash-GameBoy.imageset",
    sources: { universal: "crash-GameBoy.png", watch: "crash-GameBoy 1.png", tv: "crash-GameBoy 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/GameBoy/life-GameBoy.imageset",
    sources: { universal: "life-GameBoy.png", watch: "life-GameBoy 1.png", tv: "life-GameBoy 2.png" },
    caps: lifeCaps,
  },
  {
    path: "Sprites/8Bit/playersCar-8Bit.imageset",
    sources: { universal: "playersCar-8Bit.png", watch: "playersCar-8Bit 1.png", tv: "playersCar-8Bit 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/8Bit/rivalsCar-8Bit.imageset",
    sources: { universal: "rivalsCar-8Bit.png", watch: "rivalsCar-8Bit 1.png", tv: "rivalsCar-8Bit 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/8Bit/crash-8Bit.imageset",
    sources: { universal: "crash-8Bit.png", watch: "crash-8Bit 1.png", tv: "crash-8Bit 2.png" },
    caps: spriteCaps,
  },
  {
    path: "Sprites/8Bit/life-8Bit.imageset",
    sources: { universal: "life-8Bit.png", watch: "life-8Bit 1.png", tv: "life-8Bit 2.png" },
    caps: lifeCaps,
  },
]) {
  optimizeSpriteImageset(definition.path, definition.sources, definition.caps);
}

for (const definition of [
  ["Finished.imageset", "Finished.png"],
  ["NewRecord.imageset", "NewRecord.png"],
  ["AchievementDefault.imageset", "AchievementDefault.png"],
]) {
  optimizeImageset(definition[0], definition[1], [
    { name: "iphone", idiom: "iphone", maxLongEdge: 9999 },
    { name: "ipad", idiom: "ipad", maxLongEdge: 9999 },
    { name: "mac", idiom: "mac", maxLongEdge: 9999 },
    { name: "watch", idiom: "watch", maxLongEdge: 512 },
    { name: "tv", idiom: "tv", maxLongEdge: 384 },
  ]);
}

optimizeImageset("Sprites/lapStripMask.imageset", "lapStripMask.png", [
  { name: "iphone", idiom: "iphone", maxLongEdge: 1600 },
  { name: "ipad", idiom: "ipad", maxLongEdge: 1600 },
  { name: "mac", idiom: "mac", maxLongEdge: 1600 },
  { name: "tv", idiom: "tv", maxLongEdge: 1600 },
]);
resizeOrCopy(
  join(sourceCatalog, "Sprites/lapStripMask.imageset/lapStripMask 1.png"),
  join(catalog, "Sprites/lapStripMask.imageset/lapStripMask-watch.png"),
  800
);
{
  const imageset = join(catalog, "Sprites/lapStripMask.imageset");
  const contents = JSON.parse(readFileSync(join(imageset, "Contents.json"), "utf8"));
  contents.images.push({ filename: "lapStripMask-watch.png", idiom: "watch" });
  writeFileSync(join(imageset, "Contents.json"), JSON.stringify(contents, null, 2) + "\n");
}

optimizeImageset("ScreenshotFixtures/johnAppleseedAvatar.imageset", "johnAppleseedAvatar.png", [
  { name: "iphone", idiom: "iphone", maxLongEdge: 226 },
  { name: "ipad", idiom: "ipad", maxLongEdge: 226 },
  { name: "mac", idiom: "mac", maxLongEdge: 226 },
]);

for (const relative of [
  "Sprites/Volume.imageset",
  "Sprites/laneInnerMask.imageset",
  "Sprites/laneOuterMask.imageset",
]) {
  const path = join(catalog, relative);
  if (existsSync(path)) {
    rmSync(path, { recursive: true, force: true });
  }
}

convertTo8Bit(
  join(root, "RetroRacing/RetroRacingUniversal/Assets/RetroRapid.icon/Assets/appstore1024.png"),
  join(root, "RetroRacing/RetroRacingUniversal/Assets/RetroRapid.icon/Assets/appstore1024.png")
);
convertTo8Bit(
  join(root, "RetroRacing/RetroRacingWatchOS/Assets.xcassets/AppIcon.appiconset/appstore1024.png"),
  join(root, "RetroRacing/RetroRacingWatchOS/Assets.xcassets/AppIcon.appiconset/appstore1024.png")
);
