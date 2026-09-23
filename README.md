# omaLinea — La Linea Walker for Omarchy

An Omarchy shell plugin that brings Osvaldo Cavandoli's **La Linea** to your
desktop: he walks the bottom of your screen, argues with his creator's hand,
and rants in Carlo Bonomi's unmistakable gibberish.

> **Unofficial fan tribute.** Not affiliated with the rights holders.
> Footage and audio are cut from the user's own copy for personal,
> non-commercial desktop use. Grazie, Maestro.

![La Linea on stage (earlier short-scene build)](preview.png)

🎬 [Watch the 33s demo of v3.6.0](https://github.com/ariDev1/omaLinea/releases/download/v3.6.0/omaLinea-preview.mp4) — edge-fill over the scope, with rant audio. Also on the [v3.6.0 release page](https://github.com/ariDev1/omaLinea/releases/tag/v3.6.0). This preview predates the complete-episode build.

## Features

- **28 complete episodes** — every numbered episode (101–128) in the 72-minute
  source compilation, from title to ending, with its original continuous audio
- **Bounded memory** — transparent WebP animation changes in 30-second chunks;
  only the active chunk is decoded, even during a full episode
- **Click-through overlay** — he never steals clicks from your windows
- **Native stage + edge fill** — crisp bottom-stage look by default,
  stretch-to-edges zoom on demand
- **Animated bar icon** — a standing La Linea living in your bar; every
  5–18s he randomly bows, hops, or stands straight
- **Episode picker + tribute card** — click the bar icon to choose any episode
  from a native Omarchy dropdown, with Cavandoli credits and links
- **Episode cycling** — flip through all 28 episodes without touching the mouse

## Episodes

Select any of the **28 numbered episodes, 101 through 128**. Each runs about
2½ minutes; the last frame loops back to the episode's opening. Each has one
uninterrupted Ogg audio track and five or six transparent WebP parts in
`episodes/`. The episode boundaries and media recipe are in
`tools/generate_episodes.py`.

Click the La Linea bar icon, then click an episode number to play it immediately.
The popup scrolls on smaller screens.

## Keybindings

| Keys | Action |
|------|--------|
| `SUPER + L` | Summon / dismiss La Linea |
| `SUPER + SHIFT + L` | Next episode |
| `SUPER + SHIFT + J` | Previous episode |
| `SUPER + SHIFT + Z` | Toggle native size ↔ edge-to-edge zoom |

Direct summon also works, e.g.:

```bash
omarchy-shell shell summon rene.lalinea '{"episode":120}' # episode 120
omarchy-shell shell summon rene.lalinea '{"scene":19}'    # same episode, zero-based
omarchy-shell shell summon rene.lalinea '{"action":"fill"}'    # force zoom
omarchy-shell shell summon rene.lalinea '{"action":"stage"}'   # force native
```

## Install

Requirements: [Omarchy](https://omarchy.org/) (Quickshell shell), `mpv` for
the original audio, and Qt's WebP image plugin (`qt6-imageformats` on Arch).

1. Standard install (recommended):
   ```bash
   omarchy plugin add https://github.com/ariDev1/omaLinea.git --enable
   omarchy plugin validate ~/.config/omarchy/plugins/rene.lalinea
   ```
   Manual alternative:
   ```bash
   git clone https://github.com/ariDev1/omaLinea.git
   cp -r omaLinea ~/.config/omarchy/plugins/rene.lalinea
   omarchy plugin validate ~/.config/omarchy/plugins/rene.lalinea
   ```
2. Register it in `~/.config/omarchy/shell.json`:
   ```json
   "plugins": [{ "id": "rene.lalinea" }]
   ```
   and add `{ "id": "rene.lalinea" }` to `bar.layout.right` for the bar icon.
3. Add the keybindings to `~/.config/hypr/bindings.lua`.
   `omarchy plugin add --enable` does **not** install Hyprland keybindings —
   this step is required, otherwise `SUPER+L` keeps doing its default
   workspace-layout toggle and the other keys do nothing.
   (`SUPER+L` needs `hl.unbind("SUPER + L")` first — it replaces the
   workspace-layout toggle.) Copy-paste block:
   ```lua
   -- omaLinea — La Linea Walker (https://github.com/ariDev1/omaLinea)
   -- SUPER+L was previously bound to Toggle workspace layout, unbound below.
   hl.unbind("SUPER + L")
   o.bind("SUPER + L", "La Linea toggle", "omarchy-shell shell toggle rene.lalinea")
   o.bind("SUPER + SHIFT + L", "La Linea next episode", "omarchy-shell shell summon rene.lalinea '{\"action\":\"next\"}'")
   o.bind("SUPER + SHIFT + J", "La Linea prev episode", "omarchy-shell shell summon rene.lalinea '{\"action\":\"prev\"}'")
   o.bind("SUPER + SHIFT + Z", "La Linea zoom toggle", "omarchy-shell shell summon rene.lalinea '{\"action\":\"toggleFill\"}'")
   ```
   Verify with: `omarchy menu keybindings --print | grep "La Linea"`
4. Apply:
   ```bash
   hyprctl reload && hyprctl configerrors
   omarchy restart shell
   ```

## Update

```bash
omarchy plugin update rene.lalinea
omarchy restart shell
```

## Removal

```bash
omarchy plugin remove rene.lalinea
```

Removal deletes the plugin directory. Your `shell.json` entry, bar layout
entry, and Hyprland keybindings are yours — remove those lines too if you
don't want them. Nothing else is left behind: no services, no timers, no
files outside the plugin directory (the audio `mpv` process exits with the
overlay and is reaped on shell start).

## Rebuilding episodes

With your own local copy of the same compilation and `ffmpeg` installed:

```bash
python3 tools/generate_episodes.py /absolute/path/to/lalinea.webm
```

The source video is **not** included in this repository. The generated media
is already included. The script cuts every complete episode and can also
rebuild one with `--only 120 --force`. `AnimatedImage` decodes all frames of
the active part into RAM, so each part stays at **30s × 8fps = 240 frames**
at 400×320. The single Ogg per episode remains continuous as parts change.

## Credits

- **Osvaldo Cavandoli (1920–2007)** — creator of La Linea (first aired 1969)
- **Carlo Bonomi** — voice of the rant
- Built for the [Omarchy](https://omarchy.org/) community with love

## Support & security

- Bugs and ideas: [GitHub issues](https://github.com/ariDev1/omaLinea/issues)
- Security: this plugin runs unsandboxed inside the Omarchy shell (like all
  shell plugins). It launches one local process — `mpv` for episode audio, no
  network access, no credentials. Report concerns via GitHub issues; do not
  post credentials anywhere.

## Compatibility

The original short-scene build was tested on Omarchy 4.0.4, single monitor.
The complete-episode build needs a live-shell summon/hide and part-boundary
check on your target version; `omarchy plugin validate` checks its manifest.
