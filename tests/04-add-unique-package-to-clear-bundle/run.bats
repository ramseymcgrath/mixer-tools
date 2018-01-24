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

@test "Create version 20 with unique custom bundle added to os-core-update" {
  localize_builder_conf
  mixer-init-versions $CLRVER 20
  download-rpm "ftp://rpmfind.net/linux/fedora-secondary/development/rawhide/source/SRPMS/j/json-c-0.12-7.fc24.src.rpm"
  mixer-add-rpms
  add-package "json-c" "os-core-update"
  mixer-build-chroots
  mixer-create-update > $BATS_TEST_DIRNAME/create_update-20.log
}
# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
