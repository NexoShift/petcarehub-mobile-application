import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../iam/application/iam_store.dart';
import '../profiles/application/profiles_store.dart';
import '../shared/domain/api_error.dart';
import '../shared/presentation/theme/app_colors.dart';

/// Pantalla de carga mientras se sabe quién es el usuario:
/// 1. restaura la sesión guardada (IAM);
/// 2. si hay sesión, carga su perfil (Profiles).
/// El router decide a dónde ir cuando cambian los stores.
class BootView extends StatefulWidget {
  const BootView({super.key});

  @override
  State<BootView> createState() => _BootViewState();
}

class _BootViewState extends State<BootView> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final iam = context.read<IamStore>();
    final profiles = context.read<ProfilesStore>();
    try {
      if (iam.status == AuthStatus.unknown) await iam.restoreSession();
      final session = iam.session;
      if (session != null && profiles.status == ProfileStatus.unknown) {
        await profiles.loadFor(session);
      }
    } on ApiError catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset('assets/images/logo-petcarehub.png', height: 64),
              ),
              const SizedBox(height: 32),
              if (_error == null)
                const CircularProgressIndicator(color: AppColors.turquoise)
              else ...[
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Reintentar')),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  onPressed: () => context.read<IamStore>().signOut(),
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
