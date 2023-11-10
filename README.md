# gs_test
Framework for test implementation + test discovery in jai

## Description

This Jai Module provies a means of writing tests and building a test executable
that can be used in applications such as CI runners.

## Test Executable Reference
Test executables can be run individually or via `run_all_tests.sh` which is output in the same directory.
Both tests and `run_all_tests.sh` have the same options:

`-colors`: output colored information for easier readability
`-verbose`: by default the output will only show test suites run, and full information on errors. Enabling verbose output indicates all tests that are run as well.

## Test Harness Reference

`Init_Test_Harness(suite_name: string)`: Call at the beginning of your test suite function to initialize the test suite.
`Run_Test_Harness()`: Call at the end of your test suite function to execute all tests
`Before_Each(#type () -> ())`: Define a function that will be run before each test
`After_Each(#type () -> ())`: Define a funciton that will be run after each test
`Test(test_name: string, test_proc: #type () -> ())`: Define a single test function

`expect(received, expected)`: Checks for equality between the two values. Equivalent to `if (received != expected) report_test_failure()`
`expect_true(value)`
`expect_false(value)`

## How It Works

1. You call `gs_test.build_all_tests` from your build script
2. gs_test scans your project directory for files ending in the specified extension (default is `.test.jai`)
3. For each test file found, gs_test outputs an executable
4. gs_test outputs a `run_all_tests` file

You can call `run_all_tests` in CI and it will output an error code if any tests fail.

## To Try It Out:

1. Put gs_test somewhere where your jai compiler can find it.
  ie. `C:\jai\modules\gs_test`
2. Copy the two examples below into files in a sample project directory
3. Run `jai -import_dir C:\jai\modules build.jai`
4. Run `./tests/run_all_tests.sh` (you might need to give it execute permissions first)

## Example Usage:

build.jai
```jai
  #import "Compiler";
  gs_test :: #import "gs_test";

  #run build();
  build :: ()
  {
    w := compiler_create_workspace("Target Program");
    target_options := get_build_options(w);

    mc := gs_test.Config.{
      // See gs_test/module.jai::Config for information on how to configure things further
      root_path = #filepath
    }
    gs_test.build_all_tests(mc, target_options);

    set_build_options_dc(.{ do_output = false });
  }
```

main.test.jai
```jai
main :: () {
  Init_Test_Harness();

  Test("my test", () {
    expect(5, 5); // succeeds
    expect(5, 3); // fails
  });

  Run_Test_Harness();
}

```

## Why One Executable Per Test File?

Because of the way Jai handles imports, we have to either have a single test executable which runs all your tests, or make an executable per test file. In the former case, we'd be forced to do a bunch of complicated things to deduplicate #load
calls in the cases where you have separate tests importing the same files. This solution seemed simpler - you define your tests how you want, and for each file, just import what that test requires. I may revist this in the future.

## Goals

1. Simply import the test framework into your build pipeline, pass compiler messages to it, and get tests out.
2. Easily write tests, and get useful failure information back out.
3. Reasonable Defaults:
  - creates a single test executable next to your output
  - runs all tests, returning failure codes on exit
  - tests can be placed in *.test.jai files or inline with @test tags.
4. Customization
  - name the output file
  - define the pattern for test files (ie. instead of *.test.jai, use something else)
  - define the test tag (ie. instead of @test, use something else)