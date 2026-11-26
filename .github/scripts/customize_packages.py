#!/usr/bin/env python3
"""Set the Sileo-facing name, description and icon for the Mochy package."""
from pathlib import Path
import sys

PACKAGE_ID = "com.puc.mochyios"
CUSTOM_FIELDS = {
    "Name": "Translated Mochy iOS",
    "Icon": "https://35767686.github.io/4nn0yys-repo/PackageIcon.png",
    "Description": (
        "A community-maintained Turkish localization of Mochy Music for iOS. "
        "Explore music and use YouTube Music browsing and playback features "
        "through a translated interface with language and region preferences."
    ),
}


def field_value(lines: list[str], field: str) -> str | None:
    prefix = field + ":"
    for line in lines:
        if line.startswith(prefix):
            return line[len(prefix):].strip()
    return None


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: customize_packages.py PATH_TO_PACKAGES", file=sys.stderr)
        return 2

    path = Path(sys.argv[1])
    if not path.is_file():
        print(f"Packages index not found: {path}", file=sys.stderr)
        return 2

    text = path.read_text(encoding="utf-8")
    paragraphs = [p for p in text.strip().split("\n\n") if p.strip()]
    found = False
    updated: list[str] = []

    for paragraph in paragraphs:
        lines = paragraph.splitlines()
        if field_value(lines, "Package") != PACKAGE_ID:
            updated.append(paragraph)
            continue

        found = True
        fields_to_replace = set(CUSTOM_FIELDS) | {"Description-md5"}
        kept: list[str] = []
        skip_continuation = False
        for line in lines:
            if line[:1].isspace() and skip_continuation:
                continue
            skip_continuation = False
            key, separator, _ = line.partition(":")
            if separator and key in fields_to_replace:
                skip_continuation = True
                continue
            kept.append(line)

        # Place the human-readable fields close to the Package identifier.
        package_line = next(i for i, line in enumerate(kept) if line.startswith("Package:"))
        custom_lines = [f"{key}: {value}" for key, value in CUSTOM_FIELDS.items()]
        kept[package_line + 1:package_line + 1] = custom_lines
        updated.append("\n".join(kept))

    if not found:
        print(f"No package entry found for {PACKAGE_ID}; refusing to publish unbranded metadata.", file=sys.stderr)
        return 1

    path.write_text("\n\n".join(updated) + "\n", encoding="utf-8")
    print(f"Customized Sileo metadata for {PACKAGE_ID}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
