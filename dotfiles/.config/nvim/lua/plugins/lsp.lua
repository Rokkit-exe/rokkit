return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()

      require("mason-lspconfig").setup({
        -- use lspconfig server names
        ensure_installed = { "svelte", "html", "cssls", "ts_ls", "gopls", "lua_ls" },
        automatic_installation = true,
      })

      local lspconfig = require("lspconfig")

      local servers = { "svelte", "html", "cssls", "ts_ls", "gopls", "lua_ls", "dartls" }

      local function on_attach(_, bufnr)
        local nmap = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end
        nmap("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
        nmap("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
        nmap("<leader>f", function()
          vim.lsp.buf.format({ async = true })
        end, "[F]ormat Document")
      end

      for _, server in ipairs(servers) do
        lspconfig[server].setup({
          on_attach = on_attach,
        })
      end
    end,
  },
}
