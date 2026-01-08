# important that volta is at the beginning of the path so it resolves via its shims _before_ the underlying system binaries
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"
