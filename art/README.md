# Original battery artwork

Created 2026-09-24 using the built-in image generation tool under the user's
explicit artwork-production authorization. These are source masters, not yet
runtime textures or 3D models. No third-party reference images were supplied.

| Master | Target item | State |
| --- | --- | --- |
| source/BatteryAA-v1.png | B47ANCEDPower.BatteryAA | Visually inspected; 1254 x 1254 RGBA, transparent corner and 4,528 transparent pixels in a 16-pixel-grid sample |
| source/BatteryCoin-v1.png | B47ANCEDPower.BatteryCoin | Visually inspected; alpha and small-size readability validation pending |
| source/BatteryLithiumPack-v1.png | B47ANCEDPower.BatteryLithiumPack | Visually inspected; transparent source master; game-size readability pending |
| source/Battery9V-v1.png | B47ANCEDPower.Battery9V | Visually inspected; distinct snap terminals and correct 9V marking; game-size readability pending |
| source/BatteryAAA-v1.png | B47ANCEDPower.BatteryAAA | Visually inspected; slender silhouette and correct marking; game-size readability pending |
| source/BatteryD-v1.png | B47ANCEDPower.BatteryD | Visually inspected; broad silhouette and correct marking; game-size readability pending |
| source/BatteryC-v1.png | B47ANCEDPower.BatteryC | Visually inspected; correct marking; game-size readability pending |
| source/BatteryAAImprovised-rejected-v1.png | Not for runtime use | Rejected: oversized paperclip loop, unlike the compact model spacer |
| source/BatteryAAImprovised-v2.png | B47ANCEDPower.BatteryAAImprovised | Corrected compact spacer; visually inspected; game-size review pending |
| source/BatteryPackSmall-v1.png | B47ANCEDPower.BatteryPackSmall | Four AA cells/two tape bands visually inspected; game-size review pending |
| source/BatteryPackLarge-v1.png | B47ANCEDPower.BatteryPackLarge | Four D cells/two tape bands visually inspected; game-size review pending |

Historical production notes below retain their original wording and prompts.

Prompt briefs: AA used a single worn charcoal-and-silver AA cylinder, diagonal
isometric view, AA/+ markings, no branding, transparent background. Coin cell
used a single thin silver disk, isometric view, engraved +, no branding,
transparent background. Both requested crisp inventory silhouettes readable at
32 pixels, restrained painted shading, no glow or external shadow.

Lithium-pack master generated with the built-in image-generation tool, 2026-09-26.
Final prompt: "Use case: stylized-concept. Asset type: original survival-game
inventory sprite for powerWorks rechargeable lithium battery pack. Single
unbranded charcoal rectangular sealed battery, rounded case edges, slightly raised
dark grey top and bottom caps, two small silver contact pads near the top of its
front face. No wires. Isometric view angled diagonally lower-left to upper-right,
centered with full silhouette and generous transparent margin. Restrained
hand-painted realistic shading, subtle worn edges, crisp legible silhouette
intended for tiny 32-pixel inventory display. Genuinely transparent background.
No text, logo, glow, cast shadow, scenery, extra objects or watermark. Not a
product advertisement."

9V master generated with the built-in image-generation tool, 2026-09-26.
Final prompt: "Use case: stylized-concept. Asset type: original survival-game
inventory sprite, powerWorks 9V battery. Single unbranded charcoal rectangular
9V battery with silver top plate and two different snap terminals: one small
round raised positive snap and one larger hollow hexagonal negative socket.
Clearly visible top, front and side in isometric perspective; battery long
axis diagonal lower-left to upper-right. Exact small front marking: '9V', no
other text. Restrained hand-painted realistic shading and lightly worn edges.
Crisp silhouette for 32-pixel inventory use. Whole battery centered, transparent
margins and genuinely transparent background. No other objects, wires, branding,
glow, external shadow or watermark. Keep terminals mechanically distinct."
The generated composition is upright rather than diagonal; retain it as a
candidate pending game-size review, not an approved final inventory export.

AAA and D masters generated with the built-in image-generation tool, 2026-09-26.
Exact prompts share this text, with the alternatives below substituted:
"Use case: stylized-concept. Original survival-game inventory sprite: one
{shape}, worn charcoal wrapper, silver ends and small positive button. Exact
markings '{mark}' and '+', no branding or other text. Full battery diagonal
lower-left to upper-right, clear isometric view. Restrained painted-realistic
shading, crisp silhouette for small inventory use. Genuinely transparent
background, balanced margin, no shadow outside object, no extra items, no glow
or watermark."

- AAA shape: `slender AAA battery, length about 4.2 times diameter`; mark: `AAA`.
- D shape: `squat broad D-cell battery, length about 1.8 times diameter`; mark: `D`.
- C uses the same exact prompt with shape `broad C-cell battery, length about 1.9 times diameter`; mark: `C`.

Improvised-AA rejected draft prompt (built-in generation, 2026-09-26):
"Use case: stylized-concept. Original survival-game inventory sprite: one
makeshift AA adapter consisting only of a slender charcoal-and-silver AAA
battery and a folded silver paperclip conductor spacer touching its flat
negative end. The spacer extends the battery length slightly and is visibly
bent wire, not a second battery or sleeve. Exact wrapper markings 'AAA' and '+'.
No tape, wire leads, extra components or branding. Full object diagonal
lower-left to upper-right, positive button at upper right, folded spacer at
lower left clearly visible. Restrained painted-realistic shading, lightly worn
surfaces, crisp small-inventory silhouette. Genuinely transparent background,
balanced margin, no external shadow, glow or watermark."

The requested correction (compact zigzag extending only one tenth of the body
length) failed with a generation usage-limit response. No corrected image was
produced. The two pack icons remain ungenerated. Do not use the rejected draft
or count it as completed coverage; CLI fallback was not authorized or invoked.

After the reported reset, built-in editing succeeded with this exact prompt:
"Use case: precise-object-edit. Edit target is the supplied battery sprite.
Preserve battery body, AAA marking, colors, angle and transparent background.
Change ONLY the oversized paperclip loop at the negative end: fold it tightly
into a compact zigzag metal spacer touching the flat negative end. Spacer must
extend the battery by only one tenth of the body's length, not a handle. No
extra components or tape. Keep transparency."
The v2 result was visually inspected and saved separately; the original rejected
draft remains intact. Small-size readability is not yet validated.

Original AAA, AA, C, D, coin-cell, 9V, small/large taped-pack and improvised-AA model masters now exist in `models/`, with FBX
round-trip validation recorded in `geometry-validation.json`. Basic wrapper and
metal materials are assigned and 256-pixel base-color atlases are now baked.
`render_battery_geometry.py` produces transparent model previews. Initial review
confirms distinct cylinder/disk shapes and visible terminals. Reduced preview
lighting and smooth side normals corrected initial overexposure and faceting.
All ten single-atlas exports pass geometry, dimensions, UV and texture-reference
checks. Exported-model previews were generated; AA/D and 9V were inspected.
The 9V has distinct male and recessed female snaps. These are plain base-color
prototypes, not final detailed artwork; native review remains outstanding.

The taped packs each depict the four cells required by their existing recipes.
Their thin rounded tape wraps and exported previews have been visually reviewed.
The improvised-AA model depicts the existing AAA-plus-paperclip recipe with a
folded conductor spacer; its exported preview has also been inspected. These
illustrations do not establish electrical topology or change gameplay values.
The rechargeable lithium pack now has an original sealed-case model with two
contact pads. Exported preview review caught coplanar top-cap surfaces; separating
the top cap from the case face corrected the artifact before revalidation.
Its unbranded shape is visual design only, not a new connector contract.

Cylindrical wrappers now use original procedural charcoal variation baked into
the atlas, including cells inside the taped packs and the improvised AA. AA and
large-pack exported previews were inspected after this change. No runtime shader
or external texture dependency is required. This adds surface variation, not
finished labels or an assertion of native-game appearance.

AAA/AA/C/D and the AAA inside the improvised adapter now have curved size
markings in their original model geometry. Initial D preview revealed that
coarse letter faces intersected the curved wrapper. Subdividing the lettering
before wrapping corrected those gaps; the corrected exported D preview was
inspected and all ten model round trips passed. Finished surface artwork and
native presentation are still outstanding. These source updates are not integrated.
AAA, C and improvised-AA previews were subsequently rendered and inspected too.
The 9V now carries its own original front-face marking; its exported preview
was inspected with both snap terminals visible and its round-trip validation passed.
Both taped packs now carry the appropriate AA/D markings between their bands.
Exported preview review found cap-to-wrapper gaps on the D pack; slightly
overlapping the cap geometry corrected them. Both pack exports were regenerated,
all ten model checks and eight coverage tests passed, and the corrected D-pack
preview was inspected. This does not establish final in-game scale or readability.

Next: verify coin-cell alpha, produce game-size exports, review on light/dark
inventory backgrounds, texture the models and integrate item mappings.
Do not infer native rendering or model completeness from these raster masters.

## Inventory-size preparation

`inventory-review.html` displays all ten non-rejected masters at 32/64 pixels against light
and dark backgrounds, without modifying them. Automated browser inspection was
blocked by local-file URL policy; this page has NOT been visually validated.
Direct PNG inspection confirmed fully transparent pixels in all four masters.
At 32-pixel aspect-preserving fit, their alpha>127 content bounds measure:

| Master | Content width x height at 32 px |
| --- | --- |
| AA | 28.4 x 24.3 |
| Coin | 22.7 x 18.2 |
| Lithium pack | 20.6 x 21.8 |
| 9V | 19.1 x 28.9 |

Padding differs materially, especially for the lithium pack. Normalize export
framing before final readability review; do not equate the dimensions or alpha
check with a visual pass. Source masters remain unchanged.
