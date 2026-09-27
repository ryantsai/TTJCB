"""Sign the Rive game locally and push the static host to GitHub Pages.

The dedicated gh-pages branch contains only release assets. Git plumbing keeps
the source checkout and its current branch untouched during publication.
"""

from __future__ import annotations

from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "web"
DIST = WEB / "dist"
REPO = "ryantsai/TTJCB"
ASSETS = (
    "index.html",
    "game.js",
    "game.riv",
    "rive.wasm",
    "noto-sans-tc.woff2",
)


def command(*args: str, cwd: Path = ROOT, input_data: bytes | None = None,
            check: bool = True) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(args, cwd=cwd, input=input_data, stdout=subprocess.PIPE,
                          check=check)


def output(*args: str, input_data: bytes | None = None) -> str:
    return command(*args, input_data=input_data).stdout.decode().strip()


def main() -> None:
    actual = output("gh", "repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner")
    if actual != REPO:
        raise RuntimeError(f"Refusing to publish {actual}; expected {REPO}.")

    if not (WEB / "node_modules" / "esbuild").is_dir():
        print("Installing browser host dependencies...", flush=True)
        subprocess.run(("npm", "ci"), cwd=WEB, check=True)
    print("Signing and building the web game...", flush=True)
    subprocess.run(("npm", "run", "build"), cwd=WEB, check=True)
    for name in ASSETS:
        if not (DIST / name).is_file() or (DIST / name).stat().st_size == 0:
            raise RuntimeError(f"Missing release asset: {name}")

    blobs = {name: output("git", "hash-object", "-w", str(DIST / name)) for name in ASSETS}
    blobs[".nojekyll"] = output("git", "hash-object", "-w", "--stdin", input_data=b"")
    tree_data = "".join(f"100644 blob {blobs[name]}\t{name}\n" for name in sorted(blobs))
    tree = output("git", "mktree", input_data=tree_data.encode())

    existing = command("git", "ls-remote", "--exit-code", "origin", "refs/heads/gh-pages",
                       check=False)
    if existing.returncode not in (0, 2):
        raise RuntimeError("Could not read the existing gh-pages branch.")
    parent: list[str] = []
    if existing.returncode == 0:
        command("git", "fetch", "origin", "refs/heads/gh-pages")
        commit = output("git", "rev-parse", "FETCH_HEAD")
        if output("git", "rev-parse", f"{commit}^{{tree}}") == tree:
            print(f"GitHub Pages already contains this build ({commit[:12]}).")
            return
        parent = ["-p", commit]

    commit = output("git", "commit-tree", tree, *parent,
                    "-m", "Deploy signed Teen Titans: Jump City Brawl web build")
    subprocess.run(("git", "push", "origin", f"{commit}:refs/heads/gh-pages"),
                   cwd=ROOT, check=True)
    print(f"Pushed {commit[:12]} to gh-pages for https://ryantsai.github.io/TTJCB/")


if __name__ == "__main__":
    main()
