# TsekNet dotfiles 🛠

Cross-platform automated system configuration. Run script. Setup System.

- Problem: Setting up a system requires configuring a variable amount of files (dotfiles, such as ~/.bashrc) locally.
- Solution: Store configuration files (dotfiles) on GitHub and leverage [chezmoi](https://www.chezmoi.io/) to keep those files up-to-date.

New to dotfiles? Check out [dotfiles.github.io](https://dotfiles.github.io/) for more information.

## Installing

Below are the commands you can run to get started with my dotfiles.

⚠ Be sure to review the code before executing random scripts on the internet. TL;DR can be found in [install.ps1](install.ps1) Comment-Based Help.

### Linux

Use curl to download the package, and bash to execute it.

```bash
curl -fsSL https://git.io/tseksh | bash
```

### Windows

Run the following command in PowerShell as administrator:

```powershell
iex ((New-Object Net.WebClient).DownloadString('https://git.io/tsekps'))
```

## Usage

```bash
chezmoi init --apply --verbose https://github.com/tseknet/dotfiles.git
# OR
chezmoi init --apply --verbose git@github.com:tseknet/dotfiles.git
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

[MIT](https://choosealicense.com/licenses/mit/)
