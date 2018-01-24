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
  setup_builder_conf
  mixer-init-versions $CLRVER 10
  mixer-build-chroots
  mixer-create-update
}

@test "Create version 20 with bootloader & kernel-kvm added" {
  mixer-init-versions $CLRVER 20
  add-clear-bundle "kernel-kvm"
  add-clear-bundle "bootloader"
  mixer-build-chroots
  mixer-create-update > $BATS_TEST_DIRNAME/create_update-20.log
}

@test "Create version 30 with old swupd-server" {
  mixer-init-versions $CLRVER 30
  mixer-build-chroots
  sudo mixer build-update -prefix $cachedir/swupd_server/ -config ./builder.conf -format 3 -no-publish > $BATS_TEST_DIRNAME/create_update-30.log
}

@test "Create version 40 with format/client bump using new server" {
  run sed -i 's/FORMAT=3/FORMAT=4/' $BATS_TEST_DIRNAME/builder.conf
  mixer-init-versions $CLRVER 40
  sudo mv ./update/image/30 ./update/image/40
  sudo mixer build-update -config ./builder.conf -keep-chroots -format 4 > $BATS_TEST_DIRNAME/create_update-40.log
}
# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
