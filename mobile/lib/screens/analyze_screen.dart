import 'package:flutter/material.dart';

import '../models/analysis_result.dart';
import '../services/matcher_api.dart';
import '../widgets/result_view.dart';

/// Les 4 états possibles de l'écran.
///
/// `sealed` : toutes les sous-classes sont dans ce fichier, donc le compilateur
/// vérifie que le `switch` de [_AnalyzeScreenState._buildStateView] les traite toutes.
sealed class AnalysisState {
  const AnalysisState();
}

class AnalysisIdle extends AnalysisState {
  const AnalysisIdle();
}

class AnalysisLoading extends AnalysisState {
  const AnalysisLoading();
}

class AnalysisSuccess extends AnalysisState {
  const AnalysisSuccess(this.result);

  final AnalysisResult result;
}

class AnalysisFailure extends AnalysisState {
  const AnalysisFailure(this.message);

  final String message;
}

/// Écran unique : saisie du CV et de l'offre, puis affichage du résultat.
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key, required this.api});

  final MatcherApi api;

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _cvController = TextEditingController();
  final _offerController = TextEditingController();
  AnalysisState _state = const AnalysisIdle();

  @override
  void dispose() {
    // Les controllers gardent des ressources : on les libère avec l'écran.
    _cvController.dispose();
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final cv = _cvController.text.trim();
    final offer = _offerController.text.trim();

    // Validation locale : inutile d'appeler l'API pour une requête qu'elle refusera.
    if (cv.isEmpty || offer.isEmpty) {
      setState(() {
        _state = const AnalysisFailure("Remplissez le CV et l'offre.");
      });
      return;
    }
    if (cv.length < MatcherApi.minTextLength ||
        offer.length < MatcherApi.minTextLength) {
      setState(() {
        _state = const AnalysisFailure(
          "Le CV et l'offre doivent contenir chacun au moins 50 caractères.",
        );
      });
      return;
    }

    FocusScope.of(context).unfocus(); // ferme le clavier
    setState(() => _state = const AnalysisLoading());

    try {
      final result = await widget.api.analyze(jobOffer: offer, cv: cv);
      // L'utilisateur a pu quitter l'écran pendant l'attente.
      if (!mounted) return;
      setState(() => _state = AnalysisSuccess(result));
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _state = AnalysisFailure(error.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _state is AnalysisLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Alternance Matcher')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const Key('cvField'),
              controller: _cvController,
              enabled: !isLoading,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Ton CV',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('offerField'),
              controller: _offerController,
              enabled: !isLoading,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: "L'offre d'alternance",
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('analyzeButton'),
              // null désactive le bouton : pas de double envoi pendant le chargement
              onPressed: isLoading ? null : _analyze,
              child: const Text('Analyser'),
            ),
            const SizedBox(height: 24),
            _buildStateView(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateView() {
    return switch (_state) {
      AnalysisIdle() => const SizedBox.shrink(),
      AnalysisLoading() => const Center(child: CircularProgressIndicator()),
      AnalysisSuccess(:final result) => ResultView(result: result),
      AnalysisFailure(:final message) => Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(message, key: const Key('errorMessage')),
          ),
        ),
    };
  }
}
