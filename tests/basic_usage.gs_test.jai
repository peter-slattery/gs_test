// This is a basic example test.

#load "./example_math.jai";
// You can import files and libraries as normal.
//
// Note you do not have to import anything for the test
// suite specifically. That gets handled by the metaprogram.

main :: () {
  Init_Test_Harness("basic");
  // This call initializes the test harness.
  // The string you pass in will be prefixed to all test names.
  // (you can omit the prefix if you want.)

  // This is how you create a single test.
  // A test is a logically connected unit of functionality you
  // want to verify the results of.
  Test("example test", () {
    expect(times2(1), 2);
    expect(times2(2), 4);
  });

  // You can have more than one test in a suite.
  Test("example test 2", () {
    expect(times2(3), 6);

    // uncomment this next expect call to see what it's like when
    // a test fails
    // expect(times2(4), 3);
  });

  Run_Test_Harness();
  // when you're done declaring tests, call Run_Test_Harness
  // to actually run all the tests and output the results

  // This test will never run because it's being declared after
  // Run_Test_Harness. We don't have a good way to check this and
  // alert you automatically right now so be careful
  Test("bad test", () {
    expect(times2(4), 3);
  });
}
