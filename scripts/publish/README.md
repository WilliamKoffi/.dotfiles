# publish

High-fidelity Markdown to PDF & DOCX publisher CLI tool built with [WeasyPrint](https://weasyprint.org/), [python-docx](https://python-docx.readthedocs.io/), [Markdown](https://python-markdown.github.io/), and [BeautifulSoup](https://www.crummy.com/software/BeautifulSoup/). Managed seamlessly with [uv](https://docs.astral.sh/uv/) using [PEP 723](https://peps.python.org/pep-0723/) inline script metadata.

The tool lives at `~/.dotfiles/scripts/publish/publish` and is symlinked to `~/.local/bin/publish` so it is instantly available across your system without requiring manual virtual environment setup or global package installation.

---

## Features

- **Zero-Setup Execution**: Uses `uv run --script` to automatically download, resolve, and cache dependencies (`python-docx`, `markdown`, `weasyprint`, `beautifulsoup4`, `pygments`) in an isolated environment.
- **Affordance-Driven Architecture**: Structured around domain entities (`Document`) with `format()` and `publish()` affordances, with clean stateless namespaces (`Pdf`, `Word`) under `src/`.
- **Dual Output Engines**:
  - **PDF**: High-fidelity print stylesheet using `@page` rules, Plus Jakarta Sans, JetBrains Mono, callout boxes, and page counters.
  - **DOCX**: Native Microsoft Word elements with customized headings, styled tables, code callout boxes, custom lists, and XML shading.
- **Batch & Directory Support**: Convert a single file, multiple files via arguments/globs, or all `.md` files in the current folder and `./docs`.
- **Both Formats in One Pass**: Use `-f both` to generate PDF and DOCX simultaneously.
- **Robust Error Handling**: Clean error reporting by default with `--verbose` diagnostics on demand.

---

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (installed on `PATH`)

No manual `pip install` is needed; `uv` handles everything on first invocation.

---

## Structure

```
~/.dotfiles/scripts/publish/
├── README.md
├── publish            # Executable script with PEP 723 metadata & sys.path resolution
└── src/
    ├── cli.py         # Argument parsing & CLI runner
    ├── colors.py      # Terminal ANSI formatting colors
    ├── document.py    # Document domain entity (format & publish affordances)
    ├── pdf.py         # Stateless PDF rendering namespace (WeasyPrint)
    └── word.py        # Stateless DOCX rendering namespace (python-docx)
```

---

## Installation & PATH Integration

1. **Source Script**: `~/.dotfiles/scripts/publish/publish`
2. **Symlink in PATH**: `~/.local/bin/publish`
3. **Stow Ignore**: `scripts/.stow-local-ignore` ensures GNU Stow does not link `scripts/publish/` directly into your home folder root.

---

## Usage

```bash
publish [inputs...] [options]
```

### Options

| Flag / Option | Description |
|---|---|
| `inputs...` | One or more Markdown files or directory paths to publish. (Defaults to `*.md` and `docs/*.md`). |
| `-f, --format <pdf\|docx\|both>` | Output format (`pdf`, `docx`, or `both`, default: `pdf`). |
| `-o, --target, --output <path>` | Custom output file path (single file only). |
| `-d, --dir <path>` | Destination directory for generated files. |
| `-q, --quiet` | Suppress non-error progress messages. |
| `-v, --verbose` | Display detailed diagnostic traces on error. |
| `-V, --version` | Display version information. |
| `-h, --help` | Display usage help. |

---

## Examples

### 1. Default Directory Run

Convert all `.md` files in the current directory and `./docs` to PDF:
```bash
publish
```

### 2. Single File Conversion

```bash
# Convert to PDF (default)
publish README.md

# Convert to Word (.docx)
publish report.md -f docx

# Convert to both PDF and DOCX
publish notes.md -f both
```

### 3. Custom Output Target or Directory

```bash
# Specify explicit output filename
publish documentation.md -o guide.pdf

# Output all converted files into a specific folder
publish *.md -d ./dist -f both
```

### 4. Batch Publishing a Folder

```bash
publish ./docs -d ./exports -f pdf
```
