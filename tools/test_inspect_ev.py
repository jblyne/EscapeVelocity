"""Small binary fixtures test offsets, encodings, and malformed input rejection."""

import struct
import unittest

from inspect_ev import decode_template, read_resources, read_template


def fork_fixture():
    payload = struct.pack(">hh", -1, 435)
    body = struct.pack(">I", len(payload)) + payload
    # One type, one resource, and one Pascal resource name.
    type_list = struct.pack(">H4sHH", 0, b"TEST", 0, 10)
    type_list += struct.pack(">hH", -42, 0) + bytes(8)
    name = b"\x06Sample"
    data_offset = 256
    map_offset = data_offset + len(body)
    map_size = 28 + len(type_list) + len(name)
    header = struct.pack(">IIII", data_offset, map_offset, len(body), map_size)
    resource_map = header + bytes(8) + struct.pack(">HH", 28, 28 + len(type_list))
    return header + bytes(240) + body + resource_map + type_list + name


class ReaderTests(unittest.TestCase):
    def test_bare_fork_and_negative_resource_id(self):
        rows = read_resources(fork_fixture())
        self.assertEqual(len(rows), 1)
        self.assertEqual((rows[0]["type"], rows[0]["id"], rows[0]["name"]),
                         ("TEST", -42, "Sample"))
        self.assertEqual(rows[0]["data"], struct.pack(">hh", -1, 435))

    def test_appledouble_wrapper(self):
        fork = fork_fixture()
        wrapper = struct.pack(">II16sHIII", 0x00051607, 0x00020000,
                              bytes(16), 1, 2, 38, len(fork))
        self.assertEqual(read_resources(wrapper + fork), read_resources(fork))

    def test_out_of_bounds_resource(self):
        data = bytearray(fork_fixture())
        struct.pack_into(">I", data, 256, 5000)
        with self.assertRaises(ValueError):
            read_resources(bytes(data))

    def test_truncated_map(self):
        with self.assertRaises(ValueError):
            read_resources(fork_fixture()[:-1])

    def test_signed_unsigned_and_rectangle_fields(self):
        template = read_template(b"\x01ADWRD\x01BHLNG\x01CRECT")
        decoded = decode_template(struct.pack(">hIhhhh", -1, 0x80000000, 1, -2, 3, 4), template)
        self.assertEqual(decoded["fields"], {"A": -1, "B": 0x80000000, "C": [1, -2, 3, 4]})
        self.assertEqual(decoded["field_offsets"], {"A": 0, "B": 2, "C": 6})
        self.assertEqual(decoded["trailing_bytes"], 0)

    def test_unsupported_field_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unsupported"):
            decode_template(bytes(4), [{"name": "Unknown", "encoding": "????"}])

    def test_unterminated_string_rejected(self):
        with self.assertRaisesRegex(ValueError, "Unterminated"):
            decode_template(b"abc", [{"name": "Text", "encoding": "CSTR"}])


if __name__ == "__main__":
    unittest.main()
