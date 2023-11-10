#import "Basic";
#import "Compiler";
#import "String";

gs_test :: #import "gs_test";

#run build();
build :: ()
{
  target_options := get_build_options();

  target_options.output_executable_name = "basic_test";
  target_options.output_path = tprint("%/output", #filepath);

  gs_test.build_all_tests(.{
    root_paths = .[#filepath],
    test_categories = .[
      .{
        file_extension = ".gs_test.jai",
      },
      .{
        file_extension = ".test_group_b.jai",

        category_name = "group_b",
        // It's useful to be able to run only a subset of your total
        // test suite. By creating categories, you can specifiy
        // individual categories to run in run_all_tests.sh
      },

      // Sometimes it's useful to have a set of files get compiled
      // along side your tests but which you don't want run with
      // the automated test suite - for example, tests that rely
      // on creating windows, etc.
      .{
        file_extension = ".manual_test.jai",

        exe_extension = ".manual.test",
        // exe_extension will get appended to the output filename
        // before any platform specific executable extensions.
        // ie. on windows this will output basic.manual.test.exe

        category_name = "manual",

        exclude_from_run_all_tests = true,
        // all output executables in this category will be omitted
        // from run_all_tests.sh
      }
    ]
  }, target_options);

  set_build_options_dc(.{ do_output = false }); // exclude this file from build
}
