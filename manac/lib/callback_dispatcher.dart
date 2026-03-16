import 'package:workmanager/workmanager.dart';
import 'services/sync_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'syncTask':
        await SyncService().autoSync();
        return true;
      default:
        return false;
    }
  });
}
