"""Sign and prepare site/ for GitHub Pages deployment from main.

Review and commit the generated assets, then push main to deploy through Actions.
"""

from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "web"
DIST = WEB / "dist"
SITE = ROOT / "site"
ASSETS = ("index.html", "game.js", "game.riv", "rive.wasm", "noto-sans-tc.woff2", "noto-sans-jp.woff2")


def main() -> None:
    if not (WEB / "node_modules" / "esbuild").is_dir():
        subprocess.run(("npm", "ci"), cwd=WEB, check=True)
    subprocess.run(("npm", "run", "build"), cwd=WEB, check=True)
    for name in ASSETS:
        if not (DIST / name).is_file() or (DIST / name).stat().st_size == 0:
            raise RuntimeError(f"Missing release asset: {name}")
    SITE.mkdir(exist_ok=True)
    for name in ASSETS:
        shutil.copy2(DIST / name, SITE / name)
    (SITE / ".nojekyll").touch()
    print("Signed release ready in site/. Commit the source and site/ changes, "
          "then push main to deploy GitHub Pages.")


if __name__ == "__main__":
    main()
