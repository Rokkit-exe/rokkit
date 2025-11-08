-- default git-fugitive 
-- lua/plugins/git-fugitive.lua
return {
  {
    "tpope/vim-fugitive",
    cmd = {
      "Git",
      "G",
      "Gdiffsplit",
      "Gvdiffsplit",
      "Gread",
      "Gwrite",
      "Gdelete",
      "Gedit",
      "Gsplit",
      "Ggrep",
      "Gbrowse",
    },
    dependencies = {
      -- Optional: enable :Gbrowse for GitHub/GitLab/etc.
      "tpope/vim-rhubarb",
    },
    keys = {
      -- Status / UI
      { "<leader>gs", function() vim.cmd("Git") end, desc = "Git status (Fugitive)" },
      { "<leader>gS", function() vim.cmd("tab Git") end, desc = "Git status (tab)" },

      -- Diff & blame
      { "<leader>gd", ":Gdiffsplit<CR>", desc = "Git diff split" },
      { "<leader>gD", ":Gvdiffsplit<CR>", desc = "Git diff (vertical)" },
      { "<leader>gb", ":Git blame<CR>", desc = "Git blame (buffer)" },

      -- Stage / unstage current file
      { "<leader>ga", ":Git add %<CR>", desc = "Git add current file" },
      { "<leader>gu", ":Git reset -- %<CR>", desc = "Unstage current file" },

      -- Checkout / restore current file
      { "<leader>gr", ":Gread<CR>", desc = "Restore file from index/HEAD" },

      -- Write current buffer to index (stage changes in file)
      { "<leader>gw", ":Gwrite<CR>", desc = "Stage buffer (Gwrite)" },

      -- Commit / push / pull
      { "<leader>gc", ":Git commit<CR>", desc = "Git commit" },
      { "<leader>gC", ":Git commit --amend<CR>", desc = "Amend last commit" },
      { "<leader>gp", ":Git push<CR>", desc = "Git push" },
      { "<leader>gP", ":Git pull --rebase<CR>", desc = "Git pull --rebase" },

      -- Browse on remote (needs vim-rhubarb or similar)
      { "<leader>gB", ":Gbrowse<CR>", desc = "Open on remote (Gbrowse)" },

      -- Quick log for current file
      { "<leader>gl", ":Git log --oneline --decorate -- %<CR>", desc = "Git log (current file)" },

      -- Grep in repo
      { "<leader>gg", ":Ggrep ", desc = "Grep in Git repo", mode = "n" },
    },
    init = function()
      -- If you're on LazyVim: give which-key nice group names (optional)
      if pcall(require, "which-key") then
        require("which-key").add({
          { "<leader>g", group = "Git (Fugitive)" },
        })
      end
    end,
  },
}

