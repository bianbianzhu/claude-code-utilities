# Claude Code LSP Setup Guide

## What is LSP?

**LSP (Language Server Protocol)** is a standard that lets code editors communicate with language-specific tools. Instead of each editor implementing its own TypeScript analyzer, Python type checker, etc., they all talk to a shared "language server" that provides:

- **Go to Definition** - Jump to where a function/class is defined
- **Find References** - Find all places that use a symbol
- **Hover Info** - See type information and documentation
- **Symbol Search** - Find functions/classes by name

### What LSP Does NOT Do in Claude Code

LSP in Claude Code is for **code navigation**, not type checking:

| Feature                                   | How It Works                                      |
| ----------------------------------------- | ------------------------------------------------- |
| "Where is `UserService` defined?"         | LSP tool (on-demand)                              |
| "Find all usages of `handleRequest`"      | LSP tool (on-demand)                              |
| "What type errors exist in this project?" | `npm run typecheck` or `pyright` (manual command) |

Type errors/diagnostics are shown **passively after you edit a file**, not on-demand for the whole project.

---

## Quick Setup (Recommended)

### Step 1: Update Claude Code

You need version **2.0.74** or higher:

```bash
claude --version    # Check current version
claude update       # Update if needed
```

### Step 2: Install Language Server Binaries

Claude Code connects to language servers but doesn't bundle them. Install the ones you need:

**TypeScript/JavaScript:**

```bash
npm install -g typescript-language-server typescript
```

**Python:**

```bash
pip install pyright
# or: npm install -g pyright
```

**Go:**

```bash
go install golang.org/x/tools/gopls@latest
```

Then add Go's bin directory to your PATH. Add this to `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/go/bin:$PATH"
```

**Swift (macOS):**
Already installed at `/usr/bin/sourcekit-lsp`

**Rust:**

```bash
rustup component add rust-analyzer
```

### Step 3: Install LSP Plugins from Marketplace

1. Start Claude Code:

   ```bash
   claude
   ```

2. Open the plugin menu:

   ```
   /plugin
   ```

3. Go to the **Discover** tab (use arrow keys or tab)

4. Search for "lsp" and install the plugins you need:

   - `typescript-lsp` - TypeScript/JavaScript
   - `pyright-lsp` - Python
   - `gopls-lsp` - Go
   - `swift-lsp` - Swift
   - `rust-analyzer-lsp` - Rust
   - `clangd-lsp` - C/C++

5. **Enable the plugins**: Go to the **Installed** tab, navigate to each plugin, and press **Space** to toggle it on (should show ◉ not ◯)

6. **Restart Claude Code** - LSP servers only start on fresh sessions

---

## Verifying Your Setup

### Check Installed Plugins

Run `/plugin` and go to the **Installed** tab. You should see:

```
claude-plugins-official
  ◉ pyright-lsp user, v1.0.0      <- ◉ means enabled
  ◉ typescript-lsp user, v1.0.0
  ◉ gopls-lsp user, v1.0.0
  ◯ swift-lsp user, v1.0.0        <- ◯ means disabled
```

Press **Space** on any ◯ to enable it.

### Check Language Server Binaries

```bash
which typescript-language-server   # Should show a path
which pyright-langserver           # Should show a path
which gopls                        # Should show a path (after PATH update)
which sourcekit-lsp                # macOS: /usr/bin/sourcekit-lsp
```

### Test LSP is Working

In a TypeScript/Python/Go project, ask Claude:

```
Using the LSP tool, find where [ClassName] is defined
```

You should see Claude use the `LSP` tool:

```
⏺ LSP(operation: "goToDefinition", symbol: "ClassName", in: "path/to/file.ts")
  ⎿  Found 1 definition
     Defined in src/models/class.ts:42:1
```

If Claude uses `grep` or `Search` instead, the LSP might not be enabled or the server isn't running.

---

## Available LSP Operations

| Operation            | What It Does                      | Example Query                          |
| -------------------- | --------------------------------- | -------------------------------------- |
| `goToDefinition`     | Find where a symbol is defined    | "Where is UserService defined?"        |
| `findReferences`     | Find all usages of a symbol       | "Find all usages of handleRequest"     |
| `hover`              | Get type info and documentation   | "What type is this variable?"          |
| `documentSymbol`     | List all symbols in a file        | "What functions are in this file?"     |
| `workspaceSymbol`    | Search for symbols across project | "Find any class named Config"          |
| `goToImplementation` | Find implementations of interface | "Where is this interface implemented?" |

---

## Troubleshooting

### Plugin Installed but Not Working

1. **Check if enabled**: In `/plugin` → Installed tab, make sure the plugin shows ◉ (not ◯)
2. **Restart Claude Code**: LSP servers only start on new sessions
3. **Check binary is installed**: Run `which <binary-name>` to verify

### "Executable not found in $PATH"

Check the `/plugin` → **Errors** tab. This means the plugin is installed but the language server binary isn't in your PATH.

**Fix**: Install the binary (see Step 2) and ensure it's in your PATH.

### LSP Not Being Used

If Claude uses `grep` or runs `npm run typecheck` instead of the LSP tool:

1. The LSP tool is for **code navigation** (go to definition, find references)
2. For **type checking**, Claude will correctly run the type checker manually
3. Try asking: "Using the LSP tool, find where X is defined"

### Enable Debug Logs

```bash
claude --enable-lsp-logging
```

Logs are written to `~/.claude/debug/`. Look for entries like:

```
[DEBUG] LSP server plugin:typescript-lsp:typescript initialized
```

### Check Debug Logs

```bash
# View latest session's LSP activity
grep -i "lsp" ~/.claude/debug/latest | head -30
```

---

## Advanced: Custom LSP Plugin

For languages not in the marketplace, create your own plugin.

### Plugin Structure

```
my-ruby-lsp/
├── .claude-plugin/
│   └── plugin.json
└── .lsp.json
```

### plugin.json

```json
{
  "name": "my-ruby-lsp",
  "version": "1.0.0",
  "description": "Ruby language server support",
  "lspServers": "./.lsp.json"
}
```

### .lsp.json

```json
{
  "ruby": {
    "command": "solargraph",
    "args": ["stdio"],
    "extensionToLanguage": {
      ".rb": "ruby",
      ".rake": "ruby"
    }
  }
}
```

### Install Custom Plugin

```bash
# For current session only (testing)
claude --plugin-dir ./my-ruby-lsp

# Install permanently
claude plugin install ./my-ruby-lsp --scope user
```

---

## Available Official LSP Plugins

| Plugin              | Language              | Binary Required              |
| ------------------- | --------------------- | ---------------------------- |
| `typescript-lsp`    | TypeScript/JavaScript | `typescript-language-server` |
| `pyright-lsp`       | Python                | `pyright-langserver`         |
| `gopls-lsp`         | Go                    | `gopls`                      |
| `swift-lsp`         | Swift                 | `sourcekit-lsp`              |
| `rust-analyzer-lsp` | Rust                  | `rust-analyzer`              |
| `clangd-lsp`        | C/C++                 | `clangd`                     |
| `jdtls-lsp`         | Java                  | `jdtls`                      |
| `lua-lsp`           | Lua                   | `lua-language-server`        |
| `php-lsp`           | PHP                   | `intelephense`               |
| `csharp-lsp`        | C#                    | `csharp-ls`                  |

Install with:

```bash
claude plugin install <plugin-name>@claude-plugins-official --scope user
```

---

## Summary

1. **Install language server binaries** (npm/pip/go install)
2. **Install LSP plugins** from `/plugin` → Discover
3. **Enable plugins** in `/plugin` → Installed (press Space)
4. **Restart Claude Code**
5. **Test** with "Using the LSP tool, find where X is defined"

LSP gives Claude IDE-like code navigation. For project-wide type checking, Claude will still run `tsc`, `pyright`, etc. as needed.
