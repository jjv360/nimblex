##
## This simple tool fetches and runs command-line tools from nimble.directory
import std/os
import std/osproc
import std/terminal
import std/json
import std/strutils

# Get binary name from an installed package name
proc binForPackage(pkgName: string): string =
    try:

        # Get binary name
        let info = parseJson(execProcess(@["nimble", "dump", pkgName, "--json"].quoteShellCommand()))
        var binName = info{"bin"}{0}.getStr()

        # Remove .exe extension
        if binName.endsWith(".exe"):
            binName = binName.substr(0, binName.len - 5)

        # Done
        return binName

    except CatchableError:
        return ""


# Run command and exit
proc runAndExitIfPossible(binName: string, args: seq[string]) =

    # Stop if binName is empty
    if binName == "":
        return

    # Find path to EXE
    let exePath = findExe(binName)
    if exePath == "":
        return

    # Prepare args
    var newArgs = args
    newArgs.insert(exePath, 0)

    # Run it and return the exit code
    let exitCode = execCmd(newArgs.quoteShellCommand())
    quit(exitCode)


when isMainModule:

    # Get input from command line
    var args = commandLineParams()

    # Get our flags
    var verbose = false
    while args.len > 0:
        if args[0] == "--verbose":
            verbose = true
            args.delete(0)
        elif args[0].startsWith("--"):
            stdout.styledWriteLine(fgRed, "Error: ", resetStyle, "Unknown option: " & args[0])
            quit(1)
        else:
            break

    # Check arg length
    if args.len == 0:
        stdout.styledWriteLine(fgRed, "Error: ", resetStyle, "No package name provided.")
        quit(1)

    # First argument is always the package or binary name
    let pkgName = args[0]
    args.delete(0)
    if verbose:
        stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Package name: ", pkgName)

    # Check if this app already exists, if so just run it
    if verbose: stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Attempting to run ", pkgName)
    runAndExitIfPossible(pkgName, args)

    # It doesn't, so maybe it's a package name and the binary name for this package is different? Attempt to read the `bin` field if so
    var binName = binForPackage(pkgName)
    if verbose: stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Attempting to run ", binName)
    runAndExitIfPossible(binName, args)

    # Still can't find it, it probably isn't installed... Attempt to install it via Nimble
    if verbose: stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Attempting to install ", pkgName)
    let result = execCmdEx(@["nimble", "install", "-y", pkgName].quoteShellCommand())
    if result.exitCode != 0:

        # Failed to install!
        echo result.output
        quit(result.exitCode)

    # Now that it's installed, attempt to find and run the EXE again
    if verbose: stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Attempting to run ", pkgName)
    runAndExitIfPossible(pkgName, args)
    

    # Still can't find the EXE! Again maybe the package name is not the same as the binary name, so attempt to read the `bin` field
    binName = binForPackage(pkgName)
    if verbose: stdout.styledWriteLine(fgBlue, "> ", resetStyle, "Attempting to run ", binName)
    runAndExitIfPossible(binName, args)

    # This binary just doesn't exist... Fail here
    stdout.styledWriteLine(fgRed, "Error: ", resetStyle, "Unable to find the binary for '" & pkgName & "'")
    quit(1)