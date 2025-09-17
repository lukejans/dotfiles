-- use the same background as the terminal
vim.opt.termguicolors = true
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })

-- always use a block cursor
vim.opt.guicursor = "n-v-c-i:block"

-- turn off concealment
vim.opt.conceallevel = 1
