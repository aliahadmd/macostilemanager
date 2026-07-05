# TileManager

TileManager is a small personal macOS menu bar utility that tiles windows vertically. Double-click a safe title-bar or toolbar area and the clicked window moves to the top or bottom half of its current display.

## Build

```sh
./scripts/build-app.sh
```

The app bundle is created at:

```text
.build/TileManager.app
```

## Run

```sh
open .build/TileManager.app
```

On first launch, grant Accessibility permission in System Settings. TileManager cannot move other apps' windows until macOS grants that permission.

For day-to-day use, install to a stable per-user app path:

```sh
./scripts/install-user-app.sh
```

Then enable `TileManager` in System Settings > Privacy & Security > Accessibility. If an older rebuilt copy is already listed, remove it and add `~/Applications/TileManager.app`.

The build script signs the app with your first available local code-signing identity, falling back to ad-hoc signing only when no identity exists. A stable signing identity helps macOS keep Accessibility permission across rebuilds.

## Verify

```sh
swift build
swift run TileManagerGeometryTests
```

## Behavior

- Menu bar utility only; no dock icon.
- Double-click title bars/top bars to tile.
- Windows mostly above the display midpoint move to the top half.
- Windows mostly below the display midpoint move to the bottom half.
- Display rotation, menu bar, dock, and multi-display layout are handled from macOS screen geometry.
- Normal Mode keeps the classic top/bottom half layout.
- Screen Recorder Mode makes the bottom region a fitted 16:9 recording area on portrait displays, with the remaining vertical space on top.
