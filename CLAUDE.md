# CLAUDE.md - Flutter Caravan App Guidelines

## Commands
- Run app: `flutter run`
- Test all: `flutter test`
- Test single: `flutter test test/widget_test.dart`
- Test specific: `flutter test --name="test name"`
- Analyze: `flutter analyze`
- Format: `flutter format lib/`
- Dependencies: `flutter pub get`, `flutter pub upgrade`

## Code Style
- **Imports**: Flutter first, third-party next, project imports last
- **Models**: Use suffix "Model", implement fromMap/toMap
- **Providers**: Use ChangeNotifier, implement proper state management
- **Naming**: PascalCase for classes, camelCase for methods/variables
- **Types**: Use strong typing with null safety (String?, required)
- **Privacy**: Prefix private members with underscore (_variable)
- **Error Handling**: Try/catch for async, provide user-friendly messages
- **Organization**: Maintain folder structure (models, providers, screens, widgets)
- **State**: Notify listeners after state changes, use immutable data when possible