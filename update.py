#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.request import Request, urlopen

RELEASES_URL = "https://api.multiviewer.app/api/v1/releases/latest/"

LATEST_DOWNLOAD_URL = (
    "https://api.multiviewer.app/api/v1/releases/latest/linux/download"
)

headers = {
    "User-Agent": "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.7) Gecko/2009021910 Firefox/3.0.7",
}


def version_from_last_tag():
    return subprocess.check_output(
        ("git", "describe", "--tags"),
        text=True,
    ).strip().replace("v", "")


def get_latest_releases():
    req = Request(RELEASES_URL, headers=headers)
    with urlopen(req) as response:
        return json.loads(response.read())


def compute_sha256(url):
    nix_expr = f"""
    with import <nixpkgs> {{}};
    fetchzip {{
        url = "{url}";
        sha256 = lib.fakeSha256;
    }}
    """
    nix_output = subprocess.run(
        ("nix-build", "-E", nix_expr),
        text=True,
        stderr=subprocess.PIPE,
    ).stderr
    return nix_output.splitlines()[-1].split("got:")[-1].strip()

def update_default_nix(version,url, sha256):
    print('modifying default.nix')
    default_path = Path(__file__).parent / "default.nix"
    default = default_path.read_text()
    for v, value in zip(('version', 'url',' hash'), (version,url,sha256)):
        default = re.sub(rf'{v} = "(.*)"', f'{v} = "{value}"', default)
    default_path.write_text(default)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--force",
        help="update default.nix with latest version matter what",
        action="store_true",
    )
    parser.add_argument("--commit", help="commit changes", action="store_true")
    parser.add_argument("--tag", help="tag new version", action="store_true")
    args = parser.parse_args()
    latest = get_latest_releases()
    current_version = version_from_last_tag()

    print("Latest Version:", latest["version"])
    print("Current Version:", current_version)
    if (current_version == latest["version"]) and not args.force:
        print("flake up to date")
        sys.exit(0)

    linux = [o for o in latest["downloads"] if o.get("platform") == "linux"][0]
    sha256 = compute_sha256(linux["url"])
    update_default_nix(latest['version'], linux['url'], sha256)


if __name__ == "__main__":
    main()
