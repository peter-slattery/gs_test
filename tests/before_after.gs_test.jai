befores_called := 0;
afters_called := 0;

main :: () {
  Init_Test_Harness();

  Before_Each(() {
    befores_called += 1;
  });

  After_Each(() {
    afters_called += 1;
  });

  Test("before / after hooks #1", () {
    expect(befores_called, 1);
    expect(afters_called, 0);
  });

  Test("before / after hooks #2", () {
    expect(befores_called, 2);
    expect(afters_called, 1);
  });

  Run_Test_Harness();
}
