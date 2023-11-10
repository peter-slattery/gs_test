#!/bin/bash
SUCCESS=0
ARGS=$@

TEST_DIR=$(dirname ${BASH_SOURCE[0]})/tests_out

# Category: solo
if [[ " ${ARGS[*]} " =~ " solo " ]]; then
  $TEST_DIR/basic_first.test $@
  if [ $? != 0 ];
  then
    SUCCESS=1
  fi
  $TEST_DIR/basic_first2.test $@
  if [ $? != 0 ];
  then
    SUCCESS=1
  fi

fi
exit $SUCCESS