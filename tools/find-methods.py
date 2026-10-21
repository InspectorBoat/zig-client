#!/usr/bin/env python3
r"""Find Java method declarations by name and return type, grouped by declaring file.

    tools/find-methods.py NAME_REGEX RETURN_REGEX
    tools/find-methods.py 'canBePlaced' '^boolean$'
    tools/find-methods.py '^canBePlaced$' '^boolean$' -b
    tools/find-methods.py 'canBePlaced' '^boolean$' -F '^Item\.java$'

Defaults to the decompiled vanilla tree. NAME_REGEX and RETURN_REGEX are matched
against the declaration text as it appears on the line, so anchor them if you want
an exact type (^boolean$) rather than a substring match. -F restricts the search to
files whose name matches FILE_REGEX.
"""
import argparse
import pathlib
import re
import sys

DEFAULT_ROOT = (
    pathlib.Path(__file__).resolve().parent.parent
    / "ornithe-mod-template"
    / "build"
    / "decompiled"
)

# <modifiers> <return type> <name>( <params> )
JAVA_DECL = re.compile(
    r"^\s*(?P<mods>(?:public|protected|private|static|final|abstract|native|synchronized|default|strictfp)\s+)*"
    r"(?P<ret>[\w.$<>\[\],?\s]+?)\s+"
    r"(?P<name>[A-Za-z_$][\w$]*)\s*\("
)


def body_end(lines, start):
    """Line index of the closing brace of a body opened before `start`, or None."""
    depth = 0
    opened = False
    for i in range(start, len(lines)):
        for ch in lines[i]:
            if ch == "{":
                depth += 1
                opened = True
            elif ch == "}":
                depth -= 1
                if opened and depth == 0:
                    return i
    return None


def find(path, name_re, ret_re, bodies):
    """Yield (lineno, lines_of_match) for each declaration in path."""
    lines = path.read_text(errors="replace").splitlines()
    for i, line in enumerate(lines):
        m = JAVA_DECL.match(line)
        if not m:
            continue
        if not name_re.search(m.group("name")):
            continue
        if not ret_re.search(m.group("ret").strip()):
            continue
        end = i
        if bodies and "{" in line:
            close = body_end(lines, i)
            if close is not None:
                end = close
        yield i + 1, [l.rstrip() for l in lines[i : end + 1]]


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("name_regex")
    ap.add_argument("return_regex")
    ap.add_argument(
        "-r",
        "--root",
        default=DEFAULT_ROOT,
        help=f"directory to search (default: {DEFAULT_ROOT})",
    )
    ap.add_argument(
        "-F",
        "--file-regex",
        default=None,
        help="only search files whose name matches this regex",
    )
    ap.add_argument(
        "-b",
        "--bodies",
        action="store_true",
        help="print each match's full body instead of just the declaration",
    )
    ap.add_argument("-l", "--files-only", action="store_true", help="list files only")
    args = ap.parse_args()

    root = pathlib.Path(args.root)
    if not root.is_dir():
        sys.exit(f"error: not a directory: {root}")

    name_re = re.compile(args.name_regex)
    ret_re = re.compile(args.return_regex)
    file_re = re.compile(args.file_regex) if args.file_regex else None

    total = 0
    found_any = False
    for path in sorted(root.rglob("*.java")):
        if not path.is_file():
            continue
        if file_re is not None and not file_re.search(path.name):
            continue
        hits = list(find(path, name_re, ret_re, args.bodies))
        if not hits:
            continue
        found_any = True
        rel = path.relative_to(root)
        if args.files_only:
            print(rel)
        else:
            print(f"{rel}")
            for lineno, block in hits:
                for off, text in enumerate(block):
                    print(f"  {lineno + off}: {text}")
        total += len(hits)

    if not found_any:
        print(f"no matches for name={args.name_regex!r} return={args.return_regex!r}", file=sys.stderr)
        return 1
    print(f"\n{total} match(es)", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())