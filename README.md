# CheckPoint_CustomizePackage

<div>
  <img src="icon.png" alt="icon" width="128" align="left" style="margin-right: 16px;" />

  A PowerShell CLI tool that automates the customization of Check Point Endpoint Security packages, streamlining a previously complex workflow.

  ![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)
  ![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6)
</div>
<br clear="left" />

## Background

The organization previously used `AdminMode.bat` to create pre-configured packages with encrypted VPN site configurations. After migrating to SmartEndpoint for managed VPN clients, `vpnconfig` was adopted for additional configuration flexibility, particularly for editing `trac.defaults` files.

## Problem Addressed

The original process involved multiple manual steps: generating packages, installing them, connecting to establish configurations, modifying settings, using `vpnconfig` to create installers, uninstalling, and reinstalling to verify functionality. This script automates all these steps to eliminate this tedious workflow.

The tool handles both standard (MSI) and dynamic (EXE) packages. It specifically minimizes dynamic packages to remove unnecessary components, useful for organizations that only require VPN and firewall functionality. Given that antimalware updates increased base MSI sizes to approximately 900 MB, this optimization addresses practical deployment concerns.

## Features

- **MSI and EXE support**: Customize both MSI packages (from SmartDashboard) and EXE packages (from SmartEndpoint/Harmony Endpoint)
- **Download from management**: Download packages directly from a Harmony Endpoint management server (R81+)
- **VPN site configuration**: Generate and embed `trac.config` with site, authentication method, and SDL settings
- **Client configuration**: Customize `trac.defaults` (always connect, hotspot, certificate filtering, machine auth, etc.) and choose to embed it inside the MSI or apply it post-install
- **MSI property customization**: Modify MSI properties (SDL_ENABLED, FIXED_MAC, NoKeep, etc.)
- **Install steps**: Configure pre-install and post-install actions (stop Endpoint Security, reconnect, copy scripts, set log level, add certificate fingerprints, etc.)
- **Upgrade password**: Embed uninstall password in the EXE installer or PS1 launcher
- **Silent install options**: Configure 7-Zip progress bar visibility and MSI UI mode
- **EXE repackaging**: Unpack EXE packages with 7-Zip, customize contents, and rebuild as SFX archive
- **Post-actions**: Run custom actions after package generation (copy files, generate EXE runner)
- **Conditional configuration**: Filter configuration files based on site or other variables
- **Package repository**: Optionally store source packages locally for future reuse

## Requirements

- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges may be required for some operations

## Quick Start

```powershell
.\CheckPoint_CustomizePackage.ps1
```

The script guides you through an interactive CLI workflow:

1. **Select a package** — Download from management, pick from repository, or browse for a file
2. **Select a VPN site** — Choose site and authentication method
3. **Configure general settings** — Log folders and SCCM tagging
4. **Configure install steps** — Actions to run before and after installation
5. **Configure client settings** — `trac.defaults` customization (certificate filtering, always connect, etc.)
6. **Choose trac.defaults integration** — Embed inside MSI or apply after setup
7. **Customize MSI properties** — SDL, FIXED_MAC, NoKeep, etc.
8. **Configure post-actions** — Copy scripts, generate EXE runner
9. **Set upgrade password** (optional)
10. **Select silent install options** (EXE only)

The output is generated in `output\<package_name>\`.

## Configuration

All configuration is done through JSONC files in the `input\` directory:

| Folder | Purpose |
|--------|---------|
| `site\` | VPN site definitions (address, authentication method, SDL, log level) |
| `install_general_config\` | General install settings (log folder, SCCM tag) |
| `install_steps_before\` | Actions to run before installation |
| `install_steps_after\` | Actions to run after installation |
| `client_configuration\` | `trac.defaults` customization (always connect, hotspot, certificate filtering, machine auth) |
| `package_customization_msi\` | MSI property overrides |
| `package_customization_post_actions\` | Post-generation actions (copy files, build runner) |

Each folder contains example files (prefixed with `00_`) that can be used as templates.

### Conditional filtering

Configuration files can include a `Filter` property to restrict their availability based on context:

```jsonc
{
    "Description": "Example WW",
    // Only shown when the selected site is vpn.example.com
    "Filter": "$Variables[\"site\"] -in @(\"vpn.example.com\")"
}
```

## Project Structure

```
CheckPoint_CustomizePackage/
├── CheckPoint_CustomizePackage.ps1      # Main script
├── Install-CheckPointEndpointSecurity.ps1  # Generated installer script
├── input/
│   ├── site/                            # VPN site configurations
│   ├── install_general_config/          # General install settings
│   ├── install_steps_before/            # Pre-install actions
│   ├── install_steps_after/             # Post-install actions
│   ├── client_configuration/            # trac.defaults customization
│   ├── package_customization_msi/       # MSI property overrides
│   ├── package_customization_post_actions/  # Post-generation actions
│   └── packages/                        # Package repository
├── output/                              # Generated output packages
├── UDF/                                 # Reusable function modules
│   ├── PSSomeAPIThings/
│   ├── PSSomeAppsThings/
│   ├── PSSomeCheckPointEndpointThings/
│   ├── PSSomeCheckPointEPMThings/
│   ├── PSSomeCLIThings/
│   ├── PSSomeCoreThings/
│   ├── PSSomeDataThings/
│   ├── PSSomeEngineThings/
│   ├── PSSomeFileThings/
│   ├── PSSomeKnownAppsThings/
│   └── PSSomeSystemThings/
└── tools/
    └── 7-Zip/                           # 7-Zip for EXE packaging
```

## Documentation

See [DOC.md](doc/DOC.md) for the full documentation, including step-by-step walkthrough with screenshots for both MSI and EXE workflows, and detailed configuration file reference.

## Release Notes

- **2.3** — Migrated to modules, added input folder selection via `-InputDir` parameter
- **2.2** — Fixed file selection for EPS.msi/install.exe, improved EXE extraction with unique temp folders, added selected blades to output folder name, download packages from management server, open File Explorer after generation
- **2.1** — Dynamic EXE management
- **2.0** — Site creation inside MSI, MSI path support, post-actions moved to separate JSON config files
- **1.1.1** — Forced UTF-8 with BOM output encoding
- **1.1** — Simplified architecture: removed legacy VPN site creation and trac file copy, moved trac.defaults items to config.json
- **1.0** — First release

## License

This project is licensed under **[PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0)**.

You are free to use, modify, and distribute this software for any **noncommercial purpose**. See [LICENSE](LICENSE) for full terms.

## Disclaimer

This project is not affiliated with, endorsed by, or sponsored by Check Point Software Technologies Ltd. "Check Point", "Endpoint Security", "Harmony Endpoint", "SmartEndpoint", and "SmartDashboard" are trademarks or registered trademarks of Check Point Software Technologies Ltd.
