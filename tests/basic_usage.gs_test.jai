#load "./example_math.jai";

main :: () {
  Init_Test_Harness();

  Test("basic test", () {
    expect(times2(1), 2);
    expect(times2(2), 4);
  });

  Run_Test_Harness();
}
