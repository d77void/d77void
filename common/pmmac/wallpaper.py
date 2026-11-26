"""Apply and persist pmMac's wallpaper and Matugen palette."""

import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
from tempfile import NamedTemporaryFile
import time

STATE_DIR = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "pmmac"
STATE_FILE = STATE_DIR / "wallpaper.json"
NAMESPACE = "pmmac"


def wallpaper_command(*args, **kwargs):
    return subprocess.run(["awww", *args], **kwargs)


def current_background():
    return wallpaper_command("query", "--namespace", NAMESPACE, capture_output=True, text=True, timeout=2)


def apply(path):
    query = current_background()
    if query.returncode:
        subprocess.Popen(
            ["awww-daemon", "--namespace", NAMESPACE, "--no-cache", "--quiet"],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
        for _ in range(40):
            time.sleep(0.1)
            if current_background().returncode == 0:
                break
        else:
            raise RuntimeError("awww-daemon did not start")
    wallpaper_command(
        "img", "--namespace", NAMESPACE, "--transition-type", "none", str(path),
        check=True, timeout=15,
    )


def palette(path):
    config = Path(__file__).with_name("matugen.toml")
    result = subprocess.check_output(
        ["matugen", "image", "--config", str(config), "--dry-run", "--json", "hex",
         "--source-color-index", "0", "--type", "scheme-vibrant", str(path)],
        text=True, timeout=20,
    )
    colors = json.loads(result)["colors"]
    roles = {"surface": "surface", "raised": "surface_container_high", "accent": "primary"}
    return {key: colors[role]["default"]["color"] for key, role in roles.items()}


def write_state(state):
    with NamedTemporaryFile("w", dir=STATE_DIR, delete=False) as output:
        temp = Path(output.name)
        try:
            json.dump(state, output)
            output.flush()
            os.fsync(output.fileno())
            os.replace(temp, STATE_FILE)
        finally:
            temp.unlink(missing_ok=True)


def main(command, value=None):
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with (STATE_DIR / "wallpaper.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = json.loads(STATE_FILE.read_text()) if STATE_FILE.exists() else {"mix": 0.5}
        if command == "restore":
            if state.get("path") and Path(state["path"]).is_file():
                query = current_background()
                if query.returncode or not query.stdout.strip() or any(
                        not line.endswith("currently displaying: image: " + state["path"])
                        for line in query.stdout.splitlines()
                ):
                    apply(state["path"])
        elif command == "apply":
            path = Path(value).resolve(strict=True)
            colors = palette(path)
            apply(path)
            state.update(path=str(path), palette=colors)
            write_state(state)
        elif command == "mix":
            state["mix"] = max(0, min(1, float(value)))
            write_state(state)
        else:
            raise ValueError("Unknown wallpaper action")


if __name__ == "__main__":
    try:
        main(*sys.argv[1:])
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as exc:
        sys.exit(str(exc))
