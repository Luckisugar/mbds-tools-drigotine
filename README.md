# BDS Tools - Minecraft Bedrock Dedicated Server Mod Installers

Easy-to-use PowerShell tools for installing and managing addons/mods on a **Minecraft Bedrock Dedicated Server (BDS)**.

Built from scratch to make life easier when dealing with `.mcaddon` and `.mcpack` files.

## Features

- **BDS-Installers-Launcher** - Simple menu to run everything
- **BDS-Mcaddon-Installer** - Handles bundled `.mcaddon` files (BP + RP)
- **BDS-Mcpack-Installer** - Flexible support for single or separate `.mcpack` files (BP/RP)
- **BDS-Uninstaller** - Cleanly remove mods from a world (with option to delete files)

## Quick Start

1. Place your `.mcaddon` and/or `.mcpack` files in the same folder as the scripts (or the location expected by the scripts).
2. Double-click `BDS-ADDON INSTALLER.bat`
3. Follow the on-screen menu.

The scripts handle:
- Unpacking
- Copying to `behavior_packs` / `resource_packs`
- Registering UUIDs in your world's `world_behavior_packs.json` and `world_resource_packs.json`

## Requirements

- Windows
- PowerShell (Windows PowerShell 5.1 or PowerShell 7+ recommended)
- A Bedrock Dedicated Server

## Demo Video

[Add your video link here after uploading]

## Folder Structure

```
BDS drigotine/
├── BDS-ADDON INSTALLER.bat
├── .gitignore
├── README.md
└── TOOLS/
    ├── BDS-Installers-Launcher.ps1
    ├── BDS-Mcaddon-Installer.ps1
    ├── BDS-Mcpack-Installer.ps1
    └── BDS-Uninstaller.ps1
```

## How to Use (Advanced)

You can also run the scripts directly:
```powershell
pwsh .\TOOLS\BDS-Installers-Launcher.ps1
```

## Contributing

These tools were developed iteratively. Improvements welcome!

## License

Feel free to use and modify. 

Created while building a custom Bedrock server setup.
