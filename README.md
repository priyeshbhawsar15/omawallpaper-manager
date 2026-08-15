# Wallpaper Controller for Omarchy

An Omarchy Quickshell plugin for rotating Wallpaper Engine projects and static
images. It can apply a wallpaper per monitor, rotate selected entries, and sync
the active wallpaper to the system theme with Aether.

## Install

Install the runtime requirements first:

```bash
omarchy pkg aur add linux-wallpaperengine-git
omarchy pkg aur add aether
omarchy pkg add imagemagick zenity
```

Then install and enable the plugin:

```bash
omarchy plugin add https://github.com/priyeshbhawsar15/omarchy-wallpaper-controller.git --enable
```

Open **Wallpaper Controller** from the Omarchy menu under Style. On a Quattro
setup, `Super+Alt+W` can be bound to:

```bash
omarchy-shell shell summon priyesh.wallpaper-controller
```

## Update and remove

```bash
omarchy plugin update priyesh.wallpaper-controller
omarchy plugin remove priyesh.wallpaper-controller
```

The plugin keeps its selection and rotation state in
`~/.config/omarchy/wallpaper-controller.json`; removing the plugin does not
delete that state or your wallpaper files. To stop the renderer and remove the
installed helper before removal, run:

```bash
~/.config/omarchy/plugins/priyesh.wallpaper-controller/uninstall.sh
```

## Notes

- The plugin boots a small helper into `~/.local/bin` when Quickshell loads it.
- Static images are rendered independently for every connected monitor.
- Wallpaper Engine projects must be installed locally and readable by
  `linux-wallpaperengine`.
