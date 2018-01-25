# NOTE: source this file from a BATS test case file

# This library defines functions to use in the BATS test files for use with the
# Knife test flow.

cachedir="/opt/swupd/environment"
logdir="$cachedir/logs/$tap_test"
mkdir -p $cachedir
mkdir -p $logdir
# FIXME: swupd-client needs a configurable state dir to facilitate testing.
# Also, it would be nice to run these tests on Clear and keep Clear's
# /var/lib/swupd cache (see CLEAR-1161).
sudo rm -rf /var/lib/swupd

set_repo_revisions() {
  return 0
}

clone_and_checkout() {
  return 0
}

# FIXME: export LDFLAGS for client and server for building against local bsdiff checkout
build() {
  return 0
}

build_all_repos() {
  return 0
}

init_bundles() {
  return 0
}

copy_chroots() {
  # FIXME: run the equivalent of this commend in the Knife scripts
  # (see usage in locallib.bash)
  #find "$UPDATEDIR"/image -type f -name '.gitignore' -delete
  return 0
}

run_server_for_chroots() {
  local starver=$1
  local format_staging_path=/var/lib/update-$tap_test/version/formatstaging
  ssh root@$IP "echo $starver > $format_staging_path/latest"
}

# Remove the specified file (or directory) from the server chroot for VER
remove_from_server_webdir() {
  local ver=$1
  local file=$2

  ssh root@$IP "rm -rf /var/lib/update-$tap_test/$ver/$file"
  return 0
}

swupd_cmd() {
  local cmd=$1
  echo "$cachedir/swupd $cmd -u $URL -F staging -p $testdir/"
}

# Initializes a test directory for a chroot combination
# Parameters:
#   startver - version for the chroot combination (cannot combine versions yet)
#   bundlelist - comma-separated list of chroot names
init_combined_chroot() {
  local startver="$1"
  local bundlelist="$2"
  # global variable, so the run_* functions can reference it
  testdir=$BATS_TEST_DIRNAME/test-chroot

  mkdir -p "$testdir"
  local chroots=($(echo $bundlelist | tr ',' ' '))
  for c in ${chroots[@]}; do
    cp --archive --no-clobber $BATS_TEST_DIRNAME/chroots/$startver/$c/* $testdir/
  done
}

# Initializes a new directory for running a swupd-client test.
# Parameters:
#   startver - the version of BUNDLE to initialize
#   bundle - the bundle name to initialize
init_testdir() {
  local startver=$1
  local bundle=$2
  # global variable, so the run_* functions can reference it
  testdir=$BATS_TEST_DIRNAME/test-chroot

  sudo rm -rf $testdir
  mkdir -p $testdir
  cp -a $BATS_TEST_DIRNAME/chroots/$startver/$bundle/* $testdir/

  # Empty directories contain .gitignore, so remove them, since they are not
  # accounted for in checksumming.
  find $testdir -type f -name '.gitignore' -delete
}

run_bundleadd_test() {
  init_testdir "$1" "$2"
  local newbundle=$3

  local cmd=$(swupd_cmd "bundle-add")
  (
    sudo $cmd $newbundle
  ) &> $logdir/test_bundleadd.log
}

run_bundleremove_test() {
  init_combined_chroot "$1" "$2"
  local targetbundle=$3

  local cmd=$(swupd_cmd "bundle-remove")
  (
    sudo $cmd $targetbundle
  ) &> $logdir/test_bundleremove.log
}

run_update_test() {
  init_testdir "$1" "$2"

  local cmd=$(swupd_cmd "update")
  (
    sudo $cmd
  ) &> $logdir/testupdate_$1.log
}

run_remove_and_verify_fix_test() {
  init_testdir "$1" "$2"
  local file=$3

  rm -r $testdir/$file
  local cmd=$(swupd_cmd "verify --fix")
  (
     sudo $cmd
  ) &> $logdir/testupdate_$1.log
}

validate() {
  local ver=$1
  local bundle=$2
  local shafile=$BATS_TEST_DIRNAME/SHA256SUMS
  local testdir=$BATS_TEST_DIRNAME/test-chroot

  expected=$(awk -v V=$ver -v B=$bundle '$2 == V && $3 == B { print $1 }' $shafile)
  result=$($BATS_TEST_DIRNAME/../../scripts/chroot-checksum.sh $testdir)
  if [ "$expected" = "$result" ]; then
    return 0 # pass
  else
    return 1 # fail
  fi
}

cleanup_previous_results() {
  return 0
}

# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
