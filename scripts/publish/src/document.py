import re
from pathlib import Path
import markdown
from pdf import Pdf
from word import Word


class Document:
    """Domain model representing a markdown document with formatting and publishing affordances."""

    def __init__(
        self,
        text: str,
        context: Path | str = ".",
        source_path: Path | str | None = None,
    ):
        self.text = text
        self.context = Path(context).resolve()
        self.source_path = Path(source_path).resolve() if source_path else None

    def format(self) -> str:
        """Transforms markdown text into sanitized HTML with callouts and syntax extensions."""
        clean = re.sub(
            r">\s*\[!(NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]",
            r"> **[\1]**",
            self.text,
        )
        return markdown.markdown(
            clean,
            extensions=[
                "tables",
                "fenced_code",
                "codehilite",
                "nl2br",
                "sane_lists",
            ],
        )

    def publish(self, format: str, target: Path | str) -> Path:
        """Publishes the document to a target file path in PDF or DOCX format."""
        target_path = Path(target).resolve()

        if target_path.suffix.lower() in [".md", ".markdown"]:
            raise ValueError(
                f"Target '{target_path.name}' cannot be a Markdown file (.md / .markdown)."
            )

        if self.source_path and target_path == self.source_path:
            raise ValueError(
                f"Target '{target_path.name}' cannot overwrite the source Markdown file."
            )

        html = self.format()

        if format == "pdf":
            Pdf.render(html, target_path, base=self.context)
        elif format == "docx":
            Word.render(html, target_path)
        else:
            raise ValueError(f"Unsupported format: {format}. Must be 'pdf' or 'docx'.")

        return target_path
