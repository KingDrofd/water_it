# Water It

Personal plant companion app.

## Architecture
- Clean Architecture layers per feature (`features/plants`): domain (entities, repositories, use cases), data (models, SQLite data source, repository impl), presentation (screens).
- Localization kept via Flutter gen-l10n (`lib/l10n`).
- SQLite for fast local storage (`sqflite`), ready to grow with image storage and future plant-detection integration.

