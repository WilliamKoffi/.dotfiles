# rmbg

AI-powered image background removal CLI tool built on [Rembg](https://github.com/danielgatis/rembg) and managed seamlessly with [uv](https://docs.astral.sh/uv/) using [PEP 723](https://peps.python.org/pep-0723/) inline script metadata.

The tool lives at `~/.dotfiles/scripts/rmbg/rmbg` and is symlinked to `~/.local/bin/rmbg` so it is instantly available across your system without requiring manual virtual environment setup or global `pip install` commands.

---

## Features

- **Zero-Setup Execution**: Uses `uv run --script` to automatically resolve, download, and cache dependencies (`rembg[cpu]`, `pillow`) in an isolated environment.
- **Single & Batch Processing**: Process a single image, multiple files via globs, or entire folders recursively.
- **Model Selection**: Switch between various AI models (`u2net`, `u2netp`, `isnet-general-use`, `isnet-anime`, `sam`, etc.).
- **Alpha Matting**: Fine edge-boundary refinement for complex foregrounds like hair, fur, or semi-transparent fabrics.
- **Custom Backgrounds**: Output transparent PNGs (default) or fill the removed background with solid colors (hex, RGB, or color names).
- **Safe & Deterministic**: Automatically enforces transparent formats (`.png` / `.webp`), prevents accidental overwrites without `--force`, and supports `--dry-run`.

---

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (installed on PATH)

No manual `pip install` is needed; `uv` handles everything on first invocation.

---

## Installation & PATH Integration

`rmbg` is part of your dotfiles repository:

1. **Source Script**: `~/.dotfiles/scripts/rmbg/rmbg`
2. **Symlink in PATH**: `~/.local/bin/rmbg`
3. **Stow Ignore**: `scripts/.stow-local-ignore` ensures GNU Stow does not link `scripts/rmbg/` directly into your home folder root.

---

## Usage

```bash
rmbg [inputs...] [options]
```

### Options

| Flag / Option | Description |
|---|---|
| `inputs...` | One or more image files or directory paths to process. |
| `-o, --output <path>` | Custom output file path (single image) or output directory (multiple images). |
| `-d, --dir <path>` | Process all images inside a given directory. |
| `-r, --recursive` | Recursively scan directories for images. |
| `-m, --model <name>` | AI model to use (default: `u2net`). See [Supported Models](#supported-models). |
| `-a, --alpha-matting` | Enable alpha matting for higher quality edge cutouts (e.g. hair). |
| `--af <0-255>` | Alpha matting foreground threshold (default: `240`). |
| `--ab <0-255>` | Alpha matting background threshold (default: `10`). |
| `--ae <int>` | Alpha matting erode size (default: `10`). |
| `--post-process-mask` | Clean up small holes and artifacts in the generated mask. |
| `--only-mask` | Generate only the binary mask rather than the transparent cutout. |
| `--bgcolor <color>` | Fill background with solid color (e.g. `white`, `#ffffff`, `255,255,255`). |
| `-f, --force, --overwrite` | Overwrite existing output files without skipping. |
| `--dry-run` | Show matched files and output targets without running AI inference. |
| `-q, --quiet` | Suppress non-error messages. |
| `-v, --verbose` | Show model loading time and per-image processing durations. |
| `-V, --version` | Display version information. |
| `-h, --help` | Display usage help. |

---

## Examples

### 1. Single Image

```bash
# Removes background and saves output to photo_nobg.png
rmbg photo.jpg

# Save to a specific output path
rmbg photo.jpg -o transparent.png
```

### 2. Batch Processing

```bash
# Process multiple images into an output directory
rmbg photo1.jpg photo2.png photo3.webp -o ./cleaned/

# Process all images matching a shell glob
rmbg *.jpg -o ./output/
```

### 3. Folder Processing

```bash
# Process all supported images in a folder
rmbg --dir ./my_photos -o ./transparent_photos

# Recursively scan subfolders
rmbg --dir ./assets --recursive -o ./assets_nobg
```

### 4. Alpha Matting for Fine Details (Hair / Fur)

```bash
rmbg portrait.jpg -a
```

### 5. Solid Background Fill

```bash
# White background for product photography
rmbg product.jpg --bgcolor white -o product_white.png

# Custom hex color
rmbg portrait.jpg --bgcolor "#f0f4f8"
```

### 6. Using Different AI Models

```bash
# Anime / Illustration model
rmbg character.png -m isnet-anime

# Fast lightweight model (lower memory / CPU usage)
rmbg icon.jpg -m u2netp
```

---

## Supported Models

- `u2net` (default): Pre-trained model for general use cases.
- `u2netp`: Lightweight version of `u2net` for faster execution.
- `u2net_human_seg`: Specifically trained for human segmentation.
- `u2net_cloth_seg`: Specifically trained for parsing clothes and garments.
- `isnet-general-use`: High-accuracy model for general use cases.
- `isnet-anime`: Optimized for anime illustrations and drawings.
- `birefnet-general`: High-resolution bilateral reference model.
- `sam`: Segment Anything Model.

---

## Tips & Notes

- **Output Formats**: Outputs are saved as `.png` (or `.webp`) to preserve transparent alpha layers. Formats like `.jpg` do not support transparency.
- **First Run Download**: On the first execution with a given model, `rembg` automatically downloads the model weights (~170MB for `u2net`). Subsequent runs use the local cache and start instantly.
- **Model Caching**: When processing multiple images in a single command, the AI model session is initialized once and reused across all images for maximum speed.
