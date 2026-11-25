import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../iam/application/iam_store.dart';
import 'owner_dashboard_view.dart';
import 'vet_dashboard_view.dart';

/// Pestaña "Inicio": el dashboard depende del rol.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<IamStore>().session?.isPetOwner ?? false;
    return isOwner ? const OwnerDashboardView() : const VetDashboardView();
  }
}
