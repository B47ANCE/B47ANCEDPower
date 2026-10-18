# Icon and Workshop test distribution

Project Version: 0.17.0-dev.2

The user selected the generated battery cutout as the mod icon and authorized
merging project PRs and publishing after checks pass on 2026-10-18. This is a
PATCH-compatible artwork/packaging checkpoint within the unreleased 0.17.0 line.
No gameplay, API, sandbox, persistence schema or dependency contract changed.

`art/source/ModIcon-v1.png` is the original generated 1254 x 1254 RGBA master.
The source and mirror `42/icon.png` files use identical bytes. Alpha spans 0–255
and all four corners are fully transparent. No background fill or headline remains.
The plus/minus marks are physical battery details. Installed vanilla
`media/lua/client/OptionScreens/ModSelector/ModListBox.lua:201` renders mod icons
with `drawTextureScaled`; native UI appearance still requires in-game inspection.

Icon SHA-256: `2e48826d39abdfc54962a022c4507a97e50ddf2bf5fe4f913b9d51a7f1abca5b`.
The unchanged thumbnail/preview SHA-256 is
`f9fc7a4c1a4c16b34a37260e87052715f631b4e2692453dc8baa669999e2bc4b`.
The original thumbnail, historical packages, and prior artwork remain preserved.

## Artwork provenance

Built-in imagegen edited the user-supplied thumbnail. Final prompt:

> Use case: background-extraction. Edit target: the supplied B47ANCE'd POWER thumbnail. Create one square transparent PNG project icon showing ONLY its battery subject arrangement: the large taped four-cell battery pack, the two smaller gold/copper-topped loose batteries at right, and the silver coin cell in front. Remove ALL heading/branding/typography and remove the dark background completely, including floor, cast shadows and glow. Preserve the original subjects' recognizable arrangement, proportions, muted colors, stepped pixel-art silhouettes, shading, metal terminals and tape straps. Keep the physical plus/minus polarity marks on the batteries as item details. Reframe the object group to fill a square icon canvas with a small even transparent margin; no cropping of items. Actual transparent alpha outside objects and between separate objects, no colored fill, no checkerboard painted into the image, no border, no extra objects or text. Clean crisp edges suitable for a game mod icon.

## Package and upload contract

Canonical publication text remains `WORKSHOP_DESCRIPTION.txt` and the newest
section of `WORKSHOP_CHANGE_NOTE.txt`. `docs/STEAM_WORKSHOP_DESCRIPTION.txt` and
the `description=` lines in `workshop.txt` mirror the description. Existing BBCode
and credits are retained; the technical Mod ID in the description is corrected.
Description and current changenote explicitly label the MP testing build.

`python scripts/prepare_workshop.py` creates a separate immutable staging tree,
versioned current ZIP, SHA-256 file manifest bound to the exact Git commit, and
an existing-item VDF. `--verify` checks exact committed source bytes, mirror,
stage, ZIP inventory, CRC/data, safe paths, duplicates/case, artwork alpha/hashes,
text/newline roundtrip and provenance. It never deploys, authenticates or uploads.
It refuses to overwrite artifacts and does not clean historical outputs.

The established uploader descriptor identifies App ID 108600, Workshop item
3788592598 and `Contents/` as the uploaded root. The new VDF retains these
identities and omits visibility, tags and preview replacement. Project thumbnail
bytes and the existing remote Workshop preview are preserved. The public Steam
page returned HTTP 429 during preflight; live-page metadata is not claimed verified.
SteamCMD must explicitly report successful completion of the existing-item update.
Private authentication and raw logs are never committed. Upload result/provenance
is recorded separately after actual success, with no automatic Steam restart.

## Evidence limits

Current host validation and exact commands are recorded in `VALIDATION.json`.
The older `VALIDATION_0_17_0_dev_1.json` remains historical. Existing source fixes
retain their contracts in `AUDIT_REMEDIATION.md`; this artwork change does not
constitute renewed native gameplay evidence. SP NOT TESTED, dedicated G7
NOT TESTED / BLOCKED, stable-release G8 BLOCKED. Follow `RUNTIME_VALIDATION.md`
on fresh disposable saves with two clients, reconnects and server restarts.

## Actual upload result

SteamCMD exited 0 with cached login and the successful existing-item commit
marker on 2026-10-18. `WORKSHOP_UPLOAD_0_17_0_dev_2.json` records the exact
package/VDF hashes, payload commit and merged main commit. Public-page access
remains unavailable (HTTP 429; public API result 9 without details). Subscription
download and native runtime remain NOT TESTED. Steam was not restarted.
