[Useful forum post comment on zsh configuration](https://forum.cursor.com/t/guide-fix-cursor-agent-terminal-hangs-caused-by-zshrc/107260/31)

Technically, following z-shell semantics, .zshrc shouldn’t be sourced by Cursor because it’s intended for interactive shells, whereas Cursor is trying to use the shell in a non-interactive manner.

There are multiple initialization files you can use:

.zshenv: Move any common environment setup here for all shells, login or otherwise. This is sourced for all shells.
.zprofile: Move your user’s login setup here. E.g. any $PATH adjustments. This is sourced for all login shells and Cursor should source it.
.zshrc: Add the early return logic here from the above answer. “RC” = “Run Commands” — this file should be sourced only by interactive shells. Cursor should not source it but it does, so you need to force it not to load.
.zshlogin: Listed for the pedantic sake of completion, this gets sourced after the login process is complete, so if you care about specific timing, it’s an option. Typically, just use .zprofile though.
.zshlogout: Listed for the pedantic sake of completion, this gets sourced when you exit a login shell. I guess you could put a cleanup task here.
