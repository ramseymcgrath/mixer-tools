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
  mixer-build-chroots
  mixer-create-update > $BATS_TEST_DIRNAME/create_update-10.log
}

@test "Create version 20 with more Clear bundles" {
  mixer-init-versions $CLRVER 20
  add-clear-bundle "editors"
  add-clear-bundle "python-basic"
  add-clear-bundle "sysadmin-basic"
  mixer-build-chroots
  mixer-create-update > $BATS_TEST_DIRNAME/create_update-20.log
}
@test "Create version 30 with Clear bundle deleted" {
  mixer-init-versions $CLRVER 30
  remove-bundle "clr-devops"
  mixer-build-chroots
  mixer-create-update > $BATS_TEST_DIRNAME/create_update-30.log
}

# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
