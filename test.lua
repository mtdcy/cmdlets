local nvimts = '/tmp/nvim-treesitter'
vim.system {
  'git',
  'clone',
  '--filter=blob:none',
  '--single-branch',
  'https://github.com/nvim-treesitter/nvim-treesitter.git',
  nvimts
}:wait()
vim.opt.runtimepath:prepend(nvimts)
require('nvim-treesitter.configs').setup({})
