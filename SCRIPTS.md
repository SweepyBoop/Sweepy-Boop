# Development Scripts

The repository keeps platform-specific World of Warcraft installation roots in one file:

```text
WoWInstallPaths.txt
```

It has separate values because Windows uses drive-letter paths while macOS uses Unix paths rooted at `/`:

```text
WINDOWS_WOW_PATH=C:\Program Files (x86)\World of Warcraft
MAC_WOW_PATH=/Applications/World of Warcraft
```

The macOS value is the usual installation location and can remain as a placeholder until WoW is installed. If Battle.net installs the game elsewhere, update only `MAC_WOW_PATH`. PowerShell scripts automatically use `WINDOWS_WOW_PATH` on Windows and `MAC_WOW_PATH` when run through PowerShell on macOS.

## macOS setup

From the repository root, make the scripts executable once:

```bash
chmod +x ./*.sh ./wow-icon-upscale-workbench/*.sh
```

The scripts resolve paths relative to themselves, so they can be run from any working directory.

## Deploy to WoW

Deploy the development copy to every installed WoW client under `MAC_WOW_PATH`:

```bash
./update.sh
```

Missing client flavors are skipped. Each deployed copy includes `Internal/` and receives `addon.internal = true;` in `Common/Constants.lua`.

## Toggle test mode

Enable test mode in every installed SweepyBoop copy:

```bash
./test.sh
```

Disable it:

```bash
./test.sh --off
```

## Create the publish ZIP

Create a clean staging folder and a publish-ready archive:

```bash
./publish.sh
```

The script creates:

```text
SweepyBoop.zip
└── SweepyBoop/
    ├── SweepyBoop.toc
    ├── SweepyBoop_Mists.toc
    ├── SweepyBoop_TBC.toc
    └── ...
```

`Internal/`, `Docs/`, development scripts, Git metadata, the icon workbench, `.DS_Store`, and `__MACOSX/` are not included. The single top-level `SweepyBoop/` folder is the layout expected when publishing or extracting into `Interface/AddOns`.

Inspect the archive contents at any time with:

```bash
unzip -Z1 SweepyBoop.zip
```

You can upload `SweepyBoop.zip` directly to the add-on hosting site. The archive still contains the current `@project-version@` TOC placeholder; replace or automate that value separately if the publishing site does not substitute it.

## Other utilities

Regenerate crowd-control aura data from an installed BigDebuffs copy:

```bash
./fixBigDebuffs.sh
```

Delete all local Git branches except `main` after a confirmation prompt:

```bash
./cleanupBranches.sh
```

Skip the prompt with `./cleanupBranches.sh --force`. This operation force-deletes local branches and refuses to run with uncommitted changes.
