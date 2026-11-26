"""Move windows into and out of a Niri workspace reserved by pmMac."""

import fcntl
import json
import os
from pathlib import Path
import socket
import sys
from tempfile import NamedTemporaryFile

STASH = "pmMac Hidden"


def request(socket_path, data):
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(3)
        client.connect(str(socket_path))
        client.sendall(json.dumps(data).encode() + b"\n")
        with client.makefile("r") as stream:
            reply = json.loads(stream.readline())
    if "Err" in reply:
        raise RuntimeError(reply["Err"])
    return reply["Ok"]


def action(socket_path, action_name, **args):
    return request(socket_path, {"Action": {action_name: args}})


def save(path, state):
    with NamedTemporaryFile("w", dir=path.parent, delete=False) as handle:
        temp = Path(handle.name)
        try:
            json.dump(state, handle)
            handle.flush()
            os.replace(temp, path)
        finally:
            temp.unlink(missing_ok=True)


def move(socket_path, window, workspace):
    action(socket_path, "MoveWindowToWorkspace",
           window_id=window, reference={"Id": workspace}, focus=False)


def main(operation, *ids):
    if operation not in {"hide", "restore"} or not ids:
        raise ValueError("Expected hide or restore followed by window IDs")
    socket_path = Path(os.environ["NIRI_SOCKET"])
    state_dir = socket_path.parent / "pmmac"
    state_dir.mkdir(mode=0o700, exist_ok=True)
    state_path = state_dir / "hidden-windows.json"

    with (state_dir / "hidden-windows.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = json.loads(state_path.read_text()) if state_path.exists() else {}
        socket_id = str(socket_path) + ":" + str(socket_path.stat().st_ino)
        origins = state.get("windows", {}) if state.get("socket") == socket_id else {}

        windows = request(socket_path, "Windows")["Windows"]
        workspaces = request(socket_path, "Workspaces")["Workspaces"]
        by_window = {window["id"]: window for window in windows}
        by_workspace = {workspace["id"]: workspace for workspace in workspaces}
        selected = [by_window[int(id)] for id in ids if int(id) in by_window]
        stash = next((workspace for workspace in workspaces if workspace["name"] == STASH), None)
        focused = next((workspace for workspace in workspaces if workspace["is_focused"]), None)
        origins = {str(window["id"]): origins[str(window["id"])] for window in windows
                   if str(window["id"]) in origins
                   and stash and window["workspace_id"] == stash["id"]}

        if not selected or not focused:
            return

        if operation == "hide":
            if not stash:
                occupied = {window["workspace_id"] for window in windows}
                stash = next((workspace for workspace in reversed(workspaces)
                              if workspace["output"] == focused["output"]
                              and workspace["name"] is None and not workspace["is_active"]
                              and workspace["id"] not in occupied), None)
                if not stash:
                    raise RuntimeError("There is no spare workspace to hide the app")
                action(socket_path, "SetWorkspaceName", name=STASH, workspace={"Id": stash["id"]})

            moving = [window for window in selected if window["workspace_id"] not in (None, stash["id"])]
            origins.update({str(window["id"]): {
                "workspace": window["workspace_id"], "focused": window["is_focused"],
            } for window in moving})
            save(state_path, {"socket": socket_id, "windows": origins})
            for window in moving:
                move(socket_path, window["id"], stash["id"])
            return

        previous = next((window for window in selected
                         if isinstance(origins.get(str(window["id"])), dict)
                         and origins[str(window["id"])]["focused"]), selected[0])
        if stash:
            fallback = focused if focused["id"] != stash["id"] else next(
                (workspace for workspace in workspaces
                 if workspace["output"] == stash["output"] and workspace["id"] != stash["id"]),
                None,
            )
            if fallback:
                for window in selected:
                    if window["workspace_id"] == stash["id"]:
                        record = origins.get(str(window["id"]))
                        origin_id = record["workspace"] if isinstance(record, dict) else record
                        origin = by_workspace.get(origin_id, fallback)
                        move(socket_path, window["id"], origin["id"])
                        origins.pop(str(window["id"]), None)

        action(socket_path, "FocusWindow", id=previous["id"])
        save(state_path, {"socket": socket_id, "windows": origins})


if __name__ == "__main__":
    try:
        main(*sys.argv[1:])
    except (OSError, ValueError, KeyError, RuntimeError) as error:
        sys.exit(str(error))
