import 'package:flutter/material.dart';
import 'package:water_it/l10n/app_localizations.dart';

class PlantListPage extends StatelessWidget {
  const PlantListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings?.multiLanguage ?? 'Water It'),
      ),
      body: const Center(
        child: Text(
          'Plant list will appear here. Hook up use cases to render stored plants.',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Wire to add-plant flow.
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
