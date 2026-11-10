import 'package:flutter/material.dart';

import '../models/analysis_result.dart';

/// Affiche un résultat d'analyse : score, résumé, compétences et conseils.
class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score : ${result.score}/100', style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: result.score / 100),
        const SizedBox(height: 16),
        Text(result.summary, style: textTheme.bodyLarge),
        _Section(
          title: 'Compétences présentes',
          items: result.matchedSkills,
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _Section(
          title: 'Compétences manquantes',
          items: result.missingSkills,
          icon: Icons.cancel,
          color: colors.error,
        ),
        _Section(
          title: 'Conseils',
          items: result.advice,
          icon: Icons.lightbulb_outline,
          color: colors.primary,
        ),
      ],
    );
  }
}

/// Un titre suivi d'une liste d'éléments, ou de « Aucune » si la liste est vide.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.icon,
    required this.color,
  });

  final String title;
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (items.isEmpty) const Text('Aucune'),
          for (final item in items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(icon, color: color),
              title: Text(item),
            ),
        ],
      ),
    );
  }
}
