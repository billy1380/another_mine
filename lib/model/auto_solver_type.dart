enum AutoSolverType {
  simple("Simple", "Simple (Fast)"),
  probability("Probability", "Probability (Smart)");

  final String title, description;
  const AutoSolverType(this.title, this.description);
}
