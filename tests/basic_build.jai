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
      }
    ]
  }, target_options);

  set_build_options_dc(.{ do_output = false }); // exclude this file from build
}
