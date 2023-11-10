// See License Information at the bottom of this file

#import "Basic";
#import "String";

///////////////////////////////////////////////////////////////////////
// BEGIN INTERFACE

// Register a function to run before each test
Before_Each :: (proc: Test_Proc, loc := #caller_location) #expand
{
  h := harness();
  if h.before_each
  {
    print_error("You cannot register more than one Before_Each handler", loc);
    exit(1);
  }
  h.before_each = proc;
}

// Register a function to run after each test
After_Each :: (proc: Test_Proc, loc := #caller_location) #expand
{
  h := harness();
  if h.after_each
  {
    print_error("You cannot register more than one After_Each handler", loc);
    exit(1);
  }
  h.after_each = proc;
}

// Wrapper for registering a test procedure you want to have run
Test :: (name: string, proc: Test_Proc, loc := #caller_location, only := false) #expand
{
  h := harness();
  test_index := h.tests.count;
  array_add(*h.tests, .{
    name = name,
    proc = proc
  });

  if only
  {
    if h.only_index < 0
    {
      h.only_index = test_index;
    }
    else
    {
      print_error("You cannot register more than one test to be the only one to run.", loc);
      exit(1);
    }
  }
}

// Call this at the beginning of your main function
Init_Test_Harness :: (prefix: string = "", loc := #caller_location) #expand
{
  h := harness();
  << h = Test_Harness.{
    test_prefix = prefix,
    filename = tprint("%", #file),
  };
  init_string_builder(*h.message_builder);

  apply_command_line_arguments(h);

  print("%\n", loc.fully_pathed_filename);
}

// Call this at the end of your main function
Run_Test_Harness :: (loc:= #caller_location) #expand
{
  h := harness();

  if h.only_index >= 0 && h.only_index < h.tests.count
  {
    run_single_test(h, h.tests[h.only_index]);
  }
  else
  {
    for h.tests
    {
      run_single_test(h, it);
    }
  }

  return_code := finish_all_tests();
  exit(return_code);
}

EXPECT_MACRO :: (input: $T, expected: T, loc: Source_Code_Location, info: string, condition: Code) #expand {
  test_begin();
  passed := #insert condition;
  if passed {
    report_test_passed();
  } else {
    report_test_failed(input, expected, loc, info);
  }
}

expect :: (input: $T, expected: T, loc := #caller_location, info := "") {
  EXPECT_MACRO(input, expected, loc, info, #code input == expected);
}
expect_strings_equal :: (input: string, expected: string, loc:= #caller_location, info := "") {
  EXPECT_MACRO(input, expected, loc, info, #code equal(input, expected));
}
expect_true :: (input: bool, loc:= #caller_location, info := "") {
  EXPECT_MACRO(input, true, loc, info, #code input == true);
}
expect_false :: (input: bool, loc:= #caller_location, info := "") {
  EXPECT_MACRO(input, false, loc, info, #code input == false);
}

// END INTERFACE
///////////////////////////////////////////////////////////////////////

test_begin :: () {
  TESTS_ATTEMPTED += 1;
}

report_test_passed :: () {
  TESTS_PASSED += 1;
}

report_test_failed :: (input: $T, expected: T, loc: Source_Code_Location, info: string) {
  h := harness();
  ANY_TESTS_FAILED = true;
   print_to_builder(
    *h.message_builder,
    "    %Test Failed:%\n",
    h.colors.red,
    h.colors.normal
  );
  print_to_builder(*h.message_builder,
    "      %:%:%\n", loc.fully_pathed_filename, loc.line_number, loc.character_number
  );
  print_to_builder(*h.message_builder,
    "      Expected: %\n", expected
  );
  print_to_builder(*h.message_builder,
    "      Received: %\n", input
  );
  if info.count > 0 {
    print_to_builder(*h.message_builder, "      Info: %\n", info);
  }
}

#scope_file

ANY_TESTS_FAILED := false;
TESTS_ATTEMPTED := 0;
TESTS_PASSED    := 0;
TOTAL_TESTS_ATTEMPTED := 0;
TOTAL_TESTS_PASSED := 0;

Terminal_Color_Codes :: struct {
  normal: string;
  red: string;
  green: string;
  blue: string;
};

colors :: Terminal_Color_Codes.{
  normal = "\e[m",
  red = "\e[1;31m",
  green = "\e[1;32m",
  blue = "\e[1;34m",
};
no_colors :: Terminal_Color_Codes.{};

Test_Proc :: #type () -> ();

Test_Desc :: struct {
  name: string;
  proc: Test_Proc;
}

Test_Harness :: struct {
  filename: string;
  tests: [..]Test_Desc;

  // if set, then tests[only_index] will be the only one to run.
  // it is an error to set multiple tests to only.
  only_index := -1;

  before_each: Test_Proc;
  after_each: Test_Proc;
  test_prefix: string = "";

  verbose: bool = false;
  colors := no_colors;

  message_builder: String_Builder;
}

#add_context global_test_harness: Test_Harness;
harness :: () -> *Test_Harness { return *context.global_test_harness; }

apply_command_line_arguments :: (harness: *Test_Harness)
{
  args := get_command_line_arguments();
  for arg: args {
    if arg[0] != #char "-" continue;
    if arg == {
      case "-colors";  harness.colors = colors;
      case "-verbose"; harness.verbose = true;
    }
  }
}

test_suite_end :: (name: string)
{
  h := harness();
  print_test_name :: (h: Test_Harness, name: string, prefix: string)
  {
    print("%", h.colors.blue);
    if (prefix.count) print("% :: %\n", prefix, name);
    else print("%\n", name);
    print("%", h.colors.normal);
  }

  if TESTS_ATTEMPTED == TESTS_PASSED
  {
    if TESTS_ATTEMPTED > 0
    {
      if (h.verbose)
      {
        print("  %PASS ", h.colors.green);
        print_test_name(h, name, h.test_prefix);
      }
    }
    else
    {
      print("  %NO TESTS RUN ", h.colors.red);
      print_test_name(h, name, h.test_prefix);
    }
  }
  else
  {
    print("  %FAIL ", h.colors.red);
    print_test_name(h, name, h.test_prefix);
  }

  messages := builder_to_string(*h.message_builder, do_reset = true);
  print(messages);

  TOTAL_TESTS_ATTEMPTED += TESTS_ATTEMPTED;
  TOTAL_TESTS_PASSED += TESTS_PASSED;
  TESTS_ATTEMPTED = 0;
  TESTS_PASSED = 0;
}

run_single_test :: (h: *Test_Harness, test: Test_Desc)
{
  if h.before_each
  {
    h.before_each();
  }

  test.proc();
  test_suite_end(test.name);

  if h.after_each
  {
    h.after_each();
  }
}

finish_all_tests :: () -> s32
{
  h := harness();
  return_code: s32 = 0;

  if !ANY_TESTS_FAILED
  {
    print("Tests: % / %\n", TOTAL_TESTS_PASSED, TOTAL_TESTS_ATTEMPTED);
    print("  SUITE STATUS: %PASS%\n\n", h.colors.green, h.colors.normal);
  }
  else
  {
    return_code = 1;
    print("Tests: % / %\n", TOTAL_TESTS_PASSED, TOTAL_TESTS_ATTEMPTED);
    print("  SUITE_STATUS: %FAIL%\n\n", h.colors.red, h.colors.normal);
  }
  return return_code;
}

print_error :: (msg: string, loc: Source_Code_Location)
{
  h := harness();
  print("%", h.colors.red);
  print("%:% - %\n", loc.fully_pathed_filename, loc.line_number, msg);
  print("%", h.colors.normal);
}

/*
zlib License

(C) Copyright 2023 Peter Slattery

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
  claim that you wrote the original software. If you use this software
  in a product, an acknowledgment in the product documentation would be
  appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
  misrepresented as being the original software.
3. This notice may not be removed or altered from any source distribution.

*/