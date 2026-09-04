import argparse
import os
import sys
import traceback
from pathlib import Path
from colors import Colors
from document import Document

VERSION = "1.0.0"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="publish",
        description="High-fidelity Markdown to PDF & DOCX publisher CLI tool.",
    )
    parser.add_argument(
        "inputs",
        nargs="*",
        help="Markdown files or directories to publish (defaults to *.md and docs/*.md).",
    )
    parser.add_argument(
        "-f", "--format",
        choices=["pdf", "docx", "both"],
        default="pdf",
        help="Output format: 'pdf', 'docx', or 'both' (default: pdf).",
    )
    parser.add_argument(
        "-o", "--target", "--output",
        dest="target",
        help="Specific output target path (single file only).",
    )
    parser.add_argument(
        "-d", "--dir",
        help="Destination directory for published files.",
    )
    parser.add_argument(
        "-q", "--quiet",
        action="store_true",
        help="Suppress non-error output.",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Display detailed diagnostic traces on error.",
    )
    parser.add_argument(
        "-V", "--version",
        action="version",
        version=f"publish {VERSION}",
    )
    return parser


def discover_sources(inputs: list[str]) -> list[Path]:
    sources: list[Path] = []
    if inputs:
        for item in inputs:
            p = Path(item)
            if p.is_dir():
                sources.extend(sorted(p.glob("*.md")))
                sources.extend(sorted(p.glob("*.markdown")))
            elif p.is_file():
                if p.suffix.lower() not in [".md", ".markdown"]:
                    print(
                        f"{Colors.YELLOW}⚠️  Warning: Skipping non-markdown file: {item}{Colors.RESET}",
                        file=sys.stderr,
                    )
                    continue
                sources.append(p)
            else:
                print(f"{Colors.YELLOW}⚠️  Warning: Path not found: {item}{Colors.RESET}", file=sys.stderr)
    else:
        current = Path.cwd()
        sources.extend(sorted(current.glob("*.md")))
        sources.extend(sorted(current.glob("*.markdown")))
        docs = current / "docs"
        if docs.exists() and docs.is_dir():
            sources.extend(sorted(docs.glob("*.md")))
            sources.extend(sorted(docs.glob("*.markdown")))

    # Deduplicate while preserving order
    seen: set[Path] = set()
    unique_sources: list[Path] = []
    for s in sources:
        resolved = s.resolve()
        if resolved not in seen:
            seen.add(resolved)
            unique_sources.append(s)

    return unique_sources


def run() -> None:
    parser = build_parser()
    args = parser.parse_args()

    sources = discover_sources(args.inputs)
    if not sources:
        if not args.quiet:
            print(f"{Colors.YELLOW}ℹ️  No Markdown files found to convert.{Colors.RESET}")
        sys.exit(0)

    formats = ["pdf", "docx"] if args.format == "both" else [args.format]

    # Validate --target flag constraints early
    if args.target:
        if len(sources) > 1:
            print(
                f"{Colors.RED}❌ Error: --target/--output can only be used with a single input file (found {len(sources)}). Use --dir for batch output.{Colors.RESET}",
                file=sys.stderr,
            )
            sys.exit(1)
        if len(formats) > 1:
            print(
                f"{Colors.RED}❌ Error: --target/--output cannot be used when publishing multiple formats (-f both). Use --dir instead.{Colors.RESET}",
                file=sys.stderr,
            )
            sys.exit(1)

    if not args.quiet:
        fmt_label = " & ".join(f.upper() for f in formats)
        print(f"{Colors.CYAN}🚀 Publishing {len(sources)} document(s) to {fmt_label}...{Colors.RESET}\n")

    has_errors = False
    source_paths = {s.resolve() for s in sources}

    for source in sources:
        try:
            text = source.read_text(encoding="utf-8")
            document = Document(text, source.parent, source_path=source)

            for fmt in formats:
                if args.target:
                    target = Path(args.target)
                    if not target.suffix:
                        target = target.with_suffix(f".{fmt}")
                    elif target.suffix.lower() in [".md", ".markdown"]:
                        raise ValueError(f"Target '{target}' cannot be a Markdown file (.md / .markdown).")
                    elif target.suffix.lower() != f".{fmt}":
                        raise ValueError(
                            f"Target extension '{target.suffix}' does not match chosen format '{fmt}'."
                        )
                elif args.dir:
                    out_dir = Path(args.dir)
                    target = out_dir / source.with_suffix(f".{fmt}").name
                else:
                    target = source.with_suffix(f".{fmt}")

                # Guard against overwriting any source file or any markdown file
                if target.resolve() == source.resolve():
                    raise ValueError(f"Target path cannot be the same as source file '{source.name}'.")
                if target.resolve() in source_paths:
                    raise ValueError(f"Target path '{target.name}' matches an existing input Markdown file.")
                if target.suffix.lower() in [".md", ".markdown"]:
                    raise ValueError(f"Target '{target.name}' cannot have a Markdown extension.")

                output_path = document.publish(format=fmt, target=target)
                size_kb = output_path.stat().st_size / 1024

                if not args.quiet:
                    print(
                        f"  {Colors.GREEN}✅ [{fmt.upper()} Published]{Colors.RESET} "
                        f"{source.name} ➔ {output_path.name} ({size_kb:.1f} KB)"
                    )
        except Exception as err:
            has_errors = True
            print(f"  {Colors.RED}❌ [Error on {source.name}]: {err}{Colors.RESET}", file=sys.stderr)
            if args.verbose:
                traceback.print_exc()

    if not args.quiet and not has_errors:
        print(f"\n{Colors.GREEN}{Colors.BOLD}✨ Publishing completed successfully!{Colors.RESET}")

    if has_errors:
        sys.exit(1)
