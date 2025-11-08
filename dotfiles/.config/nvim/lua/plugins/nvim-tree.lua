-- ~/.config/nvim/lua/plugins/nvim-tree.lua
return {
  "nvim-tree/nvim-tree.lua",
  opts = {
    filters = {
      dotfiles = true, -- ← show dotfiles
    },
  },
}
