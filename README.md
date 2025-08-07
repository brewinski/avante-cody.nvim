<p align="center">
  <h1 align="center">avante-cody.nvim</h2>
</p>

<p align="center">
  Sourcegraph Cody provider for avante.nvim
</p>

<p align="center">
  <img alt="GitHub release (latest by date)" src="https://img.shields.io/github/v/release/brewinski/avante-cody.nvim" />
  <img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/brewinski/avante-cody.nvim/main.yml?branch=main" />
  <img alt="Neovim version" src="https://img.shields.io/badge/neovim-0.8%2B-green" />
  <img alt="License" src="https://img.shields.io/github/license/brewinski/avante-cody.nvim" />
</p>

## 📋 Table of Contents

- [Features](#⚡️-features)
- [Installation](#📋-installation)
- [Getting Started](#☄-getting-started)
- [Configuration](#⚙-configuration)
- [Authentication](#🔒-authentication-methods)
- [Usage with avante.nvim](#🤝-using-with-avantenvim)
- [Commands](#📝-commands)
- [Debugging & Troubleshooting](#🐛-debugging--troubleshooting)
- [Development](#🛠-development)
- [Contributing](#⌨-contributing)
- [FAQ](#❓-faq)
- [License](#📄-license)

## ⚡️ Features

- Integration with Sourcegraph Cody in [avante.nvim](https://github.com/brewinski/avante.nvim)
- Support Sourcegraph Cloud Enterprise  
- Experimental / Limited support for free, pro and enterprise starter accounts

> ⚡ **Account Ban Warning**: Using Cody Free or Pro accounts outside of Sourcegraph's official IDE may result in your account being flagged for spam and potentially banned. This is due to Sourcegraph's Acceptable Use Policy. Enterprise accounts are not affected by this limitation however there are no garantees. If you're using a Free or Pro account, please be aware of this risk.


## 📋 Installation

### Prerequisites

Before installing avante-cody.nvim, ensure you have:

1. **[Neovim](https://neovim.io/) 0.8.0 or later**
   ```bash
   nvim --version
   ```

2. **[avante.nvim](https://github.com/brewinski/avante.nvim) installed and configured**
   - This plugin is a provider for avante.nvim and requires it to function
   - Follow the [avante.nvim installation guide](https://github.com/yetone/avante.nvim#installation) first

3. **A Sourcegraph account with Cody access**
   - **Recommended**: Sourcegraph Cloud Enterprise account (no restrictions)
   - **Limited support**: Free, Pro, and Enterprise starter accounts (see warning below)

### Installation Methods

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
3. **Generate new token** with appropriate scopes:
   - For enterprise: Select all available scopes
   - For free/pro: Select basic read scopes
4. Set your environment variable: 
   ```bash
   export SRC_ACCESS_TOKEN="sgp_your_token_here"
   ```
   Add this to your shell profile (`.bashrc`, `.zshrc`, etc.) for persistence

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

**Step 4: Configure avante.nvim to use Cody**
Make sure your avante.nvim configuration includes:
```lua
require("avante").setup({
  provider = "avante-cody", -- IMPORTANT: This tells avante to use Cody
  -- ... other avante options
})
```

**Step 5: Test it works**
1. Restart Neovim completely
2. Open a code file in your project
3. Trigger avante (`:AvanteChat` or your configured keybinding)
4. You should see "avante-cody" as the active provider in the UI
5. Ask a simple question like "Explain this function" to verify it's working

**Step 6: Verify everything is working**
```vim
" Check that providers are loaded
:AvanteCodyListProviders

" Enable debug mode if you encounter issues
:AvanteCodyDebugToggle
```

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

### Configuration Examples

#### Enterprise Setup
```lua
require("avante-cody").setup({
  debug = false,
  providers = {
    ['cody-enterprise'] = {
      endpoint = "https://my-company.sourcegraphcloud.com",
      api_key_name = "SRC_ACCESS_TOKEN", 
      model = "anthropic::2024-10-22::claude-sonnet-4-latest",
      max_output_tokens = 8000, -- Higher limit for enterprise
      temperature = 0.1, -- Slightly more creative
    }
  }
})
```

#### Multiple Provider Setup
```lua
require("avante-cody").setup({
  providers = {
    ['cody-main'] = {
      endpoint = "https://sourcegraph.com",
      api_key_name = "SRC_ACCESS_TOKEN",
      model = "anthropic::2024-10-22::claude-sonnet-4-latest",
    },
    ['cody-fast'] = {
      endpoint = "https://sourcegraph.com", 
      api_key_name = "SRC_ACCESS_TOKEN",
      model = "anthropic::2024-06-20::claude-3-haiku-20240307", -- Faster model
      max_output_tokens = 2000, -- Shorter responses
    }
  }
})
```

#### Development/Debug Setup
```lua
require("avante-cody").setup({
  debug = true,
  logfile = true,
  providers = {
    ['avante-cody'] = {
      endpoint = "https://sourcegraph.com",
      api_key_name = "SRC_ACCESS_TOKEN",
      timeout = 60000, -- Longer timeout for debugging
      allow_insecure = true, -- Only for testing
    }
  }
})
```

### Advanced Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `use_xml_format` | boolean | `true` | Use XML formatting for requests |
| `disable_tools` | boolean | `false` | Disable tool usage capabilities |
| `context_window` | integer | `200000` | Maximum context window size |
| `max_tokens` | integer | `30000` | Maximum tokens for requests |
| `max_output_tokens` | integer | `4000` | Maximum tokens in response |
| `stream` | boolean | `true` | Enable streaming responses |
| `topK` | integer | `-1` | Top-K sampling (-1 = disabled) |
| `topP` | number | `-1` | Top-P sampling (-1 = disabled) |
| `temperature` | number | `0` | Response creativity (0-1) |
| `timeout` | integer | `30000` | Request timeout in milliseconds |
| `allow_insecure` | boolean | `false` | Allow insecure connections |
| `proxy` | string | `nil` | HTTP proxy URL |

## 📝 Commands

avante-cody.nvim provides several user commands for debugging and management:

### Debug Commands

- **`:AvanteCodyDebugToggle`** - Toggle debug logging on/off
  ```vim
  :AvanteCodyDebugToggle
  ```

- **`:AvanteCodyLogfileToggle`** - Toggle file logging on/off
  ```vim
  :AvanteCodyLogfileToggle
  ```

### Provider Management

- **`:AvanteCodyListProviders`** - List all available provider names
  ```vim
  :AvanteCodyListProviders
  ```

### Debugging Tools

- **`:AvanteCodyPrintLastParseCurlArgs [provider] [input|output]`** - Print curl arguments for debugging
  ```vim
  :AvanteCodyPrintLastParseCurlArgs avante-cody input
  :AvanteCodyPrintLastParseCurlArgs avante-cody output
  ```

- **`:AvanteCodyPrintParseResponse [provider]`** - Print API response for debugging
  ```vim
  :AvanteCodyPrintParseResponse avante-cody
  ```

> **Note**: Debug commands are essential for troubleshooting API issues. The default provider name is "avante-cody" if not specified.

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

## 🐛 Debugging & Troubleshooting

### Enable Debug Mode

To troubleshoot issues, enable debug logging:

```lua
require("avante-cody").setup({
  debug = true, -- Enable debug logging
  logfile = true, -- Enable file logging
  -- ... other config
})
```

Or toggle it at runtime:
```vim
:AvanteCodyDebugToggle
:AvanteCodyLogfileToggle
```

### Common Issues

#### Authentication Errors
- **Issue**: "Unauthorized" or "Invalid token" errors
- **Solution**: 
  1. Verify your access token is valid: `echo $SRC_ACCESS_TOKEN`
  2. Check token has correct scopes in Sourcegraph settings
  3. For enterprise instances, ensure endpoint URL is correct

#### Rate Limiting
- **Issue**: "Rate limit exceeded" errors
- **Solution**: 
  - This plugin automatically reduces API calls by disabling chat title generation
  - Consider upgrading your Sourcegraph subscription
  - Use `:AvanteCodyPrintLastParseCurlArgs` to monitor request frequency

#### Connection Issues
- **Issue**: Timeout or connection errors
- **Solution**:
  1. Check network connectivity to Sourcegraph
  2. For self-hosted instances, verify SSL certificates
  3. Try `allow_insecure = true` for testing (not recommended for production)
  4. Increase timeout value if needed

#### Provider Not Found
- **Issue**: "Provider 'avante-cody' not found" errors
- **Solution**:
  1. Ensure avante.nvim is configured with `provider = "avante-cody"`
  2. Check that avante-cody.nvim is loaded after avante.nvim
  3. Use `:AvanteCodyListProviders` to see available providers

### Debug Commands

Use these commands to investigate issues:

```vim
" Check if providers are loaded
:AvanteCodyListProviders

" Inspect last API request/response
:AvanteCodyPrintLastParseCurlArgs avante-cody input
:AvanteCodyPrintLastParseCurlArgs avante-cody output

" View parsed response data
:AvanteCodyPrintParseResponse avante-cody
```

### Performance Optimization

The plugin includes several performance optimizations:

1. **Rate Limit Protection**: Automatically disables expensive API calls for chat titles and memory summarization
2. **Streaming**: Uses streaming responses to provide faster feedback
3. **Prompt Caching**: Implements Claude's prompt caching for repeated requests

### Getting Help

If you're still experiencing issues:

1. Enable debug mode and collect logs
2. Use debug commands to capture API request/response data
3. Check the [GitHub Issues](https://github.com/brewinski/avante-cody.nvim/issues) for similar problems
4. Provide your configuration (sanitized) when reporting issues

## 🛠 Development

### Prerequisites for Development

- [Neovim](https://neovim.io/) (0.8.0 or later)
- [Git](https://git-scm.com/)
- [Make](https://www.gnu.org/software/make/)
- [stylua](https://github.com/JohnnyMorganz/StyLua) (for code formatting)
- [luacheck](https://github.com/mpeterv/luacheck) (for linting)

### Setting Up Development Environment

1. **Clone the repository**:
   ```bash
   git clone https://github.com/brewinski/avante-cody.nvim.git
   cd avante-cody.nvim
   ```

2. **Install dependencies**:
   ```bash
   make deps
   ```
   This installs `mini.nvim`, `avante.nvim`, and `plenary.nvim` in the `deps/` directory.

3. **Run tests**:
   ```bash
   make test
   ```

4. **Run linting**:
   ```bash
   make lint
   ```

5. **Generate documentation**:
   ```bash
   make documentation
   ```

### Development Commands

The `Makefile` provides several helpful commands:

- `make test` - Run all tests
- `make test-nightly` - Run tests on Neovim nightly (requires [bob](https://github.com/MordechaiHadad/bob))
- `make test-0.8.3` - Run tests on Neovim 0.8.3
- `make lint` - Format code with stylua and run luacheck
- `make documentation` - Generate help documentation
- `make luals` - Run lua-language-server type checking

### Project Structure

```
lua/avante-cody/
├── init.lua           # Main module entry point
├── config.lua         # Configuration management
├── main.lua           # Provider registration
├── cody-provider.lua  # Core Cody API provider implementation
├── sg-api.lua         # Sourcegraph API helpers (experimental)
├── overides.lua       # Performance optimizations
├── event-debugger.lua # Debugging utilities
├── state.lua          # State management
└── util/
    └── log.lua        # Logging utilities

plugin/
└── avante-cody.lua    # User commands and plugin initialization

doc/
├── avante-cody.txt    # Generated help documentation
└── tags               # Help tags

tests/
├── test_cody-provider.lua  # Provider tests
├── test_API.lua            # API tests
└── helpers.lua             # Test utilities
```

### Testing

The project uses [mini.test](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-test.md) for testing:

- Tests are in the `tests/` directory
- Run `make test` to execute all tests
- Use `make test-ci` for CI-style testing with dependency installation

### Code Style

- **Formatting**: Use [stylua](https://github.com/JohnnyMorganz/StyLua) with the provided `stylua.toml` config
- **Linting**: Use [luacheck](https://github.com/mpeterv/luacheck) with the provided `.luacheckrc` config
- **Type Checking**: Use [lua-language-server](https://github.com/LuaLS/lua-language-server) with `.luarc.json` config

### Adding New Features

1. **Write tests first**: Add tests in `tests/` directory
2. **Implement feature**: Add code in appropriate `lua/avante-cody/` module
3. **Update documentation**: Run `make documentation` to regenerate help docs
4. **Test thoroughly**: Run full test suite and manual testing
5. **Update CHANGELOG.md**: Document your changes

### Debugging During Development

Use the event debugger for development debugging:

```lua
-- Enable debug mode in your test config
require("avante-cody").setup({
  debug = true,
  logfile = true,
})

-- Use debug commands
:AvanteCodyPrintLastParseCurlArgs
:AvanteCodyPrintParseResponse
```

## ⌨ Contributing

PRs and issues are always welcome. Make sure to provide as much context as possible when opening one.

### Before Contributing

1. Read the [Development](#🛠-development) section
2. Check existing [issues](https://github.com/brewinski/avante-cody.nvim/issues) and [PRs](https://github.com/brewinski/avante-cody.nvim/pulls)
3. Run tests locally: `make test`
4. Follow the code style guidelines

### Pull Request Process

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Make your changes and add tests
4. Ensure all tests pass: `make test`
5. Run linting: `make lint`
6. Update documentation if needed: `make documentation`
7. Commit with clear messages
8. Push and create a Pull Request

## ❓ FAQ

### General Questions

**Q: What's the difference between Cody Free, Pro, and Enterprise?**
A: 
- **Free/Pro**: Limited API access, risk of account suspension for non-IDE usage
- **Enterprise**: Full API access, no restrictions, recommended for this plugin

**Q: Can I use this with self-hosted Sourcegraph?**
A: Yes! Configure the `endpoint` to point to your Sourcegraph instance:
```lua
['avante-cody'] = {
  endpoint = "https://my-company.sourcegraph.com",
}
```

**Q: Which models are available?**
A: Depends on your Sourcegraph subscription. Common models include:
- `anthropic::2024-10-22::claude-sonnet-4-latest` (Claude 3.5 Sonnet)
- `anthropic::2024-06-20::claude-3-haiku-20240307` (Claude 3 Haiku)

### Installation Issues

**Q: "avante-cody provider not found" error**
A: Ensure:
1. avante.nvim is configured with `provider = "avante-cody"`
2. avante-cody.nvim is loaded as a dependency
3. Both plugins are properly installed

**Q: Authentication not working**
A: 
1. Check your token: `echo $SRC_ACCESS_TOKEN`
2. Verify token permissions in Sourcegraph settings
3. For enterprise, ensure you're using the correct endpoint

### Performance Issues

**Q: Responses are slow**
A: 
1. Check your network connection to Sourcegraph
2. Try increasing the `timeout` value
3. Ensure you're using a fast model like Claude 3.5 Sonnet

**Q: Too many API requests**
A: The plugin automatically reduces API calls, but you can:
1. Use debug mode to monitor requests
2. Consider rate limits of your subscription
3. Avoid rapid-fire requests

### Advanced Usage

**Q: Can I use multiple Cody providers?**
A: Yes, configure multiple providers with different names:
```lua
providers = {
  ['cody-enterprise'] = { endpoint = "https://enterprise.com" },
  ['cody-cloud'] = { endpoint = "https://sourcegraph.com" },
}
```

**Q: How do I customize the AI behavior?**
A: Adjust these settings:
- `temperature`: Creativity level (0-1)
- `max_output_tokens`: Response length limit
- `model`: Choose different AI models

**Q: Can I use this without avante.nvim?**
A: No, this plugin is specifically designed as an avante.nvim provider and requires avante.nvim to function.

## 📄 License

This project is licensed under MIT License - see the LICENSE file for details.
