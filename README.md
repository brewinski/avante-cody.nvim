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

> ⚠️ **Important Rate Limit Warning**: Free, Pro, and Enterprise Starter accounts **will likely hit rate limits** without the recommended configuration below, making the tool unusable until limits reset.

> ⚡ **Account Ban Warning**: Using Cody Free or Pro accounts outside of Sourcegraph's official IDE may result in your account being flagged for spam and potentially banned. This is due to Sourcegraph's Acceptable Use Policy. Enterprise accounts are not affected by this limitation however there are no garantees. If you're using a Free or Pro account, please be aware of this risk.

### ⚠️ Recommended Configuration to Avoid Rate Limits

1. **Avante Settings** - Disable high-usage tools:
```lua
mode = "legacy"
disabled_tools = {
    'insert',
    'create',
    'str_replace',
    'replace_in_file'
}
```

2. **Avante-Cody Settings** - Disable additional tools:
```lua

  {
    -- cody free accounts:
    ['cody-free'] = {
      endpoint = 'https://sourcegraph.com',
      -- endpoint= 'https://<your_instance>.sourcegraphcloud.com',
      api_key_name = 'SRC_ACCESS_TOKEN',
      disable_tools = true
    },
    -- cody pro accounts:
    ['avante-pro'] = {
      endpoint = 'https://sourcegraph.com',
      -- endpoint= 'https://<your_instance>.sourcegraphcloud.com',
      api_key_name = 'SRC_ACCESS_TOKEN',
      --  rate limits are untested for pro accounts, this might not be required
      disable_tools = true
    },
    -- cody enterprise starter accounts:
    ['avante-enterprise-starter'] = {
      endpoint = 'https://sourcegraph.com',
      -- endpoint= 'https://<your_instance>.sourcegraphcloud.com',
      api_key_name = 'SRC_ACCESS_TOKEN',
      --  rate limits are untested for enterprise starter accounts, this might not be required
      disable_tools = true
    },
    -- cody enterprise accounts:
    ['avante-enterprise'] = {
      endpoint = 'https://<myworkspace>.sourcegraph.com',
      -- endpoint= 'https://<your_instance>.sourcegraphcloud.com',
      api_key_name = 'SRC_ACCESS_TOKEN',
    },
  }
```

3. **LLM Configuration Override** - Prevent unnecessary API calls:
```lua
{
    'brewinski/avante-cody.nvim',
    -- your other config options...
    config = function(_, opts)
        require('avante-cody').setup(opts)

        local llm = require 'avante.llm'
        llm.summarize_chat_thread_title = function(_, cb)
            -- prevent API calls for chat titles
            cb 'untitled'
        end

        llm.summarize_memory = function(_, _, cb)
            -- prevent API calls for memory summaries
            cb(nil)
        end
    end
}
```

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
    -- Recommended settings to avoid rate limits
    mode = "legacy",
    disabled_tools = {
      'insert',
      'create', 
      'str_replace',
      'replace_in_file'
    }
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
TODO
<!-- ```lua -->
<!-- -- TODO: confirm configuration for packer -->
<!-- use { -->
<!--   "brewinski/avante-cody.nvim", -->
<!--   requires = { -->
<!--     "brewinski/avante.nvim", -->
<!--   }, -->
<!--   config = function() -->
<!--     require("avante-cody").setup({ -->
<!--       -- your configuration -->
<!--     }) -->
<!--   end -->
<!-- } -->
<!-- ``` -->

</td>
</tr>
<tr>
<td>

[junegunn/vim-plug](https://github.com/junegunn/vim-plug)

</td>
<td>

** TODO **
<!-- ```vim -->
<!-- " TODO: confirm configuration for vim-plug  -->
<!-- Plug 'brewinski/avante.nvim' -->
<!-- Plug 'brewinski/avante-cody.nvim' -->
<!---->
<!-- " After plug#end(): -->
<!-- lua << EOF -->
<!--   require("avante-cody").setup({ -->
<!--     -- your configuration -->
<!--   }) -->
<!-- EOF -->
<!-- ``` -->

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

## 🤝 Using with avante.nvim

Once configured, you can use all avante.nvim features with the Sourcegraph Cody provider:
<img width="690" alt="image" src="https://github.com/user-attachments/assets/b336111f-60a0-4144-b6f8-7d4798bf48e0" />

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

## 📄 License

This project is licensed under MIT License - see the LICENSE file for details.
