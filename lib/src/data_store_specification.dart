import 'package:async/async.dart';
import 'package:checks/checks.dart';
import 'package:core_event_source/entry.dart';
import 'package:core_event_source/internal.dart';
import 'package:given_when_then_unit_test/given_when_then_unit_test.dart';

class DataStoreSpecification<DataStore extends CoreDataStore<Event>, Event> {
  final DataStore dataStore;
  final Entry<Event> entry1 = Entry<Event>(
      ref: EntryRefFactory.increment().create(),
      refs: [EntryRef.root],
      createdAt: DateTimeFactory.increment().create(),
      events: []);

  DataStoreSpecification(this.dataStore);

  void evaluate() {
    given('data store - empty', () {
      late InMemoryDataStoreInternal<Event> dataStoreInternal;
      late InMemoryDataStore<Event> dataStore;
      before(() {
        dataStoreInternal = InMemoryDataStoreInternal.from();
        dataStore = InMemoryDataStore(
            headRefId: '1', dataStoreInternal: dataStoreInternal);
      });
      // then('check it fails if initialized', () async {
      //   expect(() => dataStore.initialize(entry1), throwsUnsupportedError);
      // });
      then('check state', () async {
        check(await dataStore.headEntryRef).equals(null);
        check(await dataStore.mainEntryRef).equals(EntryRef.root);
        check(await dataStore.mainEntryRefMaybe).equals(EntryRef.root);
        check((await dataStore.rootEntry).ref).equals(EntryRef.root);
        final rootEntrySnapshot =
            (await dataStore.entrySnapshotsStream.take(1).toList())
                .first
                .single;
        check(rootEntrySnapshot.entry.ref).equals(EntryRef.root);
      });
      when2('add entry', () async => dataStore.appendHeadEntry(entry1),
          then: () {
        then('check state and entry collection stream', () async {
          check(await dataStore.headEntryRef).equals(entry1.ref);
          final entrySnapshots =
              (await dataStore.entrySnapshotsStream.take(3).toList()).skip(1);

          check(entrySnapshots.length).equals(2);
          check(entrySnapshots.first.single.entry).equals(entry1);
          check(entrySnapshots.first.single.isPending).equals(true);
          check(entrySnapshots.last.single.entry).equals(entry1);
          check(entrySnapshots.last.single.isPending).equals(false);
        });
      });
      when2(
          'add snapshots',
          () async => dataStore
              .addEntrySnapshots([EntrySnapshot(entry1, isPending: false)]),
          then: () {
        then('check state and entry collection stream', () async {
          check(await dataStore.headEntryRef).equals(null);
          final entrySnapshots =
              (await dataStore.entrySnapshotsStream.take(2).toList()).last;
          check(entrySnapshots.length).equals(1);
          check(entrySnapshots.single.entry).equals(entry1);
          check(entrySnapshots.single.isPending).equals(false);
        });
      });
      when2(
          'set mainEntryRef', () async => dataStore.setMainEntryRef(entry1.ref),
          then: () {
        then('check state and entry collection stream', () async {
          await (check(StreamQueue(dataStore.mainEntryRefStream))).inOrder([
            it()..emits(),
            it()..emits(),
          ]);
        });
      });
      when2('forward head ref',
          () async => dataStore.forwardHeadEntryRef(EntryRef.root, entry1.ref),
          then: () {
        then('check state and entry collection stream', () async {
          check(await dataStore.headEntryRef).equals(entry1.ref);
        });
      });
      when2('reset head ref',
          () async => dataStore.resetHeadEntryRef(EntryRef.root, entry1.ref),
          then: () {
        then('check state and entry collection stream', () async {
          check(await dataStore.headEntryRef).equals(entry1.ref);
        });
      });
      when2('update main ref ',
          () async => dataStore.updateMainEntryRef(EntryRef.root, entry1.ref),
          then: () {
        then('check state and entry collection stream', () async {
          check(await dataStore.mainEntryRef).equals(entry1.ref);
        });
      });
    });
    given('data store - one entry', () {
      late InMemoryDataStoreInternal<Event> dataStoreInternal;
      late InMemoryDataStore<Event> dataStore;
      before(() {
        dataStoreInternal = InMemoryDataStoreInternal.from(
          entryCollectionSnapshots: [EntrySnapshot(entry1, isPending: true)],
          mainEntryRef: entry1.ref,
        );
        dataStore = InMemoryDataStore(
            headRefId: '1', dataStoreInternal: dataStoreInternal);
      });
      then('check state', () async {
        check(await dataStore.headEntryRef).equals(null);
        check(await dataStore.mainEntryRef).equals(entry1.ref);
        check(await dataStore.mainEntryRefMaybe).equals(entry1.ref);
        check((await dataStore.rootEntry).ref).equals(EntryRef.root);
        final rootEntrySnapshot =
            (await dataStore.entrySnapshotsStream.first).last;
        check(rootEntrySnapshot.entry).equals(entry1);
      });
    });
  }
}

void main() {
  // initializeDebugLogging();
}
