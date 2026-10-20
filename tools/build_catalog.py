"""Convert the verified original resource dump into an engine-neutral catalog."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TYPES = {"shïp": "ships", "wëap": "weapons", "oütf": "outfits", "sÿst": "systems",
         "spöb": "objects", "gövt": "governments", "mïsn": "missions", "düde": "encounters", "përs": "persons", "öops": "events"}


def build():
    decoded = json.loads((ROOT / "research/decoded/decoded.json").read_text())
    records = decoded["EV Data.rsrc"]
    catalog = {name: {} for name in TYPES.values()}
    for record in records:
        if record["type"] in TYPES:
            catalog[TYPES[record["type"]]][str(record["id"])] = {
                "id": record["id"], "name": record["name"], "fields": record["fields"]}
    catalog["descriptions"] = {str(r["id"]): r["fields"]["Description"] for r in records if r["type"] == "dësc"}
    lists = {r["id"]: r["strings"] for r in records if r["type"] == "STR#"}
    catalog["strings"] = {str(k): v for k, v in lists.items()}
    # Original zero-based spob Type selects STR# 1100 and spin 300 + Type.
    spins = {r["id"]: r["fields"] for r in decoded["EV Graphics.rsrc"] if r["type"] == "spïn"}
    catalog["ship_graphics"] = {
        ship_id: {"sprite": spins[int(ship_id)]["SpritesID"],
                  "width": spins[int(ship_id)]["xSize"], "height": spins[int(ship_id)]["ySize"]}
        for ship_id in catalog["ships"]}
    catalog["stellar_types"] = {}
    for type_id, label in enumerate(lists[1100]):
        sprite = spins[300 + type_id]
        kind = "station" if "station" in label else ("moon" if "moon" in label else "planet")
        world_class = re.search(r"Class ([A-Z])", label)
        catalog["stellar_types"][str(type_id)] = {
            "id": type_id, "label": label.strip("()"), "kind": kind,
            "world_class": world_class[1] if world_class else "",
            "sprite": {"id": sprite["SpritesID"], "mask": sprite["MasksID"],
                       "width": sprite["xSize"], "height": sprite["ySize"]}}
    assert all(str(o["fields"]["Type"]) in catalog["stellar_types"] for o in catalog["objects"].values())
    catalog["commodities"] = [{"id": i, "name": name, "base_price": int(lists[4004][i])}
                              for i, name in enumerate(lists[4000][:6])]
    catalog["source"] = {"game": "Escape Velocity 1.0.5", "archive_sha1":
                         "33f09cd3abe8747aaabdfb5ea8d1943d8b4363d8",
                         "notice": "Original resource values; engine semantics are not implied."}
    for system in catalog["systems"].values():
        f = system["fields"]
        system["links"] = [f[f"Con{i}"] for i in range(1, 17) if f[f"Con{i}"] != -1]
        system["objects"] = [f[f"Nav{i}"] for i in range(1, 5) if f[f"Nav{i}"] != -1]
        assert all(str(i) in catalog["systems"] for i in system["links"])
        assert all(str(i) in catalog["objects"] for i in system["objects"])
    output = ROOT / "godot/data/original_catalog.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(catalog, ensure_ascii=False, separators=(",", ":")) + "\n")
    print(f"Built {output}: {len(catalog['systems'])} systems, {len(catalog['ships'])} ships")


if __name__ == "__main__":
    build()
