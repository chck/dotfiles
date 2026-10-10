#!/usr/bin/env python3
"""Render the first <svg> of a diagram-design HTML file to an opaque PNG.

Usage: rasterize.py <diagram.html> <out.png> [--scale N] [--background CSS_COLOR]

The diagram-design exporter writes a transparent PNG, which is unreadable on a
dark theme (dark ink on a dark page). This renders the same element but fills
the background, so one image reads on both light and dark GitHub.

The source HTML is not modified: the fill is applied to the live DOM only.
"""

from __future__ import annotations

import argparse
import pathlib
import sys

INSTALL_HINT = """Playwright is not installed. To enable PNG export, run:
    pip install playwright
    playwright install chromium
Then run this script again."""


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("src", type=pathlib.Path)
    parser.add_argument("out", type=pathlib.Path)
    parser.add_argument("--scale", type=int, default=2, choices=(1, 2, 3))
    parser.add_argument("--background", default="#ffffff")
    args = parser.parse_args()

    try:
        from playwright.sync_api import sync_playwright
    except ModuleNotFoundError:
        print(INSTALL_HINT, file=sys.stderr)
        return 2

    if not args.src.is_file():
        print(f"{args.src}: no such file. Pass the diagram HTML that diagram-design wrote.", file=sys.stderr)
        return 1

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(device_scale_factor=args.scale)
        page.goto(f"file://{args.src.resolve()}")
        page.wait_for_load_state("networkidle")
        page.evaluate("document.fonts.ready")
        svg = page.locator("svg").first
        if svg.count() == 0:
            browser.close()
            print(f"{args.src}: no <svg> found. This is not a diagram-design file.", file=sys.stderr)
            return 1
        svg.evaluate("(el, bg) => { el.style.background = bg; }", args.background)
        svg.screenshot(path=str(args.out), omit_background=False)
        browser.close()

    print(args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
