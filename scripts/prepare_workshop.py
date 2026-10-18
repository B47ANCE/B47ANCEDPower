"""Build/verify the existing item's test package and VDF; never uploads or deploys."""
import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import zipfile

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
MOD = "B47ANCEDPower"
ITEM = "3788592598"
LABEL = "MP testing build - dedicated multiplayer NOT TESTED"
THUMBNAIL = "f9fc7a4c1a4c16b34a37260e87052715f631b4e2692453dc8baa669999e2bc4b"
ICON = "2e48826d39abdfc54962a022c4507a97e50ddf2bf5fe4f913b9d51a7f1abca5b"


def require(condition, message):
    if not condition:
        raise ValueError(message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT).decode().strip()


def inventory(folder):
    result = {}
    for directory, folders, files in os.walk(folder, followlinks=False):
        for name in folders + files:
            path = Path(directory) / name
            require(not path.is_symlink() and not os.path.isjunction(path), "Linked staging/source entry")
        for name in files:
            path = Path(directory) / name
            result[path.relative_to(folder).as_posix()] = path.read_bytes()
    return result


def inputs():
    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    require((ROOT / "WORKSHOP_ID.txt").read_text().strip() == ITEM, "Workshop identity changed")
    source = inventory(ROOT / "src" / MOD)
    require(source == inventory(ROOT / "Contents/mods" / MOD), "Source/mirror mismatch")
    require(bool(source), "Empty source")
    for name in source:
        require(Path(name).suffix.lower() in {".lua", ".json", ".txt", ".info", ".png", ".fbx"}, "Unexpected runtime file: " + name)
    info = source["42/mod.info"].decode("utf-8")
    require(f"id={MOD}\n" in info and f"modversion={version}\n" in info, "Wrong runtime identity/version")
    require("icon=icon.png\n" in info and "poster=thumbnail.png\n" in info, "Wrong artwork references")
    require(sha(source["thumbnail.png"]) == THUMBNAIL, "Thumbnail changed")
    require(sha(source["42/icon.png"]) == ICON, "Approved icon changed")
    require(sha((ROOT / "art/source/ModIcon-v1.png").read_bytes()) == ICON, "Icon master mismatch")
    with Image.open(ROOT / "src" / MOD / "42/icon.png") as image:
        require(image.mode == "RGBA" and image.size == (1254, 1254), "Wrong icon format")
        require(image.getchannel("A").getextrema() == (0, 255), "Icon lacks true transparency")
        require(all(image.getpixel(point)[3] == 0 for point in ((0, 0), (1253, 0), (0, 1253), (1253, 1253))), "Filled icon corners")
    expected = {f"Contents/mods/{MOD}/{name}": data for name, data in source.items()}
    for name in ("preview.png", "workshop.txt"):
        expected[name] = (ROOT / name).read_bytes()
    require(sha(expected["preview.png"]) == THUMBNAIL, "Preview changed")
    require(len(expected) == len({name.casefold() for name in expected}), "Case collision")
    description = (ROOT / "WORKSHOP_DESCRIPTION.txt").read_text(encoding="utf-8")
    changes = (ROOT / "WORKSHOP_CHANGE_NOTE.txt").read_text(encoding="utf-8").split("[h2]Historical change notes[/h2]", 1)[0].strip() + "\n"
    require(description == (ROOT / "docs/STEAM_WORKSHOP_DESCRIPTION.txt").read_text(encoding="utf-8"), "Description mirror differs")
    legacy = expected["workshop.txt"].decode("utf-8").splitlines()
    require("\n".join(row[len("description="):] for row in legacy if row.startswith("description=")) + "\n" == description, "Workshop description serialization differs")
    for text in (description, changes):
        require(LABEL in text and version in text and "\\n" not in text and "\n\n" in text, "Invalid test distribution text/newlines")
        require(not re.search(r"\bTODO\b|YOUR_[A-Z_]+", text), "Unreviewed publication placeholder")
    require("[b]Mod ID:[/b] B47ANCEDPower" in description, "Wrong description Mod ID")
    require("https://github.com/B47ANCE/B47ANCEDPower" in description, "Missing verified source URL")
    return version, expected, description, changes


def verify(stage, package, expected):
    require(inventory(stage) == expected, "Staging/source mismatch or unexpected file")
    with zipfile.ZipFile(package) as archive:
        members = archive.infolist()
        names = [member.filename for member in members]
        require(len(names) == len(set(names)) == len({name.casefold() for name in names}), "Duplicate/case-colliding ZIP members")
        require(set(names) == set(expected), "Unexpected/missing ZIP members")
        for member in members:
            path = PurePosixPath(member.filename)
            require(not path.is_absolute() and ".." not in path.parts and "\\" not in member.filename and not re.match(r"^[A-Za-z]:", member.filename), "Unsafe ZIP path")
            require(not stat.S_ISLNK(member.external_attr >> 16), "Linked ZIP member")
            require(archive.read(member) == expected[member.filename], "ZIP/source mismatch")
        require(archive.testzip() is None, "ZIP CRC/data failure")


def quote(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--verify", action="store_true", help="Read-only verification of existing immutable artifacts")
    args = parser.parse_args()
    version, expected, description, changes = inputs()
    dist = ROOT / "dist"
    stage = dist / f"workshop-{version}"
    package = dist / "current" / f"{MOD}-{version}-workshop-ready.zip"
    manifest_path = dist / f"RELEASE-{version}.json"
    vdf = dist / f"{MOD}-{version}.vdf"
    # Match this project's established SteamCMD layout: upload Contents/, not its parent.
    # Omit previewfile/visibility/tags to preserve existing remote artwork/settings.
    values = {"appid": "108600", "publishedfileid": ITEM,
              "contentfolder": (stage / "Contents").as_posix(),
              "title": "B47ANCE'd Power", "description": description, "changenote": changes}
    text = '"workshopitem"\n{\n' + "".join(f"    {quote(key)} {quote(value)}\n" for key, value in values.items()) + "}\n"
    tokens = [json.loads(token, strict=False) for token in re.findall(r'"(?:\\.|[^"\\])*"', text, re.S)]
    require(tokens[0] == "workshopitem" and dict(zip(tokens[1::2], tokens[2::2])) == values, "VDF/newline roundtrip failed")
    if not args.verify:
        require(not git("status", "--porcelain"), "Commit reviewed source before packaging")
        require(not any(path.exists() for path in (stage, package, manifest_path, vdf)), "Artifacts already exist; verify without overwriting")
        for name, data in expected.items():
            path = stage / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        package.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(package, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name, data in sorted(expected.items()):
                member = zipfile.ZipInfo(name, date_time=(2026, 10, 18, 0, 0, 0))
                member.compress_type = zipfile.ZIP_DEFLATED
                member.external_attr = (stat.S_IFREG | 0o644) << 16
                archive.writestr(member, data)
        verify(stage, package, expected)
        manifest = {"project_version": version, "mod_id": MOD, "workshop_id": ITEM, "appid": "108600",
                    "source_commit": git("rev-parse", "HEAD"), "github": "https://github.com/B47ANCE/B47ANCEDPower",
                    "package": package.name, "package_sha256": sha(package.read_bytes()),
                    "minimum_game_version": "42.20.3", "installed_steam_build_id": "25485521",
                    "engine_version": "UNKNOWN; no game launch", "distribution": LABEL,
                    "SP": "NOT TESTED", "G7": "NOT TESTED / BLOCKED", "stable_G8": "BLOCKED",
                    "thumbnail_sha256": THUMBNAIL, "icon_sha256": ICON,
                    "files": {name: sha(data) for name, data in sorted(expected.items())}}
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        vdf.write_text(text, encoding="utf-8", newline="\n")
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    require(manifest["project_version"] == version and manifest["mod_id"] == MOD and manifest["workshop_id"] == ITEM and manifest["appid"] == "108600", "Manifest identity differs")
    require(manifest["package_sha256"] == sha(package.read_bytes()), "Package hash differs")
    require(manifest["files"] == {name: sha(data) for name, data in sorted(expected.items())}, "Manifest/source hashes differ")
    for name, data in expected.items():
        relative = name.replace(f"Contents/mods/{MOD}/", f"src/{MOD}/", 1) if name.startswith("Contents/") else name
        committed = subprocess.check_output(["git", "show", f"{manifest['source_commit']}:{relative}"], cwd=ROOT)
        require(committed == data, "Manifest commit/payload mismatch: " + relative)
    require(vdf.read_text(encoding="utf-8") == text, "Descriptor differs")
    verify(stage, package, expected)
    print(json.dumps({"version": version, "files": len(expected), "package_sha256": manifest["package_sha256"],
                      "source_commit": manifest["source_commit"], "integrity": "PASS", "preview": "unchanged; remote replacement omitted",
                      "G7": "NOT TESTED / BLOCKED", "stable_G8": "BLOCKED"}, indent=2))


if __name__ == "__main__":
    main()
