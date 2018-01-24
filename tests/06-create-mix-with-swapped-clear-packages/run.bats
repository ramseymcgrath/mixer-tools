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
  add-clear-bundle "os-core-update"
  mixer-build-chroots
  mixer-create-update
}

@test "Create version 20 with swupd moved from os-core-update into os-core" {
  localize_builder_conf
  mixer-init-versions $CLRVER 20
  remove-package "swupd-client" "os-core-update"
  add-package "swupd-client" "os-core"
  mixer-build-chroots
  mixer-create-update > $BATS_TEST_DIRNAME/create_update-20.log
}

# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
