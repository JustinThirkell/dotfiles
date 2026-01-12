# https://cp.slack.com/archives/C01C0A5FDB4/p1722377791183649?thread_ts=1710826453.643409&cid=C01C0A5FDB4
# ==> jpeg
# jpeg is keg-only, which means it was not symlinked into /opt/homebrew,
# because it conflicts with `jpeg-turbo`.

# If you need to have jpeg first in your PATH, run:
#   echo 'export PATH="/opt/homebrew/opt/jpeg/bin:$PATH"' >> /Users/justin/.zshrc

# For compilers to find jpeg you may need to set:
#   export LDFLAGS="-L/opt/homebrew/opt/jpeg/lib"
#   export CPPFLAGS="-I/opt/homebrew/opt/jpeg/include"

# For pkgconf to find jpeg you may need to set:
#   export PKG_CONFIG_PATH="/opt/homebrew/opt/jpeg/lib/pkgconfig"

export PATH="/opt/homebrew/opt/jpeg/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/jpeg/lib"
export CPPFLAGS="-I/opt/homebrew/opt/jpeg/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/jpeg/lib/pkgconfig"
