# ColonyManager-Pro-ME

**Automated MineColonies Request Fulfillment for Applied Energistics 2**

ColonyManager-Pro-ME is a ComputerCraft/CC:Tweaked program that automatically fulfills MineColonies citizen requests and building work orders from your Applied Energistics 2 system.

## Features

- **Automatic Request Fulfillment** - Monitors colony requests and exports items from your ME system
- **Smart Tool Handling** - Provides the cheapest acceptable tool based on building level
- **Work Order Support** - Fulfills building construction resource requests
- **Auto-Crafting** - Schedules crafting jobs for items not in storage
- **GitHub Auto-Updates** - Checks for and installs updates on boot
- **Interactive Monitor GUI** - Touch-screen interface for status and configuration
- **Excluded Items Management** - Configure items to skip via GUI
- **Night Pause** - Optional pause during night (configurable)

## Requirements

- **Minecraft Mods:**
  - [MineColonies](https://www.curseforge.com/minecraft/mc-mods/minecolonies)
  - [Applied Energistics 2](https://www.curseforge.com/minecraft/mc-mods/applied-energistics-2)
  - [CC:Tweaked](https://www.curseforge.com/minecraft/mc-mods/cc-tweaked) (ComputerCraft)
  - [Advanced Peripherals](https://www.curseforge.com/minecraft/mc-mods/advanced-peripherals) 0.7+

- **Peripherals Required:**
  - Advanced Computer
  - Monitor (any size, 0.5 text scale recommended)
  - ME Bridge (from Advanced Peripherals)
  - Colony Integrator (from Advanced Peripherals)

## Installation

### Quick Install

1. Place a computer with a **Modem** and **Monitor** (any size)
2. Connect the computer to:
   - An **ME Bridge** (for item access), connected to your ME network by ME cable (it uses one channel)
   - A **Colony Integrator** (for MineColonies data)
   - The **Monitor** (for GUI)
3. Run the installer:
   ```lua
   wget run https://raw.githubusercontent.com/justinmpowers/ColonyManager-Pro-ME/main/installer.lua
   ```
4. The GitHub repository is already configured for ColonyManager-Pro-ME

The installer will:
- Download all necessary files from GitHub
- Create a startup script to run on boot
- Configure auto-updates from GitHub
- Reboot the computer to start ColonyManager-Pro-ME

### Manual Install

1. Download all files from this repository
2. Place them in your computer's root directory:
   - `MEWarehouse.lua` - Main program
   - `startup.lua` - Boot script
   - `updater.lua` - Auto-update module
   - `config.lua` - Configuration
3. Edit `config.lua` with your settings
4. Reboot the computer

## Configuration

Edit `config.lua` to customize:

```lua
return {
    -- GitHub repository for updates
    github_repo = "justinmpowers/ColonyManager-Pro-ME",
    github_branch = "main",
    
    -- Scan interval (seconds)
    time_between_runs = 15,
    
    -- Scan during night time
    scan_at_night = true,
    
    -- Smart tool handling (provides cheapest acceptable tool)
    smart_tool_handling = true,
    
    -- Excluded items (won't be auto-fulfilled)
    excluded_items = {
        -- "Item Name",
    },
}
```

## Smart Tool Handling

When enabled, ColonyManager-Pro-ME intelligently fulfills tool and armor requests:

### How It Works

1. **Detects Building Level** - Uses Colony Integrator to find the citizen's workplace level
2. **Determines Allowed Tiers** - Based on MineColonies rules:
   - Level 0: Wood/Gold only
   - Level 1: Up to Stone
   - Level 2: Up to Iron
   - Level 3+: Up to Diamond
3. **Provides Cheapest Option** - Tries materials from cheapest to most expensive

### Material Cost Priority

| Priority | Material | Cost Value |
|----------|----------|------------|
| 1 | Wood/Gold | 1 |
| 2 | Stone | 2 |
| 3 | Iron | 3 |
| 4 | Diamond | 5 |
| 5 | Netherite | 10 |

## Monitor Interface

The touch-screen monitor displays:

- **Main Page** - Current requests and their status
- **Logs** - Recent activity log viewer
- **Stats** - Export/craft statistics
- **Config** - Settings toggles
- **Excluded** - Manage excluded items list
- **Legend** - Status icon explanations

### Status Icons

| Icon | Color | Meaning |
|------|-------|---------|
| [OK] | Green | Fully supplied from storage |
| [>>] | Yellow | Crafting job scheduled |
| [..] | Orange | Partial fill, awaiting craft |
| [XX] | Red | Failed - not available |
| [!>] | Orange | Partial fill, craft failed |
| [CP] | Magenta | Pattern exists, but no free ME Crafting CPU (retried next scan) |
| [??] | Blue | Manual fulfillment needed |

## Auto-Updates

ColonyManager-Pro-ME checks for updates from GitHub on each boot:

1. Compares local version to latest GitHub commit
2. Downloads updated files if newer version exists
3. Preserves your `config.lua` settings
4. Reboots to apply changes

### Disable Auto-Updates

Remove or rename `updater.lua` to disable automatic updates.

## Peripheral Setup

```
┌─────────────────────────────────────┐
│           Advanced Computer          │
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐           │
│  │ Monitor │  │ME Bridge│           │
│  └─────────┘  └─────────┘           │
│                                      │
│  ┌──────────────────┐               │
│  │ Colony Integrator │               │
│  └──────────────────┘               │
│                                      │
│  ME Bridge joins the ME network via  │
│  ME cable (uses one channel)         │
└─────────────────────────────────────┘
```

**Important:** The Colony Integrator must be placed within your colony boundaries.

## Troubleshooting

### "Colony Integrator is not in a colony"
- Move the integrator within your colony's claimed chunks
- Check that your Town Hall is placed and colony is established

### "ME Bridge not found"
- Ensure ME Bridge is connected to the computer
- Verify ME Bridge is connected to your ME network and the network is powered
- Make sure the ME Bridge has a free channel (check your controller or cable channel usage)
- Advanced Peripherals 0.7.x names the peripheral `meBridge`, and 0.8+ names it `me_bridge`. Both are detected.

### Requests stuck on [CP] / "no Crafting CPU is free"
- AE2 needs an idle **Crafting CPU** for every crafting job
- Build more Crafting CPUs (or larger ones) if many requests queue at once
- Waiting requests are retried automatically on the next scan

### Items not exporting
- Check the ME Bridge has access to the warehouse inventory
- Verify the export direction in `config.lua`
- Check if item is in the excluded list

### Updates not working
- Verify `github_repo` is set correctly in `config.lua`
- Ensure HTTP API is enabled in ComputerCraft config
- Check internet connectivity

## File Structure

```
/
├── MEWarehouse.lua      # Main program
├── startup.lua          # Boot script
├── updater.lua          # Auto-update module
├── config.lua           # User configuration
├── installer.lua        # Installer (wget run)
├── excluded_items.txt   # Runtime excluded items
├── .rswarehouse_version # Current version hash
└── MEWarehouse.log      # Activity log
```

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - See LICENSE file for details.

## Credits

- Original concept inspired by various MineColonies automation scripts
- Built for Advanced Peripherals 0.7+
- Compatible with CC:Tweaked 1.19+
