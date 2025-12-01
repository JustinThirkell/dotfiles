# thirkcircus dotfiles

Your dotfiles are how you personalize your system. These are mine.

I was a little tired of having long alias files and everything strewn about
(which is extremely common on other dotfiles projects, too). That led to this
project being much more topic-centric. I realized I could split a lot of things
up into the main areas I used (Ruby, git, system libraries, and so on), so I
structured the project accordingly.

If you're interested in the philosophy behind why projects like these are
awesome, you might want to [read my post on the
subject](http://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/).

## topical

Everything's built around topic areas. If you're adding a new area to your
forked dotfiles — say, "Java" — you can simply add a `java` directory and put
files in there. Anything with an extension of `.zsh` will get automatically
included into your shell. Anything with an extension of `.symlink` will get
symlinked without extension into `$HOME` when you run `script/bootstrap`.

## what's inside

A lot of stuff. Seriously, a lot of stuff. Check them out in the file browser
above and see what components may mesh up with you.
[Fork it](https://github.com/thirkcircus/dotfiles/fork), remove what you don't
use, and build on what you do use.

## components

There's a few special files in the hierarchy.

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your
  environment.
- **topic/path.zsh**: Any file named `path.zsh` is loaded first and is
  expected to setup `$PATH` or similar.
- **topic/completion.zsh**: Any file named `completion.zsh` is loaded
  last and is expected to setup autocomplete.
- **topic/install.sh**: Any file named `install.sh` is executed when you run `script/install`. To avoid being loaded automatically, its extension is `.sh`, not `.zsh`.
- **topic/\*.symlink**: Any file ending in `*.symlink` gets symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked in when you run `script/bootstrap`.

## install

Run this:

```sh
git clone https://github.com/thirkcircus/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

This will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`,
which sets up a few paths that'll be different on your particular machine.

`dot` is a simple script that installs some dependencies, sets sane macOS
defaults, and so on. Tweak this script, and occasionally run `dot` from
time to time to keep your environment fresh and up-to-date. You can find
this script in `bin/`.

## Updates

To keep your dotfiles installation up-to-date across multiple machines, you'll need to sync your changes and run the appropriate commands. The `dot` command is designed to help with this.

### How to update based on what changed

#### 1. New brew installs (additions to `Brewfile`)

If you've added new applications or tools to the `Brewfile`, you can install them by running:

```sh
cd ~/.dotfiles
dot
```

The `dot` command will run `brew bundle` which installs any missing applications from your `Brewfile`. It also takes care of `brew update` and `brew upgrade`.

#### 2. New `install.sh` scripts

Run `dot -f` to force install scripts to run.

#### 3. Running `dot`

The `dot` command is your main tool for keeping things fresh. Running `dot` will:

- Pull the latest changes from your dotfiles git repository.
- Run `brew update`, `brew upgrade`, and `brew bundle` to manage your Homebrew packages.
- Set your macOS hostname.

On a fresh installation, or when run with the `-f` flag (`dot -f`), it will also:

- Install Homebrew if it's not present.
- Set macOS defaults (from `macos/set-defaults.sh`).
- Run all `install.sh` scripts via `script/install`.

You should run `dot` periodically to keep everything in sync.

#### 4. Changes to `.zsh` files or functions

Any files ending in `.zsh` are automatically loaded when you start a new shell session. If you make changes to these files (e.g., in the `zsh/` or `functions/` directories), you just need to pull the latest changes from your git repository. The `dot` command does this for you. The changes will be available in any new terminal session you start.

## Package Manifests

This dotfiles repo automatically tracks globally installed packages from various package managers. This ensures you don't lose track of tools you've installed when setting up a new machine.

### Supported Package Managers

- **uv** - Python tools (manifest: `uv/manifest.txt`)
- **npm** - Node.js global packages (manifest: `node/npm-manifest.txt`)
- **yarn** - Yarn global packages (manifest: `node/yarn-manifest.txt`)
- **cargo** - Rust packages (manifest: `rust/manifest.txt`)
- **go** - Go packages (manifest: `go/manifest.txt`)

### How it works

**Automatic snapshots:**
When you run `dot`, it automatically generates manifests for all installed packages from each package manager. These manifests are saved in the appropriate topic directories and should be committed to your dotfiles repo.

**Restoring packages:**
When you run `dot -f` (e.g., on a fresh machine), it automatically installs all packages from the manifests via the topic `install.sh` scripts.

**Manual operations:**

```sh
# Generate all manifests manually
script/generate-manifests

# Install packages from manifests manually
script/install
```

### Notes

- Package manifests track package names only, not versions
- Installation is idempotent - running install scripts won't reinstall existing packages
- If a package manager isn't installed, its manifest generation/installation is skipped
- Remember to commit manifest changes to keep them synced across machines

## bugs

I want this to work for everyone; that means when you clone it down it should
work for you even though you may not have `rbenv` installed, for example. That
said, I do use this as _my_ dotfiles, so there's a good chance I may break
something if I forget to make a check for a dependency.

If you're brand-new to the project and run into any blockers, please
[open an issue](https://github.com/thirkcircus/dotfiles/issues) on this repository
and I'd love to get it fixed for you!

## thanks

I copied Lutz Lengemann's excellent [dotfiles](https://github.com/mobilutz/dotfiles) which are based on [Zack Holman](https://github.com/holman)'s [dotfiles](https://github.com/holman/dotfiles) which are based on [Ryan Bates](https://github.com/ryanb) [dotfiles](https://github.com/ryanb/dotfiles).
