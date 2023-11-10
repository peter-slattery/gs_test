# TODO:
- flag for allocation testing:
  - before each test, push an allocator specific to the test
  - allow a postamble that inspects / expects a certain number of allocations to have been made

- Spike: resolving multiple references to the same dependency
  - ie. two files which both #load the same file
  - Reason: If we can resolve this, it would enable compiling tests as a single compilation unit
    rather than multiple, which will significantly speed up test compilation

- check for Test declarations after Run_Test_Harness
  - maybe insert an end_of_main function that looks for
    declarations that didn't run?

- investigate multi-file tests.
  - what happens if you do something like:
    ```
    #load "tests_a.jai";
    main :: () {
      Init_Test_Harness();
      tests_declared_in_test_a();
      Run_Test_Harness();
    }
    ```