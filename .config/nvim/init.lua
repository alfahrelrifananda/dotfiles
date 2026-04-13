-- ============================================================================
-- EDITOR OPTIONS
-- ============================================================================

-- Mouse and Selection
vim.opt.mouse = "a"
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = "mouse,key"

-- UI Display
vim.opt.cursorline = true
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.background = "dark"

-- Navigation
vim.opt.whichwrap:append("<,>,[,]")

-- Transparent Background
vim.api.nvim_set_hl(0, "Normal", { bg = nil })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = nil })

-- ============================================================================
-- KEYMAPS - STANDARD EDITOR SHORTCUTS
-- ============================================================================

-- Copy (Ctrl+C)
vim.keymap.set("v", "<C-c>", '"+y<Esc>', { desc = "Copy" })
vim.keymap.set("n", "<C-c>", '"+yy', { desc = "Copy line" })
vim.keymap.set("i", "<C-c>", '<Esc>"+yyi', { desc = "Copy line" })

-- Cut (Ctrl+X)
vim.keymap.set("n", "<C-x>", '"+dd', { desc = "Cut line" })
vim.keymap.set("i", "<C-x>", '<Esc>"+ddi', { desc = "Cut line" })
vim.keymap.set("v", "<C-x>", '"+d', { desc = "Cut selection" })

-- Paste (Ctrl+V)
vim.keymap.set("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })
vim.keymap.set("c", "<C-v>", "<C-r>+", { desc = "Paste in command mode" })

-- Select All (Ctrl+A)
vim.keymap.set("n", "<C-a>", "gggH<C-o>G", { desc = "Select all" })
vim.keymap.set("i", "<C-a>", "<Esc>gggH<C-o>G", { desc = "Select all" })

-- Undo (Ctrl+Z)
vim.keymap.set("n", "<C-z>", "u", { desc = "Undo" })
vim.keymap.set("i", "<C-z>", "<C-o>u", { desc = "Undo" })

-- Redo (Ctrl+Y)
vim.keymap.set("n", "<C-y>", "<C-r>", { desc = "Redo" })
vim.keymap.set("i", "<C-y>", "<C-o><C-r>", { desc = "Redo" })

-- ============================================================================
-- LAZY.NVIM PLUGIN MANAGER SETUP
-- ============================================================================

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

-- ============================================================================
-- PLUGINS
-- ============================================================================

require("lazy").setup({

	-- ========================================================================
	-- COLOR SCHEME - Tokyo Night
	-- ========================================================================
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "night",
				transparent = true,
			})
			vim.cmd([[colorscheme tokyonight]])
		end,
	},

	-- ========================================================================
	-- FUZZY FINDER - Telescope
	-- ========================================================================
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local builtin = require("telescope.builtin")
			
			-- File Navigation Keymaps
			vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find files" })
			vim.keymap.set("n", "<C-r>", builtin.oldfiles, { desc = "Recent files" })
			
			-- Search Keymaps
			vim.keymap.set("n", "<C-f>", builtin.live_grep, { desc = "Search in files" })
			vim.keymap.set("n", "<C-/>", builtin.current_buffer_fuzzy_find, { desc = "Search in current file" })
		end,
	},

	-- ========================================================================
	-- AI COMPLETION - Supermaven
	-- ========================================================================
	{
		"supermaven-inc/supermaven-nvim",
		config = function()
			require("supermaven-nvim").setup({
				color = {
					suggestion_color = "#808080",
					cterm = 244,
				},
			})
		end,
		init = function()
			vim.g.supermaven_disable_activation_messages = true
		end,
	},

	-- ========================================================================
	-- COMMENTING - Comment.nvim
	-- ========================================================================
	{
		"numToStr/Comment.nvim",
		config = function()
			require("Comment").setup()

			-- Toggle Comment (Ctrl+;)
			vim.keymap.set("n", "<C-;>", function()
				require("Comment.api").toggle.linewise.current()
			end, { desc = "Toggle comment" })

			vim.keymap.set("v", "<C-;>", function()
				local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
				vim.api.nvim_feedkeys(esc, "nx", false)
				require("Comment.api").toggle.linewise(vim.fn.visualmode())
			end, { desc = "Toggle comment" })

			vim.keymap.set("i", "<C-;>", function()
				vim.cmd("stopinsert")
				require("Comment.api").toggle.linewise.current()
			end, { desc = "Toggle comment" })
		end,
	},

	-- ========================================================================
	-- CODE FORMATTING - Conform.nvim
	-- ========================================================================
	{
		"stevearc/conform.nvim",
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					-- Web Development
					javascript = { "prettier" },
					typescript = { "prettier" },
					javascriptreact = { "prettier" },
					typescriptreact = { "prettier" },
					vue = { "prettier" },
					html = { "prettier" },
					css = { "prettier" },
					scss = { "prettier" },
					
					-- Data Formats
					json = { "prettier" },
					jsonc = { "prettier" },
					yaml = { "prettier" },
					markdown = { "prettier" },
					graphql = { "prettier" },
					xml = { "xmlformat" },
					sql = { "sql_formatter" },
					
					-- Systems Programming
					c = { "clang_format" },
					cpp = { "clang_format" },
					java = { "clang_format" },
					rust = { "rustfmt" },
					go = { "gofmt" },
					
					-- Scripting Languages
					python = { "black" },
					lua = { "stylua" },
					ruby = { "rubocop" },
					php = { "php_cs_fixer" },
					sh = { "shfmt" },
					bash = { "shfmt" },
				},
			})

			-- Format and Save (Ctrl+S)
			vim.keymap.set({ "n", "v", "i" }, "<C-s>", function()
				if vim.fn.mode() == "i" then
					vim.cmd("stopinsert")
				end
				require("conform").format({ async = true, lsp_fallback = true })
				vim.cmd("write")
			end, { desc = "Format and save" })
		end,
	},
})
