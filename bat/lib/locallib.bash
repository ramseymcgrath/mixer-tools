# NOTE: source this file from a BATS test case file

# This library defines functions to use in the BATS test files during a local
# test run with 'make check'.

cachedir="$HOME/.cache/swupd-pre-release"
logdir="$BATS_TEST_DIRNAME/logs"
mkdir -p $cachedir
mkdir -p $logdir
# FIXME: swupd-client needs a configurable state dir to facilitate testing.
# Also, it would be nice to run these tests on Clear and keep Clear's
# /var/lib/swupd cache (see CLEAR-1161).
sudo rm -rf /var/lib/swupd


set_repo_locations() {
  export bsdiff_url=${BSDIFF_REPO:-"https://github.com/clearlinux/bsdiff.git"}
  export swupd_client_url=${CLIENT_REPO:-"https://github.com/clearlinux/swupd-client.git"}
  export swupd_server_url=${SERVER_REPO:-"https://github.com/clearlinux/swupd-server.git"}
}

set_repo_revisions() {
  set_repo_locations
  export bsdiff_commit=${BSDIFF:-"HEAD"}
  export swupd_server_commit=${SERVER:-"HEAD"}
  export swupd_client_commit=${CLIENT:-"HEAD"}
}

clone_and_checkout() {
  local project=$1
  local var=$(echo ${project}_url)
  local url=${!var}
  (
    if [ ! -d $cachedir/$project ]; then
      git clone $url $cachedir/$project
      cd $cachedir/$project
    else
      cd $cachedir/$project
      git checkout master
      git pull
    fi
    var=$(echo ${project}_commit)
    local commit=${!var}
    git checkout $commit
    cd -
  ) &> $logdir/clone_$project.log
}

build() {
  local project=$1
  (
    cd $cachedir/$project
    [ ! -f $cachedir/$project/configure ] && autoreconf -fi

    # build client and server against local bsdiff checkout
    if [ "$project" != "bsdiff" ]; then
      built_bsdir="$cachedir/bsdiff/.libs"
      built_curdir="$cachedir/$project/.libs"
      export bsdiff_CFLAGS=" "
      export bsdiff_LIBS="-L$built_bsdir -lbsdiff"
      export LDFLAGS="-L$built_bsdir -L$built_curdir -Wl,-rpath,$built_bsdir -Wl,-rpath,$built_curdir"
    fi

    ./configure
    make
    cd -
  ) &> $logdir/build_$project.log
}

build_all_repos() {
  clone_and_checkout bsdiff
  build bsdiff
  clone_and_checkout swupd_server
  build swupd_server
  clone_and_checkout swupd_client
  build swupd_client
}

init_bundles() {
  local ver=$1
  export BUNDLEREPO=$cachedir/test-bundles
  rm -rf $BUNDLEREPO
  mkdir -p $BUNDLEREPO/bundles

  ls $BATS_TEST_DIRNAME/chroots/$ver | while read BUNDLE; do
    touch $BUNDLEREPO/bundles/$BUNDLE
  done
}

copy_chroots() {
  local ver=$1
  mkdir -p "$UPDATEDIR"/image
  cp -a $BATS_TEST_DIRNAME/chroots/$ver "$UPDATEDIR"/image/

  # Empty directories contain .gitignore, so remove them, since they should not
  # be part of the update content, and they are not accounted for in checksums.
  find "$UPDATEDIR"/image -type f -name '.gitignore' -delete
}

run_server_for_chroots() {
  local VER=$1
  init_bundles $VER
  # set some variables for basic_creator.sh
  export SWUPDREPO=$cachedir/swupd_server
  export BUNDLEREPO=$BUNDLEREPO
  export UPDATEDIR=$BATS_TEST_DIRNAME/update
  copy_chroots $VER
  (
    cd $logdir
    sudo -E $cachedir/swupd_server/basic_creator.sh $VER
  ) &> $logdir/basic_creator_$VER.log
}

# Remove the specified file (or directory) from the server chroot for VER
remove_from_server_webdir() {
  local ver=$1
  local file=$2

  sudo rm -rf $UPDATEDIR/www/$ver/$file
}

gen_includes_file() {
  local bundle=$1
  local ver=$2
  local includes="${@:3}"
  mkdir -p $BATS_TEST_DIRNAME/update/www/$ver/noship
  for b in $includes; do
    cat >> $BATS_TEST_DIRNAME/update/www/$ver/noship/"$bundle"-includes << EOF
$b
EOF
  done
}

swupd_cmd() {
  local cmd=$1
  echo "$cachedir/swupd_client/swupd $cmd -u file://$UPDATEDIR/www -F staging -p $testdir/"
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
  local ver=$1
  local bundle=$2
  if grep -q ',' <<<"$bundle"; then
    init_combined_chroot "$ver" "$bundle"
  else
    init_testdir "$ver" "$bundle"
  fi

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

run_verify_fix_test() {
    local cmd=$(swupd_cmd "verify --fix")
    (
      sudo $cmd
      &> $logdir/test_verifyfix.log
    )
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
  # Remove content from a previous test run
  sudo rm -rf $BATS_TEST_DIRNAME/update
  sudo rm -rf $BATS_TEST_DIRNAME/test-chroot
}


# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
