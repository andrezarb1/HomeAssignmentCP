import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>('tasks');

  await NotificationService.init();

  runApp(const SnapTaskApp());
}

class SnapTaskApp extends StatelessWidget {
  const SnapTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnapTask Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late final Box<Task> _taskBox;

  @override
  void initState() {
    super.initState();
    _taskBox = Hive.box<Task>('tasks');
  }

  void _addTask(Task task) {
    _taskBox.put(task.id, task);
    setState(() {});
  }

  void _toggleDone(Task task) {
    task.isDone = !task.isDone;
    task.save();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _taskBox.values.toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SnapTask Reminder'),
        actions: [
          if (tasks.isNotEmpty)
            IconButton(
              tooltip: 'Clear all tasks',
              onPressed: () async {
                await _taskBox.clear();
                await NotificationService.cancelAll();
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(
              child: Text(
                'No tasks yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = tasks[index];

                final subtitleLines = <String>[];
                if (task.notes != null && task.notes!.trim().isNotEmpty) {
                  subtitleLines.add(task.notes!.trim());
                }
                if (task.locationLabel != null &&
                    task.locationLabel!.trim().isNotEmpty) {
                  subtitleLines.add('Location: ${task.locationLabel}');
                }

                return ListTile(
                  tileColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  leading: IconButton(
                    icon: Icon(
                      task.isDone
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    onPressed: () => _toggleDone(task),
                  ),
                  title: Text(
                    task.title,
                    style: TextStyle(
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: subtitleLines.isEmpty
                      ? null
                      : Text(subtitleLines.join('\n')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push<Task?>(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );

          if (created != null) {
            _addTask(created);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  double? _lat;
  double? _lng;
  String? _locationLabel;
  bool _gettingLocation = false;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addLocation() async {
    setState(() => _gettingLocation = true);

    try {
      final pos = await LocationService.getCurrentPosition();
      final label = await LocationService.reverseGeocode(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _locationLabel = label ?? 'Location saved';
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_locationLabel!)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      notes: notes.isEmpty ? null : notes,

      // Save GPS fields into the Task
      latitude: _lat,
      longitude: _lng,
      locationLabel: _locationLabel,
    );

    // Instant notification (on save)
    await NotificationService.showNow(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Task Saved',
      body: 'Task created: $title',
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),

            const SizedBox(height: 12),

            // GPS row
            Row(
              children: [
                Expanded(
                  child: Text(
                    _locationLabel == null
                        ? 'No location saved'
                        : 'Location: $_locationLabel',
                  ),
                ),
                TextButton.icon(
                  onPressed: _gettingLocation ? null : _addLocation,
                  icon: _gettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _gettingLocation ? 'Getting...' : 'Add Location (GPS)',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final locationText =
        (task.locationLabel == null || task.locationLabel!.trim().isEmpty)
        ? 'Not saved'
        : task.locationLabel!.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Created: ${task.createdAt}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Location: $locationText',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  task.notes ?? 'No notes added.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
