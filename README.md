<p align="center">
  <h1 align="center">avante-cody.nvim</h2>
</p>

<p align="center">
  Sourcegraph Cody provider for avante.nvim
</p>

## ⚡️ Features

- Seamless integration with [Sourcegraph Cody AI](https://sourcegraph.com/cody) in [avante.nvim](https://github.com/brewinski/avante.nvim)
- Support for both Sourcegraph Cloud and self-hosted Sourcegraph instances
<!-- - Secure authentication using multiple methods including 1Password CLI -->
<!-- - Intelligent context gathering for more accurate code completions and explanations -->

## 📋 Installation

### Prerequisites

- [Neovim](https://neovim.io/) (0.8.0 or later)
- [avante.nvim](https://github.com/brewinski/avante.nvim) (installed and configured)
- A Sourcegraph account with Cody access

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
{
  'yetone/avante.nvim',
  {
    --  your avnte.nvim configuration
    -- ...
    dependencies = {
      'brewinski/avante-cody.nvim',
      opts = {
        providers = {
          ['avante-cody'] = {
            endpoint = 'https://sourcegraph.com',
            -- endpoint= 'https://<your_instance>.sourcegraphcloud.com',
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
-- TODO: confirm configuration for packer
use {
  "brewinski/avante-cody.nvim",
  requires = {
    "brewinski/avante.nvim",
  },
  config = function()
    require("avante-cody").setup({
      -- your configuration
    })
  end
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
" TODO: confirm configuration for vim-plug 
Plug 'brewinski/avante.nvim'
Plug 'brewinski/avante-cody.nvim'

" After plug#end():
lua << EOF
  require("avante-cody").setup({
    -- your configuration
  })
EOF
```

</td>
</tr>
</tbody>
</table>
</div>

## ☄ Getting started

1. Install the plugin using your preferred package manager as an avante.nvim dependency (see above)
2. Configure the plugin with your Sourcegraph details
3. Register the Cody provider with avante.nvim

```lua
-- Example configuration
require("avante-cody").setup({
  providers = {
    cody = {
      endpoint = "https://sourcegraph.com",
      api_key_name = "SRC_ACCESS_TOKEN",
      -- Other provider options
      model = "anthropic::2024-10-22::claude-3-7-sonnet-latest",
    }
  }
})
```

## ⚙ Configuration

<details>
<summary>Click to unfold the full list of options with their default values</summary>

```lua
require("avante-cody").setup({
  debug = false, -- Enable debug logging
  providers = {
    cody = {
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
      model = "anthropic::2024-10-22::claude-3-7-sonnet-latest",
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

cody = {
  api_key_name = "SRC_ACCESS_TOKEN",
}
```

> ⚠️ It's recommended to load this from a secure environment variable or secrets manager

### CLI CMD Integration

```lua

cody = {
  api_key_name = "cmd:<your_command_here>",
}
```

<!-- ## 🧰 Commands -->
<!---->
<!-- | Command | Description | -->
<!-- |---------|-------------| -->
<!-- | `:AvanteSelectProvider cody` | Select Cody as the active AI provider | -->
<!-- | `:AvanteCodyToggle` | Toggle the Cody provider on/off | -->

## 🤝 Using with avante.nvim

Once configured, you can use all avante.nvim features with the Sourcegraph Cody provider:
<img width="690" alt="image" src="https://github.com/user-attachments/assets/b336111f-60a0-4144-b6f8-7d4798bf48e0" />

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 🎭 Why Sourcegraph Cody?

- **Code Intelligence**: Cody is specifically designed for code understanding and generation
- **Self-hosting**: Support for self-hosted Sourcegraph instances allows for enhanced privacy
- **Integration**: Works seamlessly with existing Sourcegraph setups

## 📄 License

This project is licensed under MIT License - see the LICENSE file for details.
