# NimbleX

![](https://img.shields.io/badge/status-beta-orange)

Like [npx](https://www.npmjs.com/package/npx) for Nim, this tool lets you run a package directly from the [Nimble Directory](https://nimble.directory). Packages will be installed if not found. Examples:

```bash
# Start a static HTTP server
nimblex staticserver
```

```bash
# Start the Moe editor
nimblex moe
```

```bash
# Use c2nim
nimblex c2nim --help
```

This tool will first search for the binary/package name on the PATH, so it's safe to just prefix any command with `nimblex` even if they don't come from Nim:

```bash
nimblex echo "Hi" > file.txt
nimblex ifconfig
nimblex pwd
```