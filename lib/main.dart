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
      title: 'TOU Document',
      theme: ThemeData(primarySwatch: Colors.indigo),
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
        const SnackBar(
          content: Text("Пожалуйста, заполните имя и фамилию"),
          backgroundColor: Colors.redAccent,
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
              const SnackBar(
                content: Text("Документ(ы) успешно обработаны"),
                backgroundColor: Colors.green,
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white30,
        toolbarHeight: 80,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 48),
            const SizedBox(width: 12),
            const Text('TOU Documents'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
          builder: (context, state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Имя'),
                    onChanged:
                        (value) =>
                            context.read<DocumentUploadCubit>().setName(value),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Фамилия'),
                    onChanged:
                        (value) => context
                            .read<DocumentUploadCubit>()
                            .setLastName(value),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: state.isLoading ? null : () => pickFiles(),
                    icon:
                        state.isLoading
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.upload_file),
                    label: Text(
                      state.isLoading ? 'Загрузка...' : 'Загрузить документы',
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildGroupedByCategory(context, state.files),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            () =>
                                context
                                    .read<DocumentUploadCubit>()
                                    .downloadAll(),
                        icon: const Icon(Icons.archive),
                        label: const Text('Скачать всё'),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          context.read<DocumentUploadCubit>().reset();
                          nameController.clear();
                          lastNameController.clear();
                        },

                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Новый абитуриент'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget buildGroupedByCategory(BuildContext context, List<UploadedFile> files) {
  final grouped = <String, List<UploadedFile>>{};

  for (var file in files) {
    grouped.putIfAbsent(file.category, () => []).add(file);
  }

  final categoryNames = {
    "Udostoverenie": "Удостоверение",
    "Diplom": "Диплом/Аттестат",
    "ENT": "ЕНТ",
    "Lgota": "Льгота",
    "Unclassified": "Неизвестно",
    "Privivka": "Прививочный паспорт",
    "MedSpravka": "Медицинская справка",
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children:
        grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                categoryNames[entry.key] ?? entry.key,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),
              ...entry.value.map((file) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    title: Text(file.originalName),
                    subtitle: Text(file.newName ?? ''),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed:
                              () => context
                                  .read<DocumentUploadCubit>()
                                  .downloadFile(file),
                          child: const Text("Скачать"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              () => context
                                  .read<DocumentUploadCubit>()
                                  .deleteFile(file),
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
    request.open('POST', 'http://127.0.0.1:5040/upload');
    request.responseType = 'json';

    request.addEventListener('loadend', (web.Event event) {
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
                      (item) =>
                          UploadedFile.fromJson(Map<String, dynamic>.from(item)),
                    )
                    .toList();
            emit(state.copyWith(files: [...state.files, ...uploaded]));
            completer.complete(true);
            return;
          }
        }
      }

      print('Upload failed: ${request.status}');
      completer.complete(false);
    }.toJS);

    request.addEventListener('error', (web.Event event) {
      if (isCompleted) return; // Prevent double completion
      isCompleted = true;

      print('Network error');
      emit(state.copyWith(isLoading: false));
      completer.complete(false);
    }.toJS);

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

    final url = 'http://127.0.0.1:5040/delete_file?filename=${Uri.encodeComponent(file.newName!)}';

    final request = web.XMLHttpRequest();
    request.open('DELETE', url);

    request.addEventListener('loadend', (web.Event event) {
      if (request.status == 200) {
        final updated =
            state.files.where((f) => f.newName != file.newName).toList();
        emit(state.copyWith(files: updated));
      } else {
        print('Delete failed: ${request.status}');
      }
    }.toJS);

    request.addEventListener('error', (web.Event event) {
      print('Delete failed');
    }.toJS);

    request.send();
  }

  void downloadFile(UploadedFile file) {
    if (file.newName != null) {
      final anchor = web.HTMLAnchorElement();
      anchor.href = 'http://127.0.0.1:5040/files/${file.newName}';
      anchor.setAttribute('download', file.newName!);
      anchor.click();
    }
  }

  void downloadAll() {
    final url = 'http://127.0.0.1:5040/download_zip?name=${state.name}&lastname=${state.lastName}';

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
