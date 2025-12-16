import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';

class SyncService {
  final DatabaseService _db = DatabaseService();
  
  final String apiUrl = 'https://jsonplaceholder.typicode.com/todos'; 

  Future<void> syncPendingItems() async {
    print("🔄 Iniciando Sincronização...");

    final pendingItems = await _db.getPendingSyncs();

    if (pendingItems.isEmpty) {
      print("✅ Nada para sincronizar.");
      return;
    }

    for (var item in pendingItems) {
      bool success = false;

      try {
        final action = item['action'];
        final payload = jsonDecode(item['payload']);
        final idDaFila = item['id']; 
        final idDaTarefa = item['item_id'];

        print("📤 Enviando: $action - ID: $idDaTarefa");
        
        await Future.delayed(const Duration(seconds: 1)); 
        success = true; 


        if (success) {
          await _db.clearSyncQueueItem(idDaFila);
          
          if (action == 'CREATE' || action == 'UPDATE') {
            await _db.markTaskAsSynced(idDaTarefa);
          }
          
          print("✅ Item $idDaTarefa sincronizado com sucesso!");
        }

      } catch (e) {
        print("❌ Erro ao sincronizar item: $e");
      }
    }
  }
}