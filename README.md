# BDS Tools - Minecraft Bedrock Dedicated Server Mod Installers

Easy-to-use PowerShell tools for installing and managing addons/mods on a **Minecraft Bedrock Dedicated Server (BDS)**.

Built from scratch to make life easier when dealing with `.mcaddon` and `.mcpack` files.

## Features

- **BDS-Installers-Launcher** - Simple menu to run everything
- **BDS-Mcaddon-Installer** - Handles bundled `.mcaddon` files (BP + RP)
- **BDS-Mcpack-Installer** - Flexible support for single or separate `.mcpack` files (BP/RP)
- **BDS-Uninstaller** - Cleanly remove mods from a world (with option to delete files)

## Quick Start

1. Put your `.mcaddon` / `.mcpack` files into the `BDS-TOOLS` folder (or wherever you configured).
2. Double-click `BDS-ADDON INSTALLER.bat`
3. Choose what you want to do from the menu.

The scripts automatically handle unpacking, copying to the correct `behavior_packs` / `resource_packs` folders, and registering them in your world's JSON files.

## Requirements

- Windows
- PowerShell 5.1+ (or better, PowerShell 7+ / `pwsh`)
- A running or set-up Bedrock Dedicated Server

## Demo Video

[Link your video here when uploaded]

## Folder Structure

```
BDS drigotine/
├── BDS-ADDON INSTALLER.bat
└── BDS-TOOLS/
    ├── BDS-Installers-Launcher.ps1
    ├── BDS-Mcaddon-Installer.ps1
    ├── BDS-Mcpack-Installer.ps1
    └── BDS-Uninstaller.ps1
```

## Contributing / Feedback

These were built iteratively. If you improve them, feel free to PR or open issues.

## License

MIT - do whatever, just don't blame me if your server explodes.

Made with too much coffee and stubbornness.
