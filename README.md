# Neon Foundry — tools

Everything that runs for the [Neon Foundry](https://github.com/egulay/neon-foundry)
Omarchy theme: four animated unlock screens, the generators behind the
wallpapers and the boot screen, and the scripts that put GTK apps and browsers
on the theme's colours.

It lives apart from the theme because Omarchy's gallery lists only
repositories that carry no code — a theme is a palette and the files that
dress Omarchy in it. None of this is run by Omarchy. It is here so the extras
are reproducible rather than hand-assembled, and `install.sh` puts the two
repositories together.

![Unlock](https://raw.githubusercontent.com/egulay/neon-foundry/main/preview-lock.png)

## Install

```bash
git clone https://github.com/egulay/neon-foundry-tools
cd neon-foundry-tools
./install.sh
```

In order, it:

1. **Installs the theme if it is missing.** A checkout beside this one, or
   one given with `--theme-dir DIR`, is linked into
   `~/.config/omarchy/themes/neon-foundry`, which Omarchy treats as your own
   theme. Otherwise it runs `omarchy theme install`.
2. **Enables the focused-window glow** — on a linked theme only. The theme
   ships it as `hyprland.lua.example` because Omarchy drops every `*.lua`
   from a theme it cloned from git; a linked theme is yours and does load it.
   The gradient border itself comes from `colors.toml` and works either way.
3. **Installs the unlock screens** by cloning Omarchy's `omarchy.lock`
   plugin to `<user>.lock` and replacing one file in it, then restarting the
   shell so the new view is picked up.

`--no-apply` installs without switching to the theme. `./uninstall.sh`
restores the stock unlock screen and removes the theme link;
`--keep-theme` and `--remove-lock-clone` adjust that.

## Unlock screens

Four scenes, one drawn at random each time the screen locks. No logo, no
clock, no user card: the password field, with the same gradient glow a
focused window has, and the characters moving behind it.

| | Scene |
|---|---|
| 0 | **Crew** — the crew hauling blocks along a lane near the foot of the screen |
| 1 | **Abduction** — the saucer crossing with its beam down, beetles bolting below |
| 2 | **Menagerie** — the cat crossing and settling, the lamb grazing, the devil ambling |
| 3 | **Patrol** — the snake crawling out of a wormhole and away along the bottom |

To pin one, set `variant` on the `FoundryScene` in
`~/.config/omarchy/plugins/<user>.lock/LockView.qml`:

```qml
FoundryScene {
    anchors.fill: parent
    variant: 2          // always the menagerie
    active: root.loadBackground
}
```

### How it works, and what is deliberately untouched

Omarchy's lock screen is not hyprlock. It is the Quickshell plugin
`omarchy.lock`, and `install.sh` clones it and replaces one file,
`lock/LockView.qml`, between two marked comment blocks.

`Service.qml` — the PAM flows, the password and fingerprint handling — is
left byte-identical to Omarchy's. Authentication is not somewhere to be clever
for the sake of a wallpaper. The scene loader also swallows its own errors: if
a scene ever fails to load, the lock screen still comes up with its field.

The field's glow is drawn in `LockView.qml` as a rim: Hyprland's shadow
cannot reach a Quickshell surface, and a blurred *filled* rectangle would show
through the field's 80% background as a pale box, so the field's own
footprint is masked back out of the blur.

The scene is built only while the lock is up. It does **not** stop when the
display blanks: Omarchy turns the backlight off five seconds after locking,
but the compositor carries on, and so do these animations. A few dozen
animated rectangles, not a repainting canvas, so the cost is small; it is
not zero.

If you edit a scene by hand, run `omarchy restart shell` afterwards. Saving a
file under `~/.config/omarchy/plugins/` reloads the plugin's service code,
but the `LockView` the shell already built stays cached: the lock screen goes
on rendering the previous view and reports no error at all.

If Omarchy's own `LockView.qml` gains features, re-clone it and re-apply
that one block rather than keeping this copy frozen.

## Wallpapers

The theme's six wallpapers are generated, not hand-drawn:

```bash
python3 -I tools/gen_backgrounds.py                 # all six, native size
python3 -I tools/gen_backgrounds.py --size 3840x2160 --seed 7
python3 -I tools/gen_backgrounds.py --only 04-lattice
```

They go straight into the installed theme's `backgrounds/` when the theme is
on this machine, else into `dist/backgrounds/`; `--out` overrides. `--seed`
changes the snowflake and the scatter; every flake is a fresh draw — one arm,
mirrored through the eight symmetries of the square.

No third-party dependencies: `tools/canvas.py` is a small RGB buffer and a
PNG writer, since Pillow is not on a stock Omarchy box and every shape here is
an axis-aligned fill. ImageMagick, which Omarchy ships, lays the captions on
afterwards. `tools/sprites.py` holds every sprite matrix; `lock/FoundrySprites.js`
is the same data for the unlock screens.

After regenerating, re-apply the theme — `omarchy theme set neon-foundry`.
Omarchy copies the theme into `~/.local/state/omarchy/current/theme/` and the
desktop reads from that copy, so a regenerated image sits unseen until then.
Note that `omarchy theme set` also steps to the next wallpaper every time it
runs.

## Boot and login screen

```bash
python3 -I tools/gen_logo.py
```

writes two files into the theme: `unlock.png`, the lattice, which Omarchy
centres above the password entry on the Plymouth splash and the SDDM greeter
(copied as `logo.png`, never recoloured), and `preview-unlock.png`, the
1920×1080 mock whose presence lists the theme in `omarchy plymouth switcher`.
Background and entry colours are not stored in either: Omarchy reads them from
`colors.toml` when it applies them.

## Matching GTK apps to the bar

Omarchy themes the bar and the terminals from `colors.toml`, but not GTK:
`omarchy-theme-set-gnome` sets only `color-scheme` and the icon theme, and
`omarchy font set` is the *monospace* font. So Nautilus stays on Adwaita grey
in Adwaita Sans while the bar is on the theme's background in JetBrains Mono.

```bash
./tools/gtk-match-bar.sh            # the bar's font, one size down, smaller icons
./tools/gtk-match-bar.sh --revert

./tools/gtk-theme-colors.sh --install   # the theme's colours, following every theme change
./tools/gtk-theme-colors.sh --revert
```

The first goes through `gsettings` only. The second writes libadwaita's named
colours into `~/.config/gtk-4.0/gtk.css` between markers of its own, and with
`--install` registers itself as a `theme-set` hook, so switching to Tokyo
Night turns Nautilus Tokyo Night. Omarchy's Glassy windows option writes to
the same file but only between `/* omarchy-glass begin */` and its end
marker, and removes just that range, so the two coexist.

## Browsers

```bash
./tools/browser-theme.sh            # does what each installed browser needs
./tools/browser-theme.sh --revert
```

**Chromium, Chrome, Brave — nothing to do.** Omarchy themes them itself from
the theme's `chromium.theme`, through browser policy, on every theme change.

**Firefox, LibreWolf, Floorp, Waterfox** get a static theme,
`tools/firefox-theme.sh` → `dist/<theme>-firefox.xpi`, built from the active
theme's `colors.toml`. `theme.colors` is a documented WebExtension API that
names surfaces rather than overriding internal CSS, so an update cannot
quietly break it. Gecko installs an unsigned theme permanently only when
signed: once, free, at
[addons.mozilla.org/developers](https://addons.mozilla.org/developers/) under
"On your own" distribution. To look first: `about:debugging` → Load Temporary
Add-on.

**Zen** turns static themes off (`zen.theme.disable-lightweight = true`) and
paints its own chrome, so its colours are set in Zen. The script writes two
prefs into the profile's `user.js` — `zen.theme.gradient.show-custom-colors`,
which unlocks a hex field in the picker, and `zen.theme.accent-color` — and
prints the background to enter. Open the picker from the URL bar: type
`theme`, choose **Open Theme Picker**. It will not open on an unsynced window
(`zen.window-sync.prefer-unsynced-windows = true`): the Browser Console then
shows `panelNode is undefined`, because `ZenGradientGenerator` returns before
defining its panel. Set the colour on a synced window; it persists on the
workspace.

## Layout

```
install.sh           theme if missing, glow, unlock screens
uninstall.sh         reverse it
lock/
  LockView.qml       Omarchy's view + one Neon Foundry block
  FoundryScene.qml   picks a scene at random
  FoundryPixel.qml   one pixel-art character
  FoundryGrid.qml    the grid they move on
  FoundrySprites.js  every sprite matrix, and the curve helpers
  Scene*.qml         the four scenes
tools/
  gen_backgrounds.py wallpapers
  gen_logo.py        boot/login assets
  sprites.py         sprite data        canvas.py  RGB buffer + PNG writer
  gtk-match-bar.sh   gtk-theme-colors.sh
  browser-theme.sh   firefox-theme.sh
```

## Licence

MIT — see [LICENSE](LICENSE).

`lock/LockView.qml` is a derivative of the `LockView.qml` that ships with
[Omarchy](https://github.com/basecamp/omarchy) (MIT, Copyright (c) David
Heinemeier Hansson). Most of that one file is Omarchy's; the Neon Foundry
change is the block marked inside it. Its licence is reproduced in `LICENSE`
under THIRD-PARTY NOTICES. Everything else here is this repository's own.
