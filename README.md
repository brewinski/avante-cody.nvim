<p align="center">
  <h1 align="center">avante-cody.nvim</h2>
</p>

<p align="center">
  Sourcegraph Cody provider for avante.nvim
</p>

## ⚡️ Features

- Integration with Sourcegraph Cody in [avante.nvim](https://github.com/brewinski/avante.nvim)
- Support Sourcegraph Cloud Enterprise  
- Experimental / Limited support for free, pro and enterprise starter accounts

> ⚡ **Account Ban Warning**: Using Cody Free or Pro accounts outside of Sourcegraph's official IDE may result in your account being flagged for spam and potentially banned. This is due to Sourcegraph's Acceptable Use Policy. Enterprise accounts are not affected by this limitation however there are no garantees. If you're using a Free or Pro account, please be aware of this risk.


## 📋 Installation

### Prerequisites

- [Neovim](https://neovim.io/) (0.8.0 or later)
- [avante.nvim](https://github.com/brewinski/avante.nvim) (installed and configured)
- A Sourcegraph account with Cody access. Ideally a Sourcegraph Cloud Enterprise account.

<div align="center">
<table>
<thead>
<tr>
<th>Package manager</th>
<th>Snippet</th>
</tr>
</thead>
<tbody>
<tr>
<td>

[folke/lazy.nvim](https://github.com/folke/lazy.nvim)

</td>
<td>

```lua
-- Add to your existing avante.nvim configuration
-- See https://github.com/yetone/avante.nvim#installation for full avante setup
{
  'yetone/avante.nvim',
  opts = {
    provider = "avante-cody", -- REQUIRED: This tells avante to use the Cody provider
  },
  dependencies = {
    -- Add avante-cody.nvim as a dependency
    'brewinski/avante-cody.nvim',
    opts = {
      providers = {
        ['avante-cody'] = {
          endpoint = 'https://sourcegraph.com',
          api_key_name = 'SRC_ACCESS_TOKEN',
        },
      },
    },
  }
}
```

</td>
</tr>
<tr>
<td>

[wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

</td>
<td>

```lua
-- Add to your existing avante.nvim configuration
use {
  "yetone/avante.nvim",
  config = function()
    require("avante").setup({
      provider = "avante-cody", -- REQUIRED: This tells avante to use the Cody provider
    })
  end,
  requires = {
    "brewinski/avante-cody.nvim",
    config = function()
      require("avante-cody").setup({
        providers = {
          ['avante-cody'] = {
            endpoint = 'https://sourcegraph.com',
            api_key_name = 'SRC_ACCESS_TOKEN',
          },
        },
      })
    end
  }
}
```

</td>
</tr>
<tr>
<td>

[junegunn/vim-plug](https://github.com/junegunn/vim-plug)

</td>
<td>

```vim
" Add to your existing avante.nvim configuration
Plug 'yetone/avante.nvim'
Plug 'brewinski/avante-cody.nvim'

" After plug#end():
lua << EOF
  require("avante").setup({
    provider = "avante-cody", -- REQUIRED: This tells avante to use the Cody provider
  })
  require("avante-cody").setup({
    providers = {
      ['avante-cody'] = {
        endpoint = 'https://sourcegraph.com',
        api_key_name = 'SRC_ACCESS_TOKEN',
      },
    },
  })
EOF
```

</td>
</tr>
</tbody>
</table>
</div>

## ☄ Getting started

### What is avante-cody.nvim?

This plugin adds **Sourcegraph Cody** as a provider to **avante.nvim**, giving you access to:
- 🤖 **Claude 3.5 Sonnet** and other advanced AI models through Sourcegraph
- 🧠 **Code-aware assistance** with full context of your codebase
- 🏢 **Enterprise-grade security** and compliance
- ⚡ **Full agentic capabilities** - code editing, file creation, multi-step tasks

### Quick Start Guide

**Step 1: Install the plugin** (using your preferred package manager from above)

**Step 2: Get your Sourcegraph access token**
1. Go to [https://sourcegraph.com](https://sourcegraph.com) (or your enterprise instance)
2. Navigate to **Settings** → **Access tokens**
3. **Generate new token** with appropriate scopes
4. Set your environment variable: `export SRC_ACCESS_TOKEN="sgp_your_token_here"`

**Step 3: Basic configuration**
```lua
require("avante-cody").setup({
  providers = {
    ['avante-cody'] = {
      endpoint = "https://sourcegraph.com", -- or your enterprise URL
      api_key_name = "SRC_ACCESS_TOKEN",
      model = "anthropic::2024-10-22::claude-sonnet-4-latest", -- optional
    }
  }
})
```

**Step 4: Test it works**
1. Restart Neovim
2. Open a file and trigger avante (`:AvanteChat` or your configured keybinding)
3. You should see "avante-cody" as the active provider
4. Ask simple question like "Explain this function" to verify it's working

## ⚙ Configuration

<details>
<summary>Click to unfold the full list of options with their default values</summary>

```lua
require("avante-cody").setup({
  debug = false, -- Enable debug logging
  providers = {
    ['avante-cody'] = {
      -- defaults
      use_xml_format = true,
      disable_tools = false,
      endpoint = "https://sourcegraph.com",
      api_key_name = "SRC_ACCESS_TOKEN",
      max_tokens = 30000,
      max_output_tokens = 4000,
      stream = true,
      topK = -1,
      topP = -1,
      model = "anthropic::2024-10-22::claude-sonnet-4-latest",
      proxy = nil,
      allow_insecure = false, -- Allow insecure server connections
      timeout = 30000, -- Timeout in milliseconds
      temperature = 0,
      cody_context = {},
      role_map = {
          user = "human",
          assistant = "assistant",
          system = "system",
      },
    }
  }
})
```

</details>

## 🔒 Authentication Methods

Supports the same authentication methods as avante.nvim. See [avante.nvim wiki](https://github.com/yetone/avante.nvim/wiki#secrets) for more information.

### Environment Variable 

```lua

['avante-cody'] = {
  api_key_name = "SRC_ACCESS_TOKEN",
}
```

> ⚠️ It's recommended to load this from a secure environment variable or secrets manager

### CLI CMD Integration

```lua

['avante-cody'] = {
  api_key_name = "cmd:<your_command_here>",
}
```

### Endpoint Configuration

You can configure the endpoint in several ways:

```lua
-- Option 1: Direct URL (most common)
['avante-cody'] = {
  endpoint = "https://my-company.sourcegraphcloud.com",
  api_key_name = "SRC_ACCESS_TOKEN",
}

-- Option 2: Environment variable (auto-detected if not a URL)
-- First set: export SRC_ENDPOINT="https://my-company.sourcegraphcloud.com"
['avante-cody'] = {
  endpoint = "SRC_ENDPOINT", -- Resolves to: "https://my-company.sourcegraphcloud.com"
  api_key_name = "SRC_ACCESS_TOKEN",
}

-- Option 3: Explicit environment variable with env: prefix
['avante-cody'] = {
  endpoint = "env:SRC_ENDPOINT", -- Explicitly get from environment variable
  api_key_name = "SRC_ACCESS_TOKEN",
}

-- Option 4: Command-based endpoint resolution
['avante-cody'] = {
  endpoint = "cmd:vault kv get -field=endpoint secret/sourcegraph",
  api_key_name = "SRC_ACCESS_TOKEN",
}
```

**Environment Variables:**
- `SRC_ENDPOINT`: Complete endpoint URL (e.g., `https://my-company.sourcegraphcloud.com`)

**Resolution Logic:**
1. If endpoint starts with `cmd:` - Execute the command and use its output as the endpoint
2. If endpoint starts with `env:` - Get value from the specified environment variable  
3. If endpoint doesn't look like a URL - Try to resolve it as an environment variable name
4. Otherwise use the literal endpoint value

This is especially useful for enterprise accounts where you don't want to expose instance names in your dotfiles or configuration.

## 🤝 Using with avante.nvim

Once configured, you can use all avante.nvim features with the Sourcegraph Cody provider:
<img width="690" alt="image" src="https://github.com/user-attachments/assets/b336111f-60a0-4144-b6f8-7d4798bf48e0" />

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 📄 License

This project is licensed under MIT License - see the LICENSE file for details.
