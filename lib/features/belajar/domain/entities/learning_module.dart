class LearningSection {
  const LearningSection({
    required this.heading,
    required this.body,
    required this.points,
  });

  final String heading;
  final String body;
  final List<String> points;
}

class LearningModule {
  const LearningModule({
    required this.slug,
    required this.topic,
    required this.title,
    required this.summary,
    required this.sections,
  });

  final String slug;
  final String topic;
  final String title;
  final String summary;
  final List<LearningSection> sections;
}
