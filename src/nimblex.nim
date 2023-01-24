##
## This simple tool fetches and runs command-line tools from nimble.directory
import std/os
import std/osproc
import std/terminal
import std/sequtils
import std/json

# Get binary name from an installed package name
proc binForPackage(pkgName: string): string =
    try:
        let info = parseJson(execProcess(@["nimble", "dump", pkgName, "--json"].quoteShellCommand()))
        return info{"bin"}{0}.getStr()
    except:
        return ""



when isMainModule:

    # Get input from command line
    var args = commandLineParams()
    if args.len == 0:
        stdout.styledWriteLine(fgRed, "Error: ", fgDefault, "No package name provided.")
        quit(1)

    # First argument is always the package or binary name
    let pkgName = args[0]

    # Check if this app already exists, if so just run it
    if findExe(pkgName) != "":
        quit(execCmd(args.quoteShellCommand()))

    # It doesn't, so maybe it's a package name and the binary name for this package is different? Attempt to read the `bin` field if so
    let binName = binForPackage(pkgName)
    if findExe(binName) != "":
        var newArgs = args
        newArgs.delete(0)
        newArgs.insert(binName, 0)
        quit(execCmd(newArgs.quoteShellCommand()))

    # Still can't find it, it probably isn't installed... Attempt to install it via Nimble
    let result = execCmdEx(@["nimble", "install", "-y", pkgName].quoteShellCommand())
    if result.exitCode != 0:

        # Failed to install!
        echo result.output
        quit(1)

    # Now that it's installed, attempt to find and run the EXE again
    if findExe(pkgName) != "":
        quit(execCmd(args.quoteShellCommand()))

    # Still can't find the EXE! Again maybe the package name is not the same as the binary name, so attempt to read the `bin` field
    let binName2 = binForPackage(pkgName)
    if findExe(binName2) != "":
        var newArgs = args
        newArgs.delete(0)
        newArgs.insert(binName2, 0)
        quit(execCmd(newArgs.quoteShellCommand()))

    # This binary just doesn't exist... Fail here
    stdout.styledWriteLine(fgRed, "Error: ", fgDefault, "Unable to find the binary for '" & pkgName & "'")
    quit(1)