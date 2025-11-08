return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for default `toggle()` implementation.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Automatically reload the current file when it changes on disk.
      auto_reload = true,

      -- Configure how opencode interacts with snacks.nvim.
      snacks = {
        -- Configuration for `opencode.ask()`.
        input = {
          border = "rounded",
          title = " Ask opencode ",
        },

        -- Configuration for `opencode.select()`.
        picker = {
          border = "rounded",
          title = " opencode actions ",
        },

        -- Configuration for `opencode.toggle()`.
        terminal = {
          border = "rounded",
          title = " opencode ",
        },
      },
    }

    -- Required for `opts.auto_reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set({ "n", "x" }, "<leader>ok", function()
      require("opencode").ask("@this: ", { submit = true })
    end, { desc = "Ask opencode" })

    vim.keymap.set({ "n", "x" }, "<leader>ox", function()
      require("opencode").select()
    end, { desc = "Execute opencode action…" })

    vim.keymap.set({ "n", "x" }, "<leader>oa", function()
      require("opencode").prompt("@this")
    end, { desc = "Add to opencode" })

    vim.keymap.set("n", "<leader>ot", function()
      require("opencode").toggle()
    end, { desc = "Toggle opencode" })

    vim.keymap.set("n", "<leader>ou", function()
      require("opencode").command("messages_half_page_up")
    end, { desc = "opencode half page up" })

    vim.keymap.set("n", "<leader>od", function()
      require("opencode").command("messages_half_page_down")
    end, { desc = "opencode half page down" })

    -- Additional useful keymaps for enhanced productivity
    vim.keymap.set({ "n", "x" }, "<leader>oe", function()
      require("opencode").ask("Explain @this", { submit = true })
    end, { desc = "Explain code with opencode" })

    vim.keymap.set({ "n", "x" }, "<leader>of", function()
      require("opencode").ask("Fix issues in @this", { submit = true })
    end, { desc = "Fix code with opencode" })

    vim.keymap.set({ "n", "x" }, "<leader>or", function()
      require("opencode").ask("Refactor @this", { submit = true })
    end, { desc = "Refactor code with opencode" })

    -- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o".
    vim.keymap.set("n", "+", "<leader>op", { desc = "Increment", noremap = true })
    vim.keymap.set("n", "-", "<leader>om", { desc = "Decrement", noremap = true })
  end,
}
