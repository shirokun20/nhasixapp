/// Question types for the interactive config wizard.
enum QuestionType {
  text,
  choice,
  multiChoice,
  yesNo,
}

/// A single question in the wizard flow.
class WizardQuestion {
  WizardQuestion({
    required this.id,
    required this.prompt,
    required this.type,
    this.choices,
    this.defaultValue,
    this.validator,
    this.isRequired = true,
  });

  final String id;
  final String prompt;
  final QuestionType type;
  final List<String>? choices;
  final String? defaultValue;
  final String? Function(String?)? validator;
  final bool isRequired;

  /// Answer storage.
  String? answer;
}

/// Collection of wizard questions organized by section.
class WizardFlow {
  WizardFlow({
    required this.sections,
  });

  final Map<String, List<WizardQuestion>> sections;

  /// Get all questions across all sections.
  List<WizardQuestion> get allQuestions =>
      sections.values.expand((q) => q).toList();

  /// Get answers as a map.
  Map<String, String?> get answers =>
      {for (final q in allQuestions) q.id: q.answer};
}
