#!/usr/bin/env bats

# shared test functions
if [ -n "$KNIFE" ]; then
  load ../../lib/knifelib
  load ../../lib/mixerlib
else
  load ../../lib/locallib
  load ../../lib/mixerlib
fi

setup() {
  setup_builder_conf
}

@test "Create initial mix 10" {
  mixer-init-versions $CLRVER 10
  clean-bundle-dir
  mixer-build-chroots
  mixer-create-update
}

@test "Create version 20 with no changes" {
  mixer-init-versions $CLRVER 10
  mixer-build-chroots
  mixer-create-update > $BATS_TEST_DIRNAME/create_update20.log
}
# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
