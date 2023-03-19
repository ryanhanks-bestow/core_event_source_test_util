An event sourcing library for Flutter, powered by Bloc.

Supports durable, real-time syncing across devices.

Currently works with Firebase Firestore via [flutter_core_event_source](../flutter_core_event_source).

## Getting Started
```dart
run() async {
  // The EventStore writes to Firebase using a document path.
  final path = 'users/$userId/objects/1';
  // Safe to share across devices
  final sourceReference = EventStore.instance
      .source(path: path, converter: ExampleEventJsonConverter());
  
  // Only write to a head reference from one device at a time
  final referenceId = deviceId;
  final headReference = sourceReference.head(referenceId: referenceId);
  
  // Execute commands and inspect / stream View from here
  final source = await headReference.get(ExampleBehavior());

  assert(source.state == 0);

  final first = source.stream.first;

  source.execute({'incrementValue': 1});

  final result = await first;

  assert(result == 1);
  assert(source.state == 1);
}
```
