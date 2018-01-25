#!/usr/bin/env bats

# shared test functions
if [ -n "$KNIFE" ]; then
  load ../../lib/knifelib
  load ../../lib/mixerlib
else
  load ../../lib/locallib
  load ../../lib/mixerlib
fi

@test "Create initial mix 10" {
}

# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
