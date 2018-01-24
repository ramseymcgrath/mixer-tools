# NOTE: source this file from a BATS test case file

# This library defines functions to use in the BATS test files during a local
# test run with 'make check'.

export cachedir="$HOME/.cache/mixer-tests"
logdir="$BATS_TEST_DIRNAME/logs"
BUNDLE_DIR="$BATS_TEST_DIRNAME/mix-bundles"
CLRVER=$(curl https://download.clearlinux.org/update/version/format18/latest)
CLR_BUNDLES="$BATS_TEST_DIRNAME/clr-bundles/clr-bundles-$CLRVER/bundles"
mkdir -p $cachedir
mkdir -p $logdir

setup_builder_conf() {
  echo -e "[Builder]
SERVER_STATE_DIR = $BATS_TEST_DIRNAME/update
BUNDLE_DIR = $BUNDLE_DIR
YUM_CONF = $BATS_TEST_DIRNAME/.yum-mix.conf
CERT = $BATS_TEST_DIRNAME/Swupd_Root.pem
VERSIONS_PATH = $BATS_TEST_DIRNAME

[swupd]
BUNDLE=os-core-update
CONTENTURL=localhost
VERSIONURL=localhost
FORMAT=3" > $BATS_TEST_DIRNAME/builder.conf
}

mixer-init-versions() {
  sudo -E mixer init-mix --config $BATS_TEST_DIRNAME/builder.conf --clear-version $1 --mix-version $2
  for i in $(ls $BUNDLE_DIR | grep -v "os-core$"); do sudo rm -rf $BUNDLE_DIR/$i; done
}

mixer-build-chroots() {
  sudo mixer build chroots --config $BATS_TEST_DIRNAME/builder.conf
}

mixer-create-update() {
  sudo mixer build update --config $BATS_TEST_DIRNAME/builder.conf
}

mixer-add-rpms() {
  mkdir -p ./local ./results
  sudo mixer add-rpms --config $BATS_TEST_DIRNAME/builder.conf
}

add-bundle() {
  sudo touch $BUNDLE_DIR/$1
}

add-package() {
  echo $1 | sudo tee $BUNDLE_DIR/$2 > /dev/null
}

add-clear-bundle() {
  sudo cp $CLR_BUNDLES/$1 $BUNDLE_DIR
}

remove-bundle() {
  sudo rm -rf $BUNDLE_DIR/$1
}

remove-package() {
  sudo sed -i "/$1/d" $BUNDLE_DIR/$2
}

download-rpm() {
  mkdir -p ./results
  cd ./results
  curl -O $1
  cd ..
}

# vi: ft=sh ts=8 sw=2 sts=2 et tw=80
