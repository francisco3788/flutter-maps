import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/supabase_client.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

class AuthController extends AsyncNotifier<User?> {
  StreamSubscription<AuthState>? _sub;

  @override
  Future<User?> build() async {
    final client = ref.read(supabaseClientProvider);
    _listenToAuthChanges(client);
    final current = client.auth.currentUser;
    if (current != null) {
      return current;
    }
    final response = await client.auth.signInAnonymously();
    return response.user;
  }

  Future<User?> refreshSession() async {
    state = const AsyncLoading();
    final client = ref.read(supabaseClientProvider);
    final response = await AsyncValue.guard(
      () async => (await client.auth.signInAnonymously()).user,
    );
    state = response;
    return response.value;
  }

  void _listenToAuthChanges(SupabaseClient client) {
    _sub ??= client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = AsyncValue.data(user);
    });
    ref.onDispose(() => _sub?.cancel());
  }
}
