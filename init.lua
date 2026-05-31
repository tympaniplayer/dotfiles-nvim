-- ~/.config/nvim/init.lua

------------------------------------------------------------
-- Leader + basic options
------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = false 
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.updatetime = 200
vim.opt.timeoutlen = 400
vim.opt.scrolloff = 8
vim.opt.clipboard = "unnamedplus"
vim.opt.completeopt = { "menuone", "noselect" }
vim.cmd.colorscheme("default")
------------------------------------------------------------
-- Global keymaps
------------------------------------------------------------
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
vim.keymap.set("n", "<leader>z", "<cmd>wq<cr>", { desc = "Save+Quit" })
vim.keymap.set("n", "<leader>no", "<cmd>noh<cr>", { desc = "No highlight" })

vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Window left" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Window down" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Window up" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Center after movement (muscle memory)
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "G", "Gzz")
vim.keymap.set("n", "gg", "ggzz")
vim.keymap.set("n", "%", "%zz")
vim.keymap.set("n", "*", "*zz")
vim.keymap.set("n", "#", "#zz")

-- Quick substitute word under cursor
vim.keymap.set("n", "S", function()
  local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
  local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Substitute word" })

------------------------------------------------------------
-- lazy.nvim bootstrap
------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

------------------------------------------------------------
-- Helpers (LSP root)
------------------------------------------------------------
local function root_with(patterns)
  return function(bufnr)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then
      return vim.loop.cwd()
    end
    return vim.fs.root(fname, patterns) or vim.loop.cwd()
  end
end

------------------------------------------------------------
-- Plugins
------------------------------------------------------------
require("lazy").setup({
   {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").install({
      "lua", "vim", "vimdoc",
      "typescript", "tsx", "javascript",
      "rust", "json", "yaml", "toml",
      "bash", "markdown", "markdown_inline",
    })

    -- Highlight: main has no `highlight = { enable = true }`.
    -- Start treesitter per-buffer wherever a parser exists; silently no-op otherwise.
    vim.api.nvim_create_autocmd("FileType", {
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
},

  -- Mason (installs LSP binaries)
  { "mason-org/mason.nvim", opts = {} },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = { "ts_ls", "rust_analyzer" },
    },
  },

  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping(function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
              cmp.confirm({ select = true })
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources(
          { { name = "nvim_lsp" }, { name = "luasnip" } },
          { { name = "buffer" } }
        ),
      })
    end,
  },

  -- LSP (Neovim 0.11 native API)
  {
    "hrsh7th/cmp-nvim-lsp",
    lazy = false,
    config = function()
      -- LSP-only keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
        callback = function(args)
          local bufnr = args.buf
          local nmap = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
          end

          nmap("K", vim.lsp.buf.hover, "Hover")
          nmap("gd", vim.lsp.buf.definition, "Goto definition")
          nmap("gD", vim.lsp.buf.declaration, "Goto declaration")
          nmap("gr", vim.lsp.buf.references, "References")
          nmap("gi", vim.lsp.buf.implementation, "Implementation")
          nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
          nmap("<leader>ca", vim.lsp.buf.code_action, "Code action")

          nmap("[d", function()
            vim.diagnostic.goto_prev()
            vim.cmd("normal! zz")
          end, "Prev diagnostic")

          nmap("]d", function()
            vim.diagnostic.goto_next()
            vim.cmd("normal! zz")
          end, "Next diagnostic")

          nmap("<leader>d", vim.diagnostic.open_float, "Line diagnostics")
        end,
      })

      local caps = require("cmp_nvim_lsp").default_capabilities()

      -- TypeScript (ts_ls = typescript-language-server)
      vim.lsp.config("ts_ls", {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
        },
        root_dir = root_with({ "tsconfig.json", "package.json", ".git" }),
        capabilities = caps,
      })

      -- Rust
      vim.lsp.config("rust_analyzer", {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_dir = root_with({ "Cargo.toml", ".git" }),
        capabilities = caps,
        settings = {
          ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
          },
        },
      })

      vim.lsp.enable({ "ts_ls", "rust_analyzer" })
    end,
  },

  -- Conform (formatting boss)
  {
    "stevearc/conform.nvim",
    config = function()
      local conform = require("conform")

      conform.setup({
        notify_on_error = true,
        formatters_by_ft = {
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          rust = { "rustfmt" },
          -- lua = { "stylua" },
        },
        format_on_save = {
          timeout_ms = 1500,
          lsp_format = "fallback",
        },
      })

      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      vim.keymap.set({ "n", "v" }, "<leader>f", function()
        conform.format({
          async = true,
          timeout_ms = 1500,
          lsp_format = "fallback",
        })
      end, { desc = "Format (Conform)" })
    end,
  },

  -- Oil
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("oil").setup()
      vim.keymap.set("n", "-", "<cmd>Oil<cr>", { desc = "Oil: parent dir" })
      vim.keymap.set("n", "<leader>e", function()
        require("oil").toggle_float()
      end, { desc = "Oil (float)" })
    end,
  },

  -- Harpoon v1 (classic muscle memory)
  {
    "ThePrimeagen/harpoon",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local mark = require("harpoon.mark")
      local ui = require("harpoon.ui")

      vim.keymap.set("n", "<leader>ha", mark.add_file, { desc = "Harpoon add" })
      vim.keymap.set("n", "<leader>ho", ui.toggle_quick_menu, { desc = "Harpoon menu" })
      vim.keymap.set("n", "<leader>hr", mark.rm_file, { desc = "Harpoon remove" })
      vim.keymap.set("n", "<leader>hc", mark.clear_all, { desc = "Harpoon clear all" })

      for i = 1, 9 do
        vim.keymap.set("n", "<leader>" .. i, function()
          ui.nav_file(i)
        end, { desc = "Harpoon " .. i })
      end
    end,
  },

  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<C-x>"] = actions.delete_buffer,
            },
          },
          file_ignore_patterns = { "node_modules", ".git", "_build", ".next" },
        },
      })

      local tb = require("telescope.builtin")
      vim.keymap.set("n", "<leader>?", tb.oldfiles, { desc = "Recent files" })
      vim.keymap.set("n", "<leader>sf", function()
        tb.find_files({ hidden = true })
      end, { desc = "Search files" })
      vim.keymap.set("n", "<leader>sg", tb.live_grep, { desc = "Search grep" })
      vim.keymap.set("n", "<leader>sb", tb.buffers, { desc = "Search buffers" })
      vim.keymap.set("n", "<leader>sh", tb.help_tags, { desc = "Search help" })
      vim.keymap.set("n", "<leader>/", function()
        tb.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({ previewer = false }))
      end, { desc = "Fuzzy in buffer" })
    end,
  },

  -- Small QoL
  { "lewis6991/gitsigns.nvim", config = true },
  { "numToStr/Comment.nvim", config = true },
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup({
        map_cr = false, -- don't mess with Enter
        map_bs = false, -- don't mess with Backspace
      })
    end,
  },
  { "tpope/vim-surround" },
})

------------------------------------------------------------
-- Diagnostics + yank highlight
------------------------------------------------------------
vim.diagnostic.config({
  virtual_text = false,
  float = { border = "rounded" },
  severity_sort = true,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})
