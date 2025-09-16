import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resource types that need cleanup
enum ResourceType {
  locationStream,
  cameraController,
  databaseConnection,
  fileWatcher,
  networkListener,
  backgroundTask,
}

/// Resource info
class ResourceInfo {
  const ResourceInfo({
    required this.type,
    required this.id,
    required this.dispose,
    this.description,
  });

  final ResourceType type;
  final String id;
  final Future<void> Function() dispose;
  final String? description;
}

/// Resource state
class ResourceState {
  const ResourceState({
    this.activeResources = const {},
    this.disposedResources = const {},
  });

  final Map<String, ResourceInfo> activeResources;
  final Set<String> disposedResources;

  ResourceState copyWith({
    Map<String, ResourceInfo>? activeResources,
    Set<String>? disposedResources,
  }) {
    return ResourceState(
      activeResources: activeResources ?? this.activeResources,
      disposedResources: disposedResources ?? this.disposedResources,
    );
  }

  int getResourceCount(ResourceType type) {
    return activeResources.values
        .where((resource) => resource.type == type)
        .length;
  }

  List<ResourceInfo> getResourcesByType(ResourceType type) {
    return activeResources.values
        .where((resource) => resource.type == type)
        .toList();
  }
}

/// Resource notifier
class ResourceNotifier extends StateNotifier<ResourceState> {
  ResourceNotifier() : super(const ResourceState());

  final List<StreamSubscription> _subscriptions = [];

  void registerResource(ResourceInfo resource) {
    final updatedResources = {...state.activeResources};
    updatedResources[resource.id] = resource;
    
    state = state.copyWith(activeResources: updatedResources);
  }

  Future<void> disposeResource(String resourceId) async {
    final resource = state.activeResources[resourceId];
    if (resource == null) return;

    try {
      await resource.dispose();
      
      final updatedResources = {...state.activeResources}..remove(resourceId);
      final updatedDisposed = {...state.disposedResources, resourceId};
      
      state = state.copyWith(
        activeResources: updatedResources,
        disposedResources: updatedDisposed,
      );
    } catch (e) {
      // Log error but continue cleanup
      print('Error disposing resource $resourceId: $e');
    }
  }

  Future<void> disposeResourcesByType(ResourceType type) async {
    final resourcesToDispose = state.activeResources.values
        .where((resource) => resource.type == type)
        .toList();

    for (final resource in resourcesToDispose) {
      await disposeResource(resource.id);
    }
  }

  Future<void> disposeAllResources() async {
    final resourceIds = state.activeResources.keys.toList();
    
    for (final resourceId in resourceIds) {
      await disposeResource(resourceId);
    }
  }

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // Dispose all resources
    disposeAllResources();
    
    super.dispose();
  }
}

/// Provider for resource management
final resourceProvider = StateNotifierProvider<ResourceNotifier, ResourceState>((ref) {
  return ResourceNotifier();
});

/// Resource manager utility
class ResourceManager {
  static void registerLocationStream(
    WidgetRef ref,
    StreamSubscription subscription,
    String streamId,
  ) {
    final resourceNotifier = ref.read(resourceProvider.notifier);
    
    resourceNotifier.registerResource(
      ResourceInfo(
        type: ResourceType.locationStream,
        id: streamId,
        dispose: () async => subscription.cancel(),
        description: 'Location stream subscription',
      ),
    );
    
    resourceNotifier.addSubscription(subscription);
  }

  static void registerCameraController(
    WidgetRef ref,
    dynamic cameraController,
    String controllerId,
  ) {
    final resourceNotifier = ref.read(resourceProvider.notifier);
    
    resourceNotifier.registerResource(
      ResourceInfo(
        type: ResourceType.cameraController,
        id: controllerId,
        dispose: () async {
          if (cameraController != null) {
            await cameraController.dispose();
          }
        },
        description: 'Camera controller',
      ),
    );
  }

  static void registerDatabaseConnection(
    WidgetRef ref,
    dynamic database,
    String connectionId,
  ) {
    final resourceNotifier = ref.read(resourceProvider.notifier);
    
    resourceNotifier.registerResource(
      ResourceInfo(
        type: ResourceType.databaseConnection,
        id: connectionId,
        dispose: () async {
          if (database != null) {
            await database.close();
          }
        },
        description: 'Database connection',
      ),
    );
  }

  static void registerBackgroundTask(
    WidgetRef ref,
    Timer timer,
    String taskId,
  ) {
    final resourceNotifier = ref.read(resourceProvider.notifier);
    
    resourceNotifier.registerResource(
      ResourceInfo(
        type: ResourceType.backgroundTask,
        id: taskId,
        dispose: () async => timer.cancel(),
        description: 'Background task timer',
      ),
    );
  }

  static Future<void> disposeResource(WidgetRef ref, String resourceId) async {
    await ref.read(resourceProvider.notifier).disposeResource(resourceId);
  }

  static Future<void> disposeResourcesByType(WidgetRef ref, ResourceType type) async {
    await ref.read(resourceProvider.notifier).disposeResourcesByType(type);
  }

  static Future<void> disposeAllResources(WidgetRef ref) async {
    await ref.read(resourceProvider.notifier).disposeAllResources();
  }
}

/// Provider for resource counts by type
final resourceCountProvider = Provider.family<int, ResourceType>((ref, type) {
  return ref.watch(resourceProvider).getResourceCount(type);
});

/// Provider for total active resources
final totalActiveResourcesProvider = Provider<int>((ref) {
  return ref.watch(resourceProvider).activeResources.length;
});