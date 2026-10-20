#!/usr/bin/env python3
"""Read classic Mac resource forks and decode EV using its embedded TMPLs.

Accepts a folder unpacked with `unar -k visible`. Uses only Python's standard
library. It never executes or modifies the original game. Numeric values retain
the original units; this tool does not infer engine semantics from field names.
"""

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct


def take(data, offset, size):
    if offset < 0 or size < 0 or offset + size > len(data):
        raise ValueError(f"Invalid byte range {offset}+{size} in {len(data)} bytes")
    return data[offset:offset + size]


def unpack(fmt, data, offset):
    return struct.unpack(fmt, take(data, offset, struct.calcsize(fmt)))


def resource_fork(data):
    """Unwrap an AppleDouble container, or accept a bare resource fork."""
    if take(data, 0, 4) != bytes.fromhex("00051607"):
        return data
    count, = unpack(">H", data, 24)
    for i in range(count):
        kind, offset, size = unpack(">III", data, 26 + 12 * i)
        if kind == 2:
            return take(data, offset, size)
    raise ValueError("AppleDouble file has no resource fork")


def read_resources(data):
    data = resource_fork(data)
    data_offset, map_offset, data_size, map_size = unpack(">IIII", data, 0)
    body = take(data, data_offset, data_size)
    resource_map = take(data, map_offset, map_size)
    type_offset, name_offset = unpack(">HH", resource_map, 24)
    types = take(resource_map, type_offset, len(resource_map) - type_offset)
    names = take(resource_map, name_offset, len(resource_map) - name_offset)
    last_type, = unpack(">h", types, 0)
    if last_type < -1:
        raise ValueError("Invalid resource type count")
    result = []
    seen = set()
    for i in range(last_type + 1):
        kind, last_resource, reference_offset = unpack(">4sHH", types, 2 + 8 * i)
        kind = kind.decode("mac_roman")
        for j in range(last_resource + 1):
            ref = take(types, reference_offset + 12 * j, 12)
            rid, name_pos = unpack(">hH", ref, 0)
            name = ""
            if name_pos != 0xFFFF:
                size = take(names, name_pos, 1)[0]
                name = take(names, name_pos + 1, size).decode("mac_roman")
            pos = int.from_bytes(ref[5:8], "big")
            size, = unpack(">I", body, pos)
            payload = take(body, pos + 4, size)
            if (kind, rid) in seen:
                raise ValueError(f"Duplicate resource {kind}/{rid}")
            seen.add((kind, rid))
            result.append({"type": kind, "id": rid, "name": name,
                           "attributes": ref[4], "size": size,
                           "sha256": hashlib.sha256(payload).hexdigest(),
                           "data": payload})
    return result


def read_template(data):
    fields = []
    pos = 0
    while pos < len(data):
        size = take(data, pos, 1)[0]
        label = take(data, pos + 1, size).decode("mac_roman")
        pos += 1 + size
        kind = take(data, pos, 4).decode("mac_roman")
        pos += 4
        fields.append({"name": label, "encoding": kind})
    return fields


def decode_template(data, fields):
    values = {}
    offsets = {}
    pos = 0
    formats = {"DWRD": ">h", "HWRD": ">H", "DLNG": ">i",
               "HLNG": ">I", "RECT": ">hhhh"}
    for field in fields:
        label, kind = field["name"], field["encoding"]
        if label in values:
            raise ValueError(f"Repeated template field {label}")
        offsets[label] = pos
        if kind in formats:
            fmt = formats[kind]
            value = unpack(fmt, data, pos)
            values[label] = list(value) if kind == "RECT" else value[0]
            pos += struct.calcsize(fmt)
        elif kind == "CSTR":
            end = data.find(b"\0", pos)
            if end == -1:
                raise ValueError("Unterminated CSTR")
            values[label] = data[pos:end].decode("mac_roman")
            pos = end + 1
        else:
            raise ValueError(f"Unsupported template encoding {kind}")
    return {"fields": values, "field_offsets": offsets,
            "decoded_bytes": pos, "trailing_bytes": len(data) - pos,
            "trailing_hex": data[pos:].hex()}


def decode_strings(data):
    count, = unpack(">H", data, 0)
    pos = 2
    strings = []
    for _ in range(count):
        size = take(data, pos, 1)[0]
        strings.append(take(data, pos + 1, size).decode("mac_roman"))
        pos += 1 + size
    return {"strings": strings, "decoded_bytes": pos,
            "trailing_bytes": len(data) - pos}


def metadata(resource):
    return {k: v for k, v in resource.items() if k != "data"}


def write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")


def inspect(source, output):
    files = {}
    templates = {}
    template_sources = {}
    for path in sorted(source.rglob("*.rsrc")):
        relative = path.relative_to(source).as_posix()
        try:
            files[relative] = read_resources(path.read_bytes())
        except (ValueError, struct.error) as exc:
            raise ValueError(f"{relative}: {exc}") from exc
        for res in files[relative]:
            if res["type"] == "TMPL":
                template = read_template(res["data"])
                if res["name"] in templates and templates[res["name"]] != template:
                    raise ValueError(f"Conflicting templates for {res['name']}")
                templates[res["name"]] = template
                template_sources.setdefault(res["name"], []).append(
                    {"file": relative, "id": res["id"], "sha256": res["sha256"]})

    decoded = {}
    warnings = []
    inventory = {}
    for relative, resources in files.items():
        decoded[relative] = []
        inventory[relative] = {
            "sha256": hashlib.sha256((source / relative).read_bytes()).hexdigest(),
            "resource_count": len(resources),
            "types": dict(sorted(Counter(r["type"] for r in resources).items())),
            "resources": [metadata(r) for r in resources],
        }
        for res in resources:
            item = metadata(res)
            try:
                if res["type"] in templates:
                    item.update(decode_template(res["data"], templates[res["type"]]))
                elif res["type"] == "STR#":
                    item.update(decode_strings(res["data"]))
                elif res["type"] == "TEXT":
                    item["text"] = res["data"].decode("mac_roman").replace("\r", "\n")
                else:
                    continue
                if item.get("trailing_bytes", 0):
                    warnings.append({"file": relative, "type": res["type"],
                                     "id": res["id"], "trailing_bytes": item["trailing_bytes"]})
                decoded[relative].append(item)
            except ValueError as exc:
                raise ValueError(f"{relative}: {res['type']}/{res['id']}: {exc}") from exc

    write_json(output / "inventory.json", inventory)
    write_json(output / "templates.json", {k: {"fields": v, "sources": template_sources[k]}
                                           for k, v in templates.items()})
    write_json(output / "decoded.json", decoded)
    write_json(output / "validation.json", {
        "resource_files": len(files),
        "resources": sum(len(v) for v in files.values()),
        "templates": len(templates),
        "decoded_records": sum(len(v) for v in decoded.values()),
        "uninterpreted_trailing_bytes": warnings,
        "notes": ["Numbers retain original storage units.",
                  "RECT template values are four signed 16-bit integers; their meaning depends on the field.",
                  "Any trailing bytes are preserved in decoded records and not interpreted.",
                  "Successful field decoding does not verify executable behavior."]})
    for relative, item in inventory.items():
        print(relative, item["types"])
    print(f"Validated {len(files)} resource files; {len(warnings)} records have trailing bytes.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--output", type=Path, default=Path("research/decoded"))
    args = parser.parse_args()
    inspect(args.source, args.output)
