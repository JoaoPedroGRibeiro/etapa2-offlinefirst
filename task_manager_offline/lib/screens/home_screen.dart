import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../services/database_service.dart';
import '../models/task_model.dart';
import '../services/sync_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Task> _tasks = [];
  bool _isOnline = true; 

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadTasks();

    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool isConnected = result != ConnectivityResult.none;
      
      setState(() {
        _isOnline = isConnected;
      });
      
      if (isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conexão restabelecida! Sincronizando...'), backgroundColor: Colors.blue),
        );

        SyncService().syncPendingItems().then((_) {
          _loadTasks(); 
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sincronização concluída!'), backgroundColor: Colors.green),
          );
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    var result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  Future<void> _loadTasks() async {
    final data = await _dbService.getTasks();
    setState(() {
      _tasks = data.map((e) => Task.fromMap(e)).toList();
    });
  }

  void _addNewTask() {
    String title = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Tarefa'),
        content: TextField(
          onChanged: (val) => title = val,
          decoration: const InputDecoration(hintText: "Nome da tarefa"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (title.isNotEmpty) {
                final id = const Uuid().v4(); 
                
                await _dbService.insertTask(id, title);
                
                Navigator.pop(context);
                _loadTasks();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Manager Offline")),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: _isOnline ? Colors.green : Colors.red,
            child: Text(
              _isOnline ? "MODO ONLINE - Sincronizado" : "MODO OFFLINE - Salvando localmente",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.id.substring(0, 8)),
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (val) async {
                      await _dbService.updateTaskStatus(task.id, val ?? false);
                      _loadTasks();
                    },
                  ),
                  trailing: Icon(
                    task.isSynced ? Icons.cloud_done : Icons.cloud_off,
                    color: task.isSynced ? Colors.green : Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        backgroundColor: _isOnline ? Colors.green : Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}