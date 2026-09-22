# dotfiles-nvim

A single-file Neovim configuration (`init.lua`) built on [lazy.nvim](https://github.com/folke/lazy.nvim),
with native LSP, Treesitter, Telescope, Harpoon and Oil.

## Requirements

> [!IMPORTANT]
> **Neovim 0.11 or newer is required.** The config uses the native `vim.lsp.config()` /
> `vim.lsp.enable()` API, which does not exist in 0.10. On 0.10 the editor still starts,
> but LSP silently never attaches. Debian/Ubuntu stable ship 0.10 or older — install
> Neovim from the [official releases](https://github.com/neovim/neovim/releases) instead
> of your distro's package manager.

### Required

| Dependency | Needed by | Notes |
| --- | --- | --- |
| Neovim ≥ 0.11 | everything | see the note above |
| `git`, `curl`, `unzip`, `tar` | lazy.nvim, mason | bootstrap and downloads |
| `tree-sitter` CLI | nvim-treesitter | **easy to miss** — see below |
| C compiler + `make` | parser compilation, LuaSnip `jsregexp` | `build-essential` on Debian |
| `ripgrep` | Telescope `live_grep` | `<leader>sg` is dead without it |
| Nerd Font | nvim-web-devicons, Oil | terminal must be set to it |
| `wl-clipboard` (Wayland) or `xclip` (X11) | `clipboard = "unnamedplus"` | without it, yanks never reach the system clipboard |

> [!WARNING]
> **The `tree-sitter` CLI is a hard requirement.** This config pins nvim-treesitter to its
> `main` branch, which shells out to `tree-sitter build` to compile parsers. This differs
> from the old `master` branch, which compiled with the C compiler directly. Without the
> CLI on `PATH`, *every* parser fails with `ENOENT: no such file or directory (cmd): 'tree-sitter'`.
> A C compiler alone is not enough.

### Optional

| Dependency | Needed by | Without it |
| --- | --- | --- |
| Node.js + npm | `ts_ls`, `prettier` (installed via Mason) | no TypeScript LSP or JS/TS formatting |
| `rustup` toolchain | `rustfmt`, `clippy` | Rust format-on-save and clippy diagnostics no-op |
| `fd` | Telescope `find_files` | falls back to `find`, slower, ignores `.gitignore` |

> [!NOTE]
> `typescript-language-server` v6 declares `node >= 22.22.2`. It currently runs on Node 20
> and npm only emits an `EBADENGINE` warning, but Node 22+ is the safer target.

## Install

### Debian / Ubuntu

```bash
# System packages
sudo apt install build-essential ripgrep fd-find nodejs npm wl-clipboard git curl unzip
ln -s "$(command -v fdfind)" ~/.local/bin/fd   # Debian names the binary fdfind

# Neovim (distro packages are too old)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# tree-sitter CLI
curl -L https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz \
  | gunzip > ~/.local/bin/tree-sitter && chmod +x ~/.local/bin/tree-sitter

# Rust toolchain (optional)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile default --component rust-src

# A Nerd Font (optional but recommended)
mkdir -p ~/.local/share/fonts/JetBrainsMonoNerdFont
curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o /tmp/JBM.zip
unzip -oq /tmp/JBM.zip -d ~/.local/share/fonts/JetBrainsMonoNerdFont && fc-cache -f
```

### Config

```bash
git clone https://github.com/tympaniplayer/dotfiles-nvim.git ~/.config/nvim
nvim
```

lazy.nvim bootstraps itself on first launch and installs everything. Mason pulls
`typescript-language-server` and `rust-analyzer`; install `prettier` with
`:MasonInstall prettier`. Then verify with `:checkhealth`.

> [!NOTE]
> `:checkhealth` reports a `luarocks` error and several `mason` "not available" warnings
> (Go, Java, PHP, julia). Both are safe to ignore — lazy itself notes that no plugin here
> requires luarocks.

## Terminal transparency

The colorscheme sets `transparent_background = true`, so the terminal's own background
shows through. Set the alpha in your terminal — in [foot](https://codeberg.org/dnkl/foot):

```ini
[main]
font=JetBrainsMono Nerd Font Mono:size=12

[colors]
alpha=0.7
```

Floating windows (Telescope, Oil, diagnostics) keep a solid background on purpose so
popups stay readable.

## Keymaps

Leader is `<Space>`.

### General

| Key | Action |
| --- | --- |
| `<leader>w` / `<leader>q` / `<leader>z` | write / quit / write+quit |
| `<leader>no` | clear search highlight |
| `<C-h/j/k/l>` | move between windows |
| `<C-u>` / `<C-d>` / `n` / `N` / `G` / `gg` | move, then recenter |
| `S` | substitute word under cursor |
| `<leader>f` | format buffer (conform) |

### LSP

| Key | Action |
| --- | --- |
| `K` | hover |
| `gd` / `gD` / `gr` / `gi` | definition / declaration / references / implementation |
| `<leader>rn` / `<leader>ca` | rename / code action |
| `[d` / `]d` | previous / next diagnostic |
| `<leader>d` | line diagnostics |

### Telescope

| Key | Action |
| --- | --- |
| `<leader>sf` / `<leader>sg` | find files / live grep |
| `<leader>sb` / `<leader>sh` | buffers / help tags |
| `<leader>?` | recent files |
| `<leader>/` | fuzzy find in buffer |

### Harpoon & Oil

| Key | Action |
| --- | --- |
| `<leader>ha` / `<leader>ho` | add file / toggle menu |
| `<leader>hr` / `<leader>hc` | remove / clear all |
| `<leader>1`–`<leader>9` | jump to marked file |
| `-` | open parent directory (Oil) |
| `<leader>e` | Oil in a floating window |

## Language support

Treesitter parsers and LSP are configured for Lua, Vim, TypeScript/TSX, JavaScript, Rust,
JSON, YAML, TOML, Bash and Markdown. Formatting runs on save via conform: `prettier` for
JS/TS, `rustfmt` for Rust.
