# Screen Ruler

A small macOS menu bar app. It makes the screen dark, but keeps a bright
horizontal slit at the height of the pointer. The slit moves with the pointer,
like a reading ruler on a page.


## Use

- **Click** the menu bar icon: open the menu with the status, the settings and
  the shortcuts.
- **⌃⌥⌘R**: switch the ruler on or off from any app.
- **⌃⌥⌘↑ / ⌃⌥⌘↓**: make the slit higher or lower from any app. Hold the key
  down to continue. The slit moves to the new height with a short animation.

Settings:

| Setting | What it does |
| --- | --- |
| Slit height | The height of the bright slit, 12 to 300 px. |
| Dim amount | How dark the rest of the screen becomes, 10 to 95 %. |
| Edge softness | The width of the soft edge above and below the slit. |
| Open at Login | Starts the app when you log in. |

The arrow shortcuts work only while the ruler is on. While it is off, the app
gives ⌃⌥⌘↑ and ⌃⌥⌘↓ back to the system.

The settings stay after a restart of the app.

## Build

```sh
./build.sh            # makes build/ScreenRuler.app
./build.sh install    # also copies it to /Applications and starts it
open build/ScreenRuler.app
```

You need Xcode command line tools. The build makes a universal binary
(Apple silicon and Intel) and signs it ad-hoc, so it runs on your own machine
without a developer account.

## How it works

- One transparent, click-through window covers each screen. The window level is
  above the menu bar, the Dock and full screen apps.
- Each window holds two dark gradient layers: one above the slit, one below it.
  A timer reads the pointer position 60 times a second and moves the two layers.
  Only the size of a layer changes, so the GPU does very little work.
- The same timer eases the drawn slit height to the height of the setting.
  Each frame covers a quarter of the distance that is left, thus a change of
  the height is a short, smooth movement.
- The windows let all clicks through (`ignoresMouseEvents`), thus the app below
  the ruler stays fully usable.
- The app polls the pointer position instead of an event tap, and the shortcuts
  use the Carbon hot key API. Therefore it needs **no accessibility permission**.
- If a second screen has no pointer on it, that screen stays fully dark.

## Files

| File | Content |
| --- | --- |
| `Sources/ScreenRuler/AppDelegate.swift` | Menu bar item, menu, shortcut. |
| `Sources/ScreenRuler/OverlayController.swift` | Windows for each screen, pointer tracking. |
| `Sources/ScreenRuler/OverlayWindow.swift` | The click-through window. |
| `Sources/ScreenRuler/RulerView.swift` | The two dark layers and the slit. |
| `Sources/ScreenRuler/SliderMenuItemView.swift` | A slider row in the menu. |
| `Sources/ScreenRuler/GlobalHotKey.swift` | The shortcuts (Carbon API). |
| `Sources/ScreenRuler/Settings.swift` | Values kept in UserDefaults. |

## License

MIT
