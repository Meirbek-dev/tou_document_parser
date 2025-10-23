import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main.freezed.dart';

void main() {
  runApp(const TouDocumentApp());
}

class TouDocumentApp extends StatelessWidget {
  const TouDocumentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Reception',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => DocumentUploadCubit(),
        child: const DocumentUploaderPage(),
      ),
    );
  }
}

class DocumentUploaderPage extends StatefulWidget {
  const DocumentUploaderPage({super.key});

  @override
  State<DocumentUploaderPage> createState() => _DocumentUploaderPageState();
}

class _DocumentUploaderPageState extends State<DocumentUploaderPage> {
  void pickFiles() {
    final state = context.read<DocumentUploadCubit>().state;

    if (state.name.trim().isEmpty || state.lastName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Пожалуйста, заполните имя и фамилию")),
            ],
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final uploadInput = web.HTMLInputElement();
    uploadInput.type = 'file';
    uploadInput.multiple = true;
    uploadInput.accept = '.pdf,.jpg,.jpeg,.png';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final files = uploadInput.files;
      if (files != null && files.length > 0) {
        final fileList = <web.File>[];
        for (var i = 0; i < files.length; i++) {
          final file = files.item(i);
          if (file != null) {
            fileList.add(file);
          }
        }

        if (fileList.isNotEmpty) {
          final success = await context.read<DocumentUploadCubit>().uploadFiles(
            fileList,
          );

          if (!mounted) return;
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Документы успешно обработаны и классифицированы",
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Ошибка при загрузке файлов. Попробуйте снова.",
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      }
    });
  }

  final nameController = TextEditingController();
  final lastNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.primaryContainer,
        toolbarHeight: 80,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 48),
            const SizedBox(width: 12),
            Text(
              'AI Reception',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ),
      body: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 32,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Информация об абитуриенте',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: nameController,
                                    enabled: !state.isLoading,
                                    decoration: const InputDecoration(
                                      labelText: 'Имя',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                      hintText: 'Введите имя',
                                    ),
                                    onChanged:
                                        (value) => context
                                            .read<DocumentUploadCubit>()
                                            .setName(value),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: lastNameController,
                                    enabled: !state.isLoading,
                                    decoration: const InputDecoration(
                                      labelText: 'Фамилия',
                                      prefixIcon: Icon(Icons.badge_outlined),
                                      hintText: 'Введите фамилию',
                                    ),
                                    onChanged:
                                        (value) => context
                                            .read<DocumentUploadCubit>()
                                            .setLastName(value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    state.isLoading ? null : () => pickFiles(),
                                icon:
                                    state.isLoading
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 24,
                                        ),
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    state.isLoading
                                        ? 'Обработка файлов...'
                                        : 'Загрузить документы',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            if (state.isLoading)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: LinearProgressIndicator(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Files Section
                    if (state.files.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Загруженные документы (${state.files.length})',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          FilledButton.tonalIcon(
                            onPressed:
                                () =>
                                    context
                                        .read<DocumentUploadCubit>()
                                        .downloadAll(),
                            icon: const Icon(Icons.download),
                            label: const Text('Скачать всё'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      buildGroupedByCategory(context, state.files),
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            context.read<DocumentUploadCubit>().reset();
                            nameController.clear();
                            lastNameController.clear();
                          },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Новый абитуриент'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.upload_file_outlined,
                                size: 80,
                                color: colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Нет загруженных документов',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Заполните форму и загрузите документы для классификации',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildGroupedByCategory(BuildContext context, List<UploadedFile> files) {
  final grouped = <String, List<UploadedFile>>{};

  for (var file in files) {
    grouped.putIfAbsent(file.category, () => []).add(file);
  }

  final categoryInfo = {
    "Udostoverenie": CategoryInfo(
      name: "Удостоверение",
      icon: Icons.credit_card,
      color: Colors.blue,
    ),
    "Diplom": CategoryInfo(
      name: "Диплом/Аттестат",
      icon: Icons.school,
      color: Colors.purple,
    ),
    "ENT": CategoryInfo(name: "ЕНТ", icon: Icons.quiz, color: Colors.orange),
    "Lgota": CategoryInfo(
      name: "Льгота",
      icon: Icons.local_offer,
      color: Colors.green,
    ),
    "Unclassified": CategoryInfo(
      name: "Неизвестно",
      icon: Icons.help_outline,
      color: Colors.grey,
    ),
    "Privivka": CategoryInfo(
      name: "Прививочный паспорт",
      icon: Icons.medical_services,
      color: Colors.teal,
    ),
    "MedSpravka": CategoryInfo(
      name: "Медицинская справка",
      icon: Icons.health_and_safety,
      color: Colors.red,
    ),
  };

  final colorScheme = Theme.of(context).colorScheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children:
        grouped.entries.map((entry) {
          final info =
              categoryInfo[entry.key] ??
              CategoryInfo(
                name: entry.key,
                icon: Icons.description,
                color: Colors.grey,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(info.icon, color: info.color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      info.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: info.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value.length}',
                        style: TextStyle(
                          color: info.color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...entry.value.map((file) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: info.color.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: info.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileIcon(file.originalName),
                        color: info.color,
                      ),
                    ),
                    title: Text(
                      file.originalName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle:
                        file.newName != null
                            ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                file.newName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            )
                            : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          onPressed:
                              () => context
                                  .read<DocumentUploadCubit>()
                                  .downloadFile(file),
                          icon: const Icon(Icons.download),
                          tooltip: 'Скачать',
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed:
                              () => context
                                  .read<DocumentUploadCubit>()
                                  .deleteFile(file),
                          icon: const Icon(Icons.delete_outline),
                          style: IconButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.5),
                            ),
                          ),
                          tooltip: 'Удалить',
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
  );
}

IconData _getFileIcon(String filename) {
  final ext = filename.toLowerCase().split('.').last;
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'jpg':
    case 'jpeg':
    case 'png':
      return Icons.image;
    default:
      return Icons.insert_drive_file;
  }
}

class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  CategoryInfo({required this.name, required this.icon, required this.color});
}

@freezed
class DocumentUploadState with _$DocumentUploadState {
  const factory DocumentUploadState({
    required String name,
    required String lastName,
    required List<UploadedFile> files,
    @Default(false) bool isLoading,
  }) = _DocumentUploadState;
}

class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  DocumentUploadCubit()
    : super(const DocumentUploadState(name: '', lastName: '', files: []));

  void setName(String name) => emit(state.copyWith(name: name));

  void setLastName(String lastName) => emit(state.copyWith(lastName: lastName));

  Future<bool> uploadFiles(List<web.File> files) async {
    if (state.isLoading) return false;

    emit(state.copyWith(isLoading: true));

    final completer = Completer<bool>();
    bool isCompleted = false; // Add flag to prevent double completion

    final formData = web.FormData();
    for (final file in files) {
      formData.append('files', file);
    }

    formData.append('name', state.name.toJS);
    formData.append('lastname', state.lastName.toJS);

    final request = web.XMLHttpRequest();
    final origin = web.window.location.origin;
    request.open('POST', '$origin/upload');
    request.responseType = 'json';

    request.addEventListener(
      'loadend',
      (web.Event event) {
        if (isCompleted) return; // Prevent double completion
        isCompleted = true;

        emit(state.copyWith(isLoading: false));

        if (request.status == 200) {
          final response = request.response;
          if (response != null) {
            final responseData = response.dartify();
            if (responseData is List) {
              final uploaded =
                  responseData
                      .map(
                        (item) => UploadedFile.fromJson(
                          Map<String, dynamic>.from(item),
                        ),
                      )
                      .toList();
              emit(state.copyWith(files: [...state.files, ...uploaded]));
              completer.complete(true);
              return;
            }
          }
        }

        debugPrint('Upload failed: ${request.status}');
        completer.complete(false);
      }.toJS,
    );

    request.addEventListener(
      'error',
      (web.Event event) {
        if (isCompleted) return; // Prevent double completion
        isCompleted = true;

        debugPrint('Network error during upload');
        emit(state.copyWith(isLoading: false));
        completer.complete(false);
      }.toJS,
    );

    request.send(formData);

    return completer.future;
  }

  void deleteFile(UploadedFile file) {
    if (file.newName == null) {
      // Просто удалить из UI
      final updated = state.files.where((f) => f != file).toList();
      emit(state.copyWith(files: updated));
      return;
    }

    final origin = web.window.location.origin;
    final url =
        '$origin/delete_file?filename=${Uri.encodeComponent(file.newName!)}';

    final request = web.XMLHttpRequest();
    request.open('DELETE', url);

    request.addEventListener(
      'loadend',
      (web.Event event) {
        if (request.status == 200) {
          final updated =
              state.files.where((f) => f.newName != file.newName).toList();
          emit(state.copyWith(files: updated));
        } else {
          debugPrint('Delete failed: ${request.status}');
        }
      }.toJS,
    );

    request.addEventListener(
      'error',
      (web.Event event) {
        debugPrint('Network error during delete');
      }.toJS,
    );

    request.send();
  }

  void downloadFile(UploadedFile file) {
    if (file.newName != null) {
      final anchor = web.HTMLAnchorElement();
      final origin = web.window.location.origin;
      anchor.href = '$origin/files/${Uri.encodeComponent(file.newName!)}';
      anchor.setAttribute('download', file.newName!);
      anchor.click();
    }
  }

  void downloadAll() {
    final origin = web.window.location.origin;
    final url =
        '$origin/download_zip?name=${Uri.encodeComponent(state.name)}&lastname=${Uri.encodeComponent(state.lastName)}';

    final anchor = web.HTMLAnchorElement();
    anchor.href = url;
    anchor.setAttribute('download', 'documents.zip');
    anchor.click();
  }

  void reset() =>
      emit(const DocumentUploadState(name: '', lastName: '', files: []));
}

class UploadedFile {
  final String originalName;
  final String? newName;
  final String category;

  UploadedFile({
    required this.originalName,
    this.newName,
    required this.category,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      originalName: json['original_name'] as String,
      newName: json['new_name'] as String?,
      category: json['category'] as String,
    );
  }
}
