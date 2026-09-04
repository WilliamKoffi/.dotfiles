from pathlib import Path
from weasyprint import CSS, HTML

PRINT_CSS = """
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600&display=swap');

@page {
    size: A4;
    margin: 20mm 18mm 22mm 18mm;
    @bottom-right {
        content: "Page " counter(page) " / " counter(pages);
        font-family: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif;
        font-size: 8.5pt;
        color: #94a3b8;
    }
}

:root {
    --primary: #0284c7;
    --primary-dark: #0369a1;
    --text-dark: #0f172a;
    --text-body: #334155;
    --text-muted: #64748b;
    --bg-code: #f8fafc;
    --border-color: #e2e8f0;
}

body {
    font-family: 'Plus Jakarta Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 10pt;
    line-height: 1.6;
    color: var(--text-body);
}

h1, h2, h3, h4, h5, h6 { color: var(--text-dark); font-weight: 800; line-height: 1.25; break-after: avoid; }
h1 { font-size: 20pt; color: var(--primary); border-bottom: 2px solid var(--primary); padding-bottom: 6px; margin: 0 0 16px; }
h2 { font-size: 14pt; color: var(--primary-dark); border-bottom: 1px solid var(--border-color); padding-bottom: 4px; margin: 22px 0 10px; }
h3 { font-size: 11.5pt; margin: 16px 0 8px; }
h4 { font-size: 10.5pt; color: var(--text-muted); margin: 12px 0 6px; }
p { margin: 0 0 10px; }
a { color: var(--primary); text-decoration: none; font-weight: 600; }
code { font-family: 'JetBrains Mono', 'Consolas', monospace; font-size: 8.8pt; background-color: #f1f5f9; color: #0369a1; padding: 2px 5px; border-radius: 4px; border: 1px solid #e2e8f0; }
pre { background-color: var(--bg-code); border: 1px solid var(--border-color); border-left: 4px solid var(--primary); border-radius: 6px; padding: 10px 14px; overflow-x: auto; break-inside: avoid; margin: 12px 0; }
pre code { background-color: transparent; color: var(--text-dark); padding: 0; border: none; font-size: 8.5pt; line-height: 1.45; }
blockquote { border-left: 4px solid var(--primary); background-color: #f0f9ff; padding: 8px 14px; margin: 12px 0; border-radius: 0 6px 6px 0; font-style: italic; color: #0c4a6e; break-inside: avoid; }
blockquote p { margin: 0; }
ul, ol { margin: 0 0 10px; padding-left: 20px; }
li { margin-bottom: 4px; }
table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 9pt; break-inside: avoid; }
th, td { padding: 8px 10px; border: 1px solid var(--border-color); text-align: left; }
th { background-color: var(--primary); color: #ffffff; font-weight: 700; }
tr:nth-child(even) { background-color: #f8fafc; }
hr { border: none; border-top: 1px solid var(--border-color); margin: 20px 0; }
kbd { font-family: 'JetBrains Mono', monospace; font-size: 8pt; background: #e2e8f0; border: 1px solid #cbd5e1; border-radius: 3px; padding: 1px 4px; }
"""


class Pdf:
    """Stateless namespace for rendering HTML to print-quality PDF."""

    @staticmethod
    def render(html: str, target: str | Path, base: str | Path = "") -> None:
        """Renders an HTML string into a formatted PDF document."""
        out = Path(target).resolve()
        if out.suffix.lower() in [".md", ".markdown"]:
            raise ValueError(f"Cannot render PDF to a Markdown file: '{out.name}'")

        out.parent.mkdir(parents=True, exist_ok=True)

        full_html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{out.stem}</title>
</head>
<body>
    {html}
</body>
</html>"""

        document = HTML(string=full_html, base_url=str(base))
        style = CSS(string=PRINT_CSS)

        tmp_out = out.with_name(f".{out.name}.tmp")
        try:
            document.write_pdf(str(tmp_out), stylesheets=[style])
            tmp_out.replace(out)
        except Exception:
            if tmp_out.exists():
                tmp_out.unlink()
            raise
