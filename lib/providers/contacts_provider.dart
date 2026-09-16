import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../services/storage_service.dart';
import 'settings_provider.dart';

class ContactsNotifier extends StateNotifier<List<Contact>> {
  final StorageService _storage;

  ContactsNotifier(this._storage) : super(_storage.getContacts());

  Future<void> addContact(Contact contact) async {
    final newList = [...state, contact];
    await _storage.saveContacts(newList);
    state = newList;
  }

  Future<void> updateContact(Contact contact) async {
    final newList = state.map((c) => c.id == contact.id ? contact : c).toList();
    await _storage.saveContacts(newList);
    state = newList;
  }

  Future<void> deleteContact(String id) async {
    final newList = state.where((c) => c.id != id).toList();
    await _storage.saveContacts(newList);
    state = newList;
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, List<Contact>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ContactsNotifier(storage);
});
