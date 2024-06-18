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


def extract_version(nix_expr):
    m = re.search(r'version.*=.*"(?P<version>.*)";', nix_expr)
    if m:
        return m.group("version")

    print("failed to read version from default.nix")
    sys.exit(0)


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


def update_default_nix(nix_expr, version, url, sha256):
    print("modifying default.nix")
    for v, value in zip(("version", "url", " hash"), (version, url, sha256)):
        nix_expr = re.sub(rf'{v} = "(.*)";', f'{v} = "{value}";', nix_expr)


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

    path_to_default = Path(__file__).parent / "default.nix"
    package_nix_expr = path_to_default.read_text()
    current_version = extract_version(package_nix_expr)

    print("Latest Version:", latest["version"])
    print("Current Version:", current_version)
    if (current_version == latest["version"]) and not args.force:
        print("flake up to date")
        sys.exit(0)

    linux = [o for o in latest["downloads"] if o.get("platform") == "linux"][0]
    sha256 = compute_sha256(linux["url"])
    update_default_nix(package_nix_expr, latest["version"], linux["url"], sha256)
    path_to_default.write_text(package_nix_expr)


if __name__ == "__main__":
    main()
