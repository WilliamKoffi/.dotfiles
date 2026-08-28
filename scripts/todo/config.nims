# Keep every build artifact out of ~/.dotfiles -- this repository is public
# and must never carry a compiled binary.
#
# Nim already puts its nimcache under $XDG_CACHE_HOME, but the *binary*
# would default to sitting next to the source. Redirect it so that even a
# bare `nim c src/todo.nim` run by hand cannot drop an executable into the
# repository. scripts/todo/.gitignore is the second line of defence.

import std/os

switch("outdir", getEnv("TODO_BUILD_DIR",
                        getEnv("XDG_CACHE_HOME", getHomeDir() / ".cache") /
                        "todo-build"))
