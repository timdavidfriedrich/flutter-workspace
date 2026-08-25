# Data Models, Mappers & Network

*Requires `SKILL.md`.*

## Three Model Types, Always

| Type | When | Location |
|---|---|---|
| `Task` (entity) | always | `shared/domain/entities/` |
| `LocalTask` | entity is persisted | `data/models/` in the data source's package |
| `RemoteTask` | entity goes over the network | `data/models/` in the data source's package |
| `task_mappers.dart` | always | `data/mappers/` in the same package |

Data sources go in `data/data_sources/`, repository implementations in
`data/repositories/`, their interfaces in `domain/repositories/`.

Wire concerns (deviating keys, case style, nullable-everything) stay in the `Remote` model, persistence concerns in the `Local` model.

## Models & Parsing
No Freezed — `dart_mappable`, with **public** named `required` parameters — mappers read these fields from another file, so private named parameters are not usable here (`SKILL.md`). The `part` directive on `<name>.mapper.dart` is mandatory.
```dart
import 'package:dart_mappable/dart_mappable.dart';

part 'remote_task.mapper.dart';

@MappableClass()
class const RemoteTask({
  required final String id,
  required final String title,
  required final String status,
}) with RemoteTaskMappable;
```

## Mappers
One file per entity. Extension named after the **source** type, method after the **target** type. Only the directions actually used.
```dart
extension RemoteTaskMappers on RemoteTask {
  Task toTask() {
    return Task(
      id: id,
      title: title,
      status: status.toTaskStatus(),
    );
  }
}

extension TaskMappers on Task {
  RemoteTask toRemoteTask() {
    return RemoteTask(
      id: id,
      title: title,
      status: status.value,
    );
  }
}
```
- Always a full constructor call with all fields, so a new field breaks every mapper at compile time.
- Structural mismatches (envelope, flat ↔ nested) are resolved in the mapper — same file, same naming convention.
- **Mappers are called only in repository implementations.** Data sources return `Local*`/`Remote*`, repositories return entities; above the repository boundary only entities exist.

## Enums
The domain enum does not know the wire format — the `Remote` model holds it as `String`, the conversion lives in the mapper file. Every server-side enum has an `unknown` case; never throw, never return nullable. The UI handles `unknown` in its exhaustive `switch`.
```dart
@MappableEnum()
enum TaskStatus { open, inProgress, done, unknown }
```
Wire values as top-level private `const` at the top of the mapper file, so every literal exists exactly once. Never match via `name`.
```dart
const _statusOpen = "open";
const _statusInProgress = "in_progress";
const _statusDone = "done";
const _statusUnknown = "unknown";

extension TaskStatusValueMappers on String {
  TaskStatus toTaskStatus() => switch (this) {
    _statusOpen => TaskStatus.open,
    _statusInProgress => TaskStatus.inProgress,
    _statusDone => TaskStatus.done,
    _ => TaskStatus.unknown,
  };
}

extension TaskStatusMappers on TaskStatus {
  String get value => switch (this) {
    TaskStatus.open => _statusOpen,
    TaskStatus.inProgress => _statusInProgress,
    TaskStatus.done => _statusDone,
    TaskStatus.unknown => _statusUnknown,
  };
}
```

## Nullability
Entity fields are non-nullable unless absence is a valid domain state. The `Remote` model mirrors the wire format including nullables.
- **Mappers are total** — they always return the entity, never `AppResult`, and resolve missing values with a default or the `unknown` case.
- If a value is mandatory and can still be missing, the repository implementation checks before mapping:
  ```dart
  if (remote.title == null) return const Failure(ValidationError());
  return Success(remote.toTask());
  ```
- Above the mapper no `?` is needed, and `!` never — unwrap via pattern matching.

## HTTP Client
`dio`, setup and interceptors in `core/network/`.
