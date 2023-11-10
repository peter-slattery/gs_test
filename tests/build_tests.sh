#!/bin/bash

ROOT_DIR=$(dirname BASH_SOURCE[0])/../
IMPORT_DIR=$ROOT_DIR/../

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  JAI=jai-linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
  JAI=jai-macos
else
  JAI=jai
fi

$JAI -import_dir "${IMPORT_DIR}" ./basic_build.jai
COMPILED=$?

if [ $COMPILED -ne 0 ]; then
  echo "Building Tests Failed"
  exit 1
fi

chmod +x ./tests_out/run_all_tests.sh