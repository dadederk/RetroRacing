# 32-Bit Sprite Generation Prompts

Generated with the built-in ImageGen tool in image-generation mode on
2026-08-05. Each asset used its matching 16-Bit Apple TV sprite as a
composition and silhouette reference, not as output artwork.

## Shared direction

Create one production-ready 2D SpriteKit racing-game cutout sprite. Preserve
the reference's rear-facing orthographic camera angle, centered composition,
silhouette proportions, and gameplay readability. Re-render it as original
late-1990s 32-Bit console artwork: pre-rendered low-poly 3D, crisp edges,
richer tonal gradients and material detail than 16-Bit pixel art, subtle
ordered dithering, vivid arcade lighting, and a readable small-scale
silhouette. Center the sprite with even padding on a flat `#00ff00` chroma-key
background. Do not add a floor, shadow, glow, scenery, text, logo, or watermark,
and do not use green on the subject.

## Asset directions

- Player car: magenta-red `#FF3855`, deep navy graphite mechanics, warm-ivory
  highlights, exposed rear tires, rear wing, and a warm-ivory helmet `X`.
- Rival car: electric cyan `#43D9FF`, navy-indigo mechanics, red-orange tail
  lights, exposed rear tires, rear wing, an unmarked helmet, and exactly four
  exhaust pipes in two pairs.
- Crash: one compact angular impact with orange `#FFB133` and yellow flame
  shards, magenta and cyan fragments, graphite debris, and exactly one readable
  detached wheel. Use opaque hard-edged forms without smoke or haze.
- Player helmet: glossy magenta-red shell, deep navy visor, cyan reflection,
  warm-ivory trim, and a warm-ivory side `X`.
- Friend helmet: glossy electric-cyan shell, deep navy visor, pale-cyan
  reflection, warm-ivory trim, and no mark, symbol, or number.

## Player car detail revision

The player car received a second built-in ImageGen edit pass after comparison
with the approved rival car. The player artwork remained the edit target and
the rival artwork was supplied only as a style and detail-density reference.
The revision prompt asked for the same mechanical richness between the rear
wheels: smaller faceted paint planes, exposed graphite cavities, crossed
silver suspension braces, coils and linkages, metallic joints, panel seams,
deeper occlusion, and more visible tire texture. It explicitly preserved the
player's magenta-red identity, warm-ivory helmet `X`, rear-facing camera,
silhouette, wheel spacing, wing, lights, intact state, and single central
exhaust, while excluding the rival's cyan palette and four-exhaust identity.

`playersCar-32Bit-v1-master-chroma.png` and
`playersCar-32Bit-v1-master.png` preserve the superseded first pass. The files
without the `v1` suffix are the approved revised masters used by the curated
and runtime variants.

The chroma-key helper used automatic border sampling, soft matte, thresholds
12/220, and despill. Curated variants use Lanczos resampling, Riemersma
dithering, a bounded 256-color RGBA palette, and exact canvas and alpha-bound
dimensions matching the established 16-Bit family.
