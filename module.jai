#import "Basic";
#import "Compiler";
#import "File";
#import "File_Utilities";
#import "String";

Test_Category :: struct
{
  file_extension: string = ".test.jai";
  // The extension all test files will end in.
  // You can override this, but it is recommended that you never set it to .jai as
  // that will match all your normal jai files as well.

  exe_extension: string = "";
  // The extension of the output test executable.
  // If not set, this will be overridden
  // with .test.exe on windows and .test everywhere else.

  category_name: string = "default";
  // If set to anything other than defualt, will put these tests inside an if block inside
  // run_all_tests that checks for this name in the arguments to run_all_tests.sh
  // ie. if category_name is "unit", then calling "run_all_tests.sh unit" will run just the
  //     tests in this category

  exclude_from_run_all_tests: bool = false;
  // This is useful if you have a category of tests that need to be run manually, or don't
  // make sense to be run in CI
}

Config :: struct
{
  root_paths: []string;
  // REQUIRED: The root directory in which tests are found

  test_categories: []Test_Category;
  // REQUIRED: You must supply at least one test category. However, it is enough to simply
  // do:
  //   config.test_categories = .[.{}];

  tests_output_dir: string = "";
  // Where test executables will be output.
  // If not set, this will be set to the value of {build_options.root_path}/tests_out
}

build_all_tests :: (config: Config, build_options: Build_Options, loc := #caller_location)
{
  set_optimization(*build_options, .DEBUG);
  configure(config, build_options, loc);
  output();
}

configure :: (config: Config, build_options: Build_Options, loc := #caller_location)
{
  stored_config = config;

  if stored_config.test_categories.count == 0
  {
    print("gs_test: Error - No test_categories provided, so no tests will be build. Aborting.\n");
    exit(1);
  }

  for * stored_config.test_categories
  {
    if (it.file_extension == "") it.file_extension = ".test.jai";
    if (it.exe_extension == "")
    {
      it.exe_extension = ".test";
    }
  }

  if (stored_config.root_paths.count == 0)
  {
    compiler_report(loc.fully_pathed_filename, loc.line_number, loc.character_number, "You must supply a root_path in gs_test's config object");
    exit(1);
  }

  if (stored_config.tests_output_dir == "")
  {
    path := parse_path(stored_config.root_paths[0]);
    array_add(*path.words, "tests_out");
    stored_config.tests_output_dir = path_to_string(path);
    print("Fallback tests_output_dir: %\n", stored_config.tests_output_dir);
  }
  else
  {
    for i: 0..stored_config.tests_output_dir.count - 1
    {
      if stored_config.tests_output_dir[i] == #char "\\"
      {
        stored_config.tests_output_dir[i] = #char "/";
      }
    }
    path := parse_path(stored_config.tests_output_dir);
    stored_config.tests_output_dir = path_to_string(path);
  }

  stored_build_options = build_options;
  stored_build_options.output_path = stored_config.tests_output_dir;

  make_directory_if_it_does_not_exist(stored_build_options.output_path, true);

  for root_path: config.root_paths
  {
    visit_files(root_path, true, *test_files, record_test_file);
  }
}

output :: ()
{
  run_all_tests_builder: String_Builder;
  init_string_builder(*run_all_tests_builder);
  append(*run_all_tests_builder, "#!/bin/bash\n");
  append(*run_all_tests_builder, "SUCCESS=0\n");
  append(*run_all_tests_builder, "ARGS=$@\n");

  category_builders: [..]String_Builder;
  for stored_config.test_categories
  {
    b := array_add(*category_builders);
    init_string_builder(b);
  }

  for test_files
  {
    category := stored_config.test_categories[it.category];
    exe_path := build_test_file(it.file_path, category);
    if (exe_path != "" && !category.exclude_from_run_all_tests)
    {
      print_to_builder(*category_builders[it.category], "% $@\n%", exe_path, UPDATE_SUCCESS_CODE);
    }
  }

  for category, i: stored_config.test_categories
  {
    if category.exclude_from_run_all_tests continue;

    category_builder := *category_builders[i];
    print_to_builder(*run_all_tests_builder, "\n# Category: %\n", category.category_name);
    if category.category_name != "default"
    {
      print_to_builder(*run_all_tests_builder, "if [[ \" ${ARGS[*]} \" =~ \" % \" ]]; then\n", category.category_name);
    }
    print_to_builder(*run_all_tests_builder, "%\n", builder_to_string(category_builder));
    if category.category_name != "default"
    {
      print_to_builder(*run_all_tests_builder, "fi\n");
    }
  }

  append(*run_all_tests_builder, "exit $SUCCESS");
  run_all_tests_sh := builder_to_string(*run_all_tests_builder);
  write_entire_file(string_append(stored_config.tests_output_dir, "/run_all_tests.sh"), run_all_tests_sh);
}

#scope_file

stored_config: Config;
stored_build_options: Build_Options;

Test_File :: struct
{
  file_path: string;
  category: int;
}

test_files: [..]Test_File;

UPDATE_SUCCESS_CODE :: #string DONE
if [ $? != 0 ];
then
  SUCCESS=1
fi
DONE

string_append :: (args: .. string) -> string
{
  sb: String_Builder;
  init_string_builder(*sb);
  for args {
    append(*sb, it);
  }
  return builder_to_string(*sb);
}

record_test_file :: (info: *File_Visit_Info, test_files: *[..]Test_File)
{
  if (info.is_directory) return;

  longest_match := 0;
  longest_match_index := -1;
  for category, category_i: stored_config.test_categories
  {
    if (ends_with_nocase(info.full_name, category.file_extension))
    {
      if longest_match < category.file_extension.count
      {
        longest_match = category.file_extension.count;
        longest_match_index = category_i;
      }
    }
  }


  if longest_match_index >= 0
  {
    array_add(test_files, .{
      file_path = copy_string(info.full_name),
      category = longest_match_index
    });
    print("  Test File: % - Category: %\n", info.full_name, stored_config.test_categories[longest_match_index].category_name);
  }
}

build_test_file :: (path_string: string, category: Test_Category) -> string
{
  workspace := compiler_create_workspace(tprint("Test: %", path_string));
  if !workspace
  {
    compiler_report(path_string, 0, 0, "Unable to create workspace for test file");
    return "";
  }

  path := parse_path(path_string);
  filename := path.words[path.words.count - 1];
  filename_without_ext := slice(filename, 0, filename.count - category.file_extension.count);
  exe_output_path := string_append(
    filename_without_ext,
    category.exe_extension
  );

  build_options := stored_build_options;
  build_options.output_executable_name = exe_output_path;

  set_build_options(build_options, workspace);
  add_build_file(path_string, workspace);
  add_build_string(tprint("#load \"%harness.jai\";\n", #filepath), workspace);

  output_path := parse_path(stored_build_options.output_path);
  array_add(*output_path.words, exe_output_path);
  output_path.trailing_slash = false;

  return path_to_string(output_path);
}