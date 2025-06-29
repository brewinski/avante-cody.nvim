# Changelog

## [1.7.0](https://github.com/brewinski/avante-cody.nvim/compare/v1.6.0...v1.7.0) (2025-06-24)


### Features

* add environment variable and command support for endpoint configuration ([db4427f](https://github.com/brewinski/avante-cody.nvim/commit/db4427f30c17c657f82266e87512bdadf72e5c0a))

## [1.6.0](https://github.com/brewinski/avante-cody.nvim/compare/v1.5.1...v1.6.0) (2025-06-24)


### Features

* **event-debugger:** improved debugging tools to help review the i/o of the cody provider. ([e0c3cbf](https://github.com/brewinski/avante-cody.nvim/commit/e0c3cbf2c2c0ae93b4c947a3a5a5069e2e3840af))
* **prompt_cache:** implement prompt caching in provider. ([d4a716c](https://github.com/brewinski/avante-cody.nvim/commit/d4a716c27a10ae73c27a1e59c376782fdf915ec2))


### Bug Fixes

* **provider:** improve message parsing and cache control handling ([ae8652b](https://github.com/brewinski/avante-cody.nvim/commit/ae8652b280924ddf45149a0a5d20a82c700c2bea))
* **provider:** stop api errors by removing any messages with empty content. ([829eb65](https://github.com/brewinski/avante-cody.nvim/commit/829eb65cac1f0aa0ad05242d5299e15472894eda))
* remove redundant cacheEnable property and update tests ([50b8fb9](https://github.com/brewinski/avante-cody.nvim/commit/50b8fb97c3dd4235f826916a8dcb70cef886eab1))
* resolve operator precedence ambiguity in string concatenation ([8be976c](https://github.com/brewinski/avante-cody.nvim/commit/8be976c6b53dc16749a5de92f713b0b816462d7d))
* resolve string concatenation ambiguity and unused variable warnings ([765c1b6](https://github.com/brewinski/avante-cody.nvim/commit/765c1b60eba5f7365f551e3534a5f28cf1900c90))

## [1.5.1](https://github.com/brewinski/avante-cody.nvim/compare/v1.5.0...v1.5.1) (2025-06-16)


### Bug Fixes

* **cody:** transform_tool correctly handles objects sub objects and arrays. ([6589327](https://github.com/brewinski/avante-cody.nvim/commit/65893274c7cb021a4a5ff9e8bd275b83ed56a266))

## [1.5.0](https://github.com/brewinski/avante-cody.nvim/compare/v1.4.0...v1.5.0) (2025-06-16)


### Features

* avante-cody debug toggle user comman. allow users to toggle debug logging. ([eb48d3d](https://github.com/brewinski/avante-cody.nvim/commit/eb48d3d35bb2974a394db56697b9fab3b39dd9ce))
* avante-cody toggle logfile logging user command. ([8e39f20](https://github.com/brewinski/avante-cody.nvim/commit/8e39f20fefa20f83de160032d9bdf6a7d65aa098))
* print the latest inputs/output messages for a given provider. ([10fc4f8](https://github.com/brewinski/avante-cody.nvim/commit/10fc4f83f8058543173ec2660e2a4926a6b03a98))


### Bug Fixes

* remove unused avante-cody command. ([ff0701c](https://github.com/brewinski/avante-cody.nvim/commit/ff0701c13848874459f0510330dac7fb63b85881))
* sg api requires a tool use and an llm message to be provided together. Insert the last response from the assistant as the message to encourage explanation of tool use. ([11a76b4](https://github.com/brewinski/avante-cody.nvim/commit/11a76b4e4cec118be4aee8e6f3bca58e02572890))

## [1.4.0](https://github.com/brewinski/avante-cody.nvim/compare/v1.3.0...v1.4.0) (2025-06-12)


### Features

* update default model to claude-sonnet-4-latest ([08ccf5a](https://github.com/brewinski/avante-cody.nvim/commit/08ccf5a5ea17d425c59259a9c34fa7ee2b983db2)), closes [#22](https://github.com/brewinski/avante-cody.nvim/issues/22)

## [1.3.0](https://github.com/brewinski/avante-cody.nvim/compare/v1.2.1...v1.3.0) (2025-06-10)


### Features

* **agentic-mode:** add support for agentic mode and write_to_file tools ([43b70af](https://github.com/brewinski/avante-cody.nvim/commit/43b70af961a67f64a8d93cd2f3061a2b24e2a7b4))
* **cody-provider:** improve tool use functionality and type definitions ([3d93e65](https://github.com/brewinski/avante-cody.nvim/commit/3d93e657259735823db7d2f7339a5e23b3227389))
* **thinking:** add thinking support to sourcegraph cody provider. ([aa0c206](https://github.com/brewinski/avante-cody.nvim/commit/aa0c20602e963c7a8db2a7420989a3083bd90f92))


### Bug Fixes

* **cody-provider:** add missing error reason in parse_response ([465f1f7](https://github.com/brewinski/avante-cody.nvim/commit/465f1f76b07858925e98782bb79204767b7967a7))
* **cody-provider:** correct API request formatting and type annotations ([7a1277b](https://github.com/brewinski/avante-cody.nvim/commit/7a1277be018a09d944dcbd171f1653192e796a76))
* **provider:** properly handle tool call and tool result messages ([04de9cc](https://github.com/brewinski/avante-cody.nvim/commit/04de9cc946a606f901dd856e81081bf7abf5ac2c))
* **provider:** remove empty test file. ([92dfca6](https://github.com/brewinski/avante-cody.nvim/commit/92dfca6666ac1712af1713f3df61e672e38ca6c3))
* **provider:** resolve compatibility issue with avante plugin interface ([fd64689](https://github.com/brewinski/avante-cody.nvim/commit/fd64689cde2c36f797bb47e40f312790b52f7d9d))
* **support:** support latest config/provider refactors start-commit: e9ab2ca2fd7b8df4bed0963f490f59d8ed119ecb end-commit:0cce9558169d20daaee6894ee9ff90932314d777 ([eceb64c](https://github.com/brewinski/avante-cody.nvim/commit/eceb64cfd1e931a733728b61b6cb91b2c619810a)), closes [#11](https://github.com/brewinski/avante-cody.nvim/issues/11)
* **thinking:** calling tools with thinking enabled resulted in an error message. Work around introduced for thinking models to avoid interlated thinking requirement. ([2437b13](https://github.com/brewinski/avante-cody.nvim/commit/2437b13baf0980a86b353d6d6abb6401818adaa2))

## [1.2.1](https://github.com/brewinski/avante-cody.nvim/compare/v1.2.0...v1.2.1) (2025-06-10)


### Bug Fixes

* **thinking:** calling tools with thinking enabled resulted in an error message. Work around introduced for thinking models to avoid interlated thinking requirement. ([2437b13](https://github.com/brewinski/avante-cody.nvim/commit/2437b13baf0980a86b353d6d6abb6401818adaa2))

## [1.2.0](https://github.com/brewinski/avante-cody.nvim/compare/v1.1.3...v1.2.0) (2025-06-10)


### Features

* **thinking:** add thinking support to sourcegraph cody provider. ([aa0c206](https://github.com/brewinski/avante-cody.nvim/commit/aa0c20602e963c7a8db2a7420989a3083bd90f92))

## [1.1.3](https://github.com/brewinski/avante-cody.nvim/compare/v1.1.2...v1.1.3) (2025-06-09)


### Bug Fixes

* **support:** support latest config/provider refactors start-commit: e9ab2ca2fd7b8df4bed0963f490f59d8ed119ecb end-commit:0cce9558169d20daaee6894ee9ff90932314d777 ([eceb64c](https://github.com/brewinski/avante-cody.nvim/commit/eceb64cfd1e931a733728b61b6cb91b2c619810a)), closes [#11](https://github.com/brewinski/avante-cody.nvim/issues/11)

## [1.1.2](https://github.com/brewinski/avante-cody.nvim/compare/v1.1.1...v1.1.2) (2025-05-02)


### Bug Fixes

* **provider:** resolve compatibility issue with avante plugin interface ([fd64689](https://github.com/brewinski/avante-cody.nvim/commit/fd64689cde2c36f797bb47e40f312790b52f7d9d))

## [1.1.1](https://github.com/brewinski/avante-cody.nvim/compare/v1.1.0...v1.1.1) (2025-05-01)


### Bug Fixes

* **cody-provider:** add missing error reason in parse_response ([465f1f7](https://github.com/brewinski/avante-cody.nvim/commit/465f1f76b07858925e98782bb79204767b7967a7))
* **provider:** properly handle tool call and tool result messages ([04de9cc](https://github.com/brewinski/avante-cody.nvim/commit/04de9cc946a606f901dd856e81081bf7abf5ac2c))

## [1.1.0](https://github.com/brewinski/avante-cody.nvim/compare/v1.0.1...v1.1.0) (2025-04-30)


### Features

* **cody-provider:** improve tool use functionality and type definitions ([3d93e65](https://github.com/brewinski/avante-cody.nvim/commit/3d93e657259735823db7d2f7339a5e23b3227389))

## [1.0.1](https://github.com/brewinski/avante-cody.nvim/compare/v1.0.0...v1.0.1) (2025-04-30)


### Bug Fixes

* **cody-provider:** correct API request formatting and type annotations ([7a1277b](https://github.com/brewinski/avante-cody.nvim/commit/7a1277be018a09d944dcbd171f1653192e796a76))

## 1.0.0 (2025-04-29)


### Bug Fixes

* **provider:** remove empty test file. ([92dfca6](https://github.com/brewinski/avante-cody.nvim/commit/92dfca6666ac1712af1713f3df61e672e38ca6c3))

## [3.0.0](https://github.com/shortcuts/neovim-plugin-boilerplate/compare/v2.2.0...v3.0.0) (2024-09-25)


### ⚠ BREAKING CHANGES

* renew template ([#22](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/22))

### Features

* renew template ([#22](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/22)) ([ca72698](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/ca726988e6711508ada1ee0e554824827d00e3be))

## [2.2.0](https://github.com/shortcuts/neovim-plugin-boilerplate/compare/v2.1.0...v2.2.0) (2024-03-18)


### Features

* **ci:** bump stylua ([#18](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/18)) ([d97ea98](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/d97ea98e85fb55a57e2ff9618982261e7d1a33d0))

## [2.1.0](https://github.com/shortcuts/neovim-plugin-boilerplate/compare/v2.0.0...v2.1.0) (2024-03-16)


### Features

* **ci:** add luals checks on CI ([#16](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/16)) ([2d0ecc4](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/2d0ecc406f7b8a2c4fab5a7ed83967f6a35cbd5d))

## [2.0.0](https://github.com/shortcuts/neovim-plugin-boilerplate/compare/v1.1.0...v2.0.0) (2024-03-15)


### ⚠ BREAKING CHANGES

* improve template helpers and state manager ([#14](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/14))

### Features

* improve template helpers and state manager ([#14](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/14)) ([9cc87ad](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/9cc87add9fffd7e54b9f37573ed105f2234c7ccd))

## [1.1.0](https://github.com/shortcuts/neovim-plugin-boilerplate/compare/v1.0.0...v1.1.0) (2023-03-26)


### Features

* make setup.sh more reliable ([6c2f360](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/6c2f360be9acd1c747f9cce112c6a0205e76532c))
* template cleanup and improvements ([#11](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/11)) ([af2fcb0](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/af2fcb0ffcac54eb9e4092bb860c22e29d2579dc))


### Bug Fixes

* CI diff documentation ([#9](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/9)) ([c4b9836](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/c4b98367f82a6fe47d7268ac7a3887643831eac8))

## 1.0.0 (2023-01-05)


### Features

* add doc generation check to CI ([#2](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/2)) ([15d4d14](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/15d4d1462f0bf99349ddd626d8f1a4b1b95f8a14))
* add release script ([144c732](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/144c732b598c01c52f81d89f085ff5a5aefe1a1f))
* add setup script ([#1](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/1)) ([fbffb71](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/fbffb71deea4fafb4e76c5901fa263b155ab8e94))
* **cd:** add release action ([#4](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/4)) ([85cb257](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/85cb257bfe0c2770364541044cfc478cecf58a2a))
* **cd:** remove homemade release script ([#6](https://github.com/shortcuts/neovim-plugin-boilerplate/issues/6)) ([316de3d](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/316de3d10be0f704bdfecde3d889efe9c2e57570))


### Bug Fixes

* easier replace ([0d686ea](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/0d686eab4a45c4437bfaa3fdf8365de305587dff))
* missing README.md mention ([97b16e0](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/97b16e028283cc7a47421da518cd51c3db206427))
* missing steps in README.md ([6ac7c6f](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/6ac7c6fab61fd9af968ad476161b06406692ca87))
* test helpers ([d65dd73](https://github.com/shortcuts/neovim-plugin-boilerplate/commit/d65dd73119ec466bdd99d9833f27c4f6a936fe1e))
