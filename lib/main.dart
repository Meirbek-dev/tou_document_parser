import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main.freezed.dart';

// Small centralized strings map for future i18n
const Map<String, String> strings = {
  'appTitle': 'AI Reception',
  'appHeader': 'Информация об абитуриенте',
  'nameLabel': 'Имя',
  'lastNameLabel': 'Фамилия',
  'uploadBtn': 'Загрузить документы',
  'uploading': 'Обработка файлов...',
  'uploadSuccess': 'Документы успешно обработаны и классифицированы',
  'uploadFail': 'Ошибка при загрузке файлов. Попробуйте снова.',
  'noFiles': 'Нет загруженных документов',
};

// Helper to centralize backend origin logic
String getBackendOrigin() {
  if (!kIsWeb) return '';
  final host = web.window.location.hostname;
  final port = web.window.location.port;
  return (host == 'localhost' || host == '127.0.0.1') && port != '5040'
      ? 'http://localhost:5040'
      : web.window.location.origin;
}

// Theme controllers (top-level so UI can listen)
final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

void main() {
  runApp(const TouDocumentApp());
}

class TouDocumentApp extends StatelessWidget {
  const TouDocumentApp({super.key});

  ThemeData _baseTheme(ColorScheme scheme) => ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeNotifier,
      builder: (context, mode, _) {
        final lightScheme = ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        );
        final darkScheme = ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        );

        return MaterialApp(
          title: 'AI Reception',
          theme: _baseTheme(lightScheme),
          darkTheme: _baseTheme(darkScheme),
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: BlocProvider(
            create: (_) => DocumentUploadCubit(),
            child: const DocumentUploaderPage(),
          ),
        );
      },
    );
  }
}

class DocumentUploaderPage extends StatefulWidget {
  const DocumentUploaderPage({super.key});

  @override
  State<DocumentUploaderPage> createState() => _DocumentUploaderPageState();
}

class _DocumentUploaderPageState extends State<DocumentUploaderPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final lastNameController = TextEditingController();

  // Selection for bulk actions (use originalName as identifier)
  final Set<String> _selected = <String>{};

  // Focus nodes for keyboard accessibility
  late final FocusNode _nameFocus;
  late final FocusNode _lastFocus;

  // Page-level drag indicator (web)
  bool _dragActive = false;

  // Upload card hover state for micro-interactions
  bool _uploadHover = false;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _lastFocus = FocusNode();

    if (kIsWeb) {
      // page-level drag listeners for web
      web.window.addEventListener(
        'dragover',
        (web.Event event) {
          try {
            event.preventDefault();
          } catch (_) {}
          if (!mounted) return;
          setState(() => _dragActive = true);
        }.toJS,
      );

      web.window.addEventListener(
        'dragleave',
        (web.Event event) {
          if (!mounted) return;
          setState(() => _dragActive = false);
        }.toJS,
      );

      web.window.addEventListener(
        'drop',
        (web.Event event) {
          try {
            event.preventDefault();
          } catch (_) {}
          if (!mounted) return;
          setState(() => _dragActive = false);

          final dt = (event as dynamic).dataTransfer;
          if (dt != null) {
            final files = dt.files;
            if (files != null && (files as dynamic).length > 0) {
              final fileList = <web.File>[];
              final len = (files as dynamic).length as int;
              for (var i = 0; i < len; i++) {
                final f = (files as dynamic).item(i);
                if (f != null) fileList.add(f as web.File);
              }
              // gentle haptic cue on accepted drop
              HapticFeedback.selectionClick();
              // call upload but don't await inside event handler
              context.read<DocumentUploadCubit>().uploadFiles(fileList);
            }
          }
        }.toJS,
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    lastNameController.dispose();
    _nameFocus.dispose();
    _lastFocus.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    final name = nameController.text.trim();
    final last = lastNameController.text.trim();
    if (name.length < 2 || last.length < 2) return false;
    final noDigits = RegExp(r'^[^0-9]+$');
    return noDigits.hasMatch(name) && noDigits.hasMatch(last);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _toggleSelectAll(List<UploadedFile> files) {
    setState(() {
      final allIds = files.map((f) => f.originalName).toSet();
      if (_selected.containsAll(allIds) && allIds.isNotEmpty) {
        _selected.clear();
      } else {
        _selected.addAll(allIds);
      }
    });
  }

  void pickFiles() {
    final cubit = context.read<DocumentUploadCubit>();
    final state = cubit.state;
    if (state.isLoading) return;

    final uploadInput = web.HTMLInputElement();
    uploadInput.type = 'file';
    uploadInput.multiple = true;
    uploadInput.accept = '.pdf,.jpg,.jpeg,.png';
    uploadInput.click();

    uploadInput.onChange.listen((_) async {
      final files = uploadInput.files;
      if (files != null && files.length > 0) {
        final fileList = <web.File>[];
        final len = files.length;
        for (var i = 0; i < len; i++) {
          final f = files.item(i);
          if (f != null) fileList.add(f);
        }
        HapticFeedback.selectionClick();
        await cubit.uploadFiles(fileList);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<DocumentUploadCubit, DocumentUploadState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final logoAsset =
            isDark ? 'assets/logo_light.png' : 'assets/logo_dark.png';

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  logoAsset,
                  height: 36,
                  errorBuilder: (ctx, error, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                Text(strings['appTitle']!),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Переключить тему',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed:
                    () =>
                        _themeModeNotifier.value =
                            isDark ? ThemeMode.light : ThemeMode.dark,
              ),
            ],
          ),
          body: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Applicant info card
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 28,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      strings['appHeader']!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextFormField(
                                              controller: nameController,
                                              enabled: !state.isLoading,
                                              decoration: InputDecoration(
                                                labelText: strings['nameLabel'],
                                                prefixIcon: const Icon(
                                                  Icons.person,
                                                ),
                                              ),
                                              validator: (value) {
                                                final v = value?.trim() ?? '';
                                                if (v.isEmpty) {
                                                  return 'Имя обязательно';
                                                }
                                                if (v.length < 2) {
                                                  return 'Слишком короткое имя';
                                                }
                                                if (RegExp(
                                                  r'[0-9]',
                                                ).hasMatch(v)) {
                                                  return 'Имя не должно содержать цифр';
                                                }
                                                return null;
                                              },
                                              onChanged:
                                                  (v) => context
                                                      .read<
                                                        DocumentUploadCubit
                                                      >()
                                                      .setName(v),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextFormField(
                                              controller: lastNameController,
                                              enabled: !state.isLoading,
                                              decoration: InputDecoration(
                                                labelText:
                                                    strings['lastNameLabel'],
                                                prefixIcon: const Icon(
                                                  Icons.person_2,
                                                ),
                                              ),
                                              validator: (value) {
                                                final v = value?.trim() ?? '';
                                                if (v.isEmpty) {
                                                  return 'Фамилия обязательна';
                                                }
                                                if (v.length < 2) {
                                                  return 'Слишком коротая фамилия';
                                                }
                                                if (RegExp(
                                                  r'[0-9]',
                                                ).hasMatch(v)) {
                                                  return 'Фамилия не должна содержать цифр';
                                                }
                                                return null;
                                              },
                                              onChanged:
                                                  (v) => context
                                                      .read<
                                                        DocumentUploadCubit
                                                      >()
                                                      .setLastName(v),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: FilledButton.icon(
                                              onPressed:
                                                  (state.isLoading ||
                                                          !_isFormValid())
                                                      ? null
                                                      : () => pickFiles(),
                                              icon:
                                                  state.isLoading
                                                      ? const SizedBox(
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                      : const Icon(
                                                        Icons
                                                            .cloud_upload_outlined,
                                                      ),
                                              label: Text(
                                                state.isLoading
                                                    ? strings['uploading']!
                                                    : strings['uploadBtn']!,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              context
                                                  .read<DocumentUploadCubit>()
                                                  .reset();
                                              nameController.clear();
                                              lastNameController.clear();
                                            },
                                            icon: const Icon(Icons.restart_alt),
                                            label: const Text('Новый'),
                                          ),
                                        ],
                                      ),
                                      if (state.isLoading) ...[
                                        const SizedBox(height: 12),
                                        LinearProgressIndicator(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Upload card
                        MouseRegion(
                          onEnter: (_) => setState(() => _uploadHover = true),
                          onExit: (_) => setState(() => _uploadHover = false),
                          child: AnimatedScale(
                            scale: _uploadHover ? 1.01 : 1.0,
                            duration: const Duration(milliseconds: 140),
                            child: Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => pickFiles(),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  constraints: const BoxConstraints(
                                    minHeight: 160,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 48,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Перетащите или нажмите, чтобы выбрать файлы',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.86),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Поддерживаемые форматы: PDF, JPG, PNG',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 10),
                                      FilledButton.tonalIcon(
                                        onPressed:
                                            (state.isLoading || !_isFormValid())
                                                ? null
                                                : () => pickFiles(),
                                        icon: const Icon(
                                          Icons.file_upload_outlined,
                                        ),
                                        label: const Text('Выбрать файлы'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Files list / empty state
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          child:
                              state.files.isEmpty
                                  ? Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(28.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.folder_open_outlined,
                                            size: 56,
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.28),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            strings['noFiles']!,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Заполните форму и загрузите документы для автоматической классификации.',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Checkbox(
                                                value:
                                                    _selected.isNotEmpty &&
                                                    _selected.length ==
                                                        state.files.length,
                                                onChanged:
                                                    (_) => _toggleSelectAll(
                                                      state.files,
                                                    ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Загруженные документы (${state.files.length})',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              FilledButton.tonalIcon(
                                                onPressed:
                                                    () =>
                                                        context
                                                            .read<
                                                              DocumentUploadCubit
                                                            >()
                                                            .downloadAll(),
                                                icon: const Icon(
                                                  Icons.download,
                                                ),
                                                label: const Text(
                                                  'Скачать всё',
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              FilledButton.tonalIcon(
                                                onPressed:
                                                    _selected.isNotEmpty
                                                        ? () async {
                                                          final idsToDelete =
                                                              _selected
                                                                  .toList();
                                                          final filesToDelete =
                                                              idsToDelete
                                                                  .map(
                                                                    (
                                                                      id,
                                                                    ) => state
                                                                        .files
                                                                        .firstWhere(
                                                                          (f) =>
                                                                              f.originalName ==
                                                                              id,
                                                                        ),
                                                                  )
                                                                  .toList();
                                                          final cubit =
                                                              context
                                                                  .read<
                                                                    DocumentUploadCubit
                                                                  >();
                                                          final confirmed = await showDialog<
                                                            bool
                                                          >(
                                                            context: context,
                                                            builder:
                                                                (
                                                                  ctx,
                                                                ) => AlertDialog(
                                                                  title: const Text(
                                                                    'Подтвердите удаление',
                                                                  ),
                                                                  content: Text(
                                                                    'Удалить ${idsToDelete.length} выбранных файлов?',
                                                                  ),
                                                                  actions: [
                                                                    TextButton(
                                                                      onPressed:
                                                                          () => Navigator.of(
                                                                            ctx,
                                                                          ).pop(
                                                                            false,
                                                                          ),
                                                                      child: const Text(
                                                                        'Отмена',
                                                                      ),
                                                                    ),
                                                                    TextButton(
                                                                      onPressed:
                                                                          () => Navigator.of(
                                                                            ctx,
                                                                          ).pop(
                                                                            true,
                                                                          ),
                                                                      child: const Text(
                                                                        'Удалить',
                                                                        style: TextStyle(
                                                                          color:
                                                                              Colors.red,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                          );
                                                          if (confirmed ==
                                                              true) {
                                                            if (!mounted) {
                                                              return;
                                                            }
                                                            for (var file
                                                                in filesToDelete) {
                                                              cubit.deleteFile(
                                                                file,
                                                              );
                                                            }
                                                            setState(
                                                              () =>
                                                                  _selected
                                                                      .clear(),
                                                            );
                                                          }
                                                        }
                                                        : null,
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                label: const Text('Удалить'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: buildGroupedByCategory(
                                          context,
                                          state.files,
                                          _selected,
                                          _toggleSelection,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Center(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            context
                                                .read<DocumentUploadCubit>()
                                                .reset();
                                            nameController.clear();
                                            lastNameController.clear();
                                          },
                                          icon: const Icon(Icons.restart_alt),
                                          label: const Text('Новый абитуриент'),
                                        ),
                                      ),
                                    ],
                                  ),
                        ),

                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),

              // Page-level drag overlay
              if (_dragActive)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: Color.fromRGBO(0, 0, 0, 0.45),
                      child: Center(
                        child: Card(
                          color: Theme.of(context).colorScheme.surface,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_upload,
                                  size: 56,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Перетащите файлы, чтобы загрузить',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Отпустите файлы, чтобы начать загрузку',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Widget buildGroupedByCategory(
  BuildContext context,
  List<UploadedFile> files,
  Set<String> selected,
  void Function(String) toggleSelection,
) {
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

  if (grouped.isEmpty) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_open,
            size: 56,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Нет документов',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Загрузите документы, и мы автоматически их классифицируем и сгруппируем по категориям.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children:
        grouped.entries.map((entry) {
          final catKey = entry.key;
          final items = entry.value;
          final info =
              categoryInfo[catKey] ??
              CategoryInfo(
                name: catKey,
                icon: Icons.description,
                color: Colors.grey,
              );

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: info.color.withValues(alpha: 0.12),
                        child: Icon(info.icon, color: info.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${info.name} (${items.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Скачать все (${items.length})',
                        icon: const Icon(Icons.download_rounded),
                        onPressed:
                            items.any((f) => f.newName != null)
                                ? () {
                                  for (var f in items) {
                                    if (f.newName != null) {
                                      context
                                          .read<DocumentUploadCubit>()
                                          .downloadFile(f);
                                    }
                                  }
                                }
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Files list
                  ...items.map((f) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getFileIcon(f.originalName),
                          color: info.color,
                        ),
                      ),
                      title: Text(
                        f.originalName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle:
                          f.newName != null
                              ? Text('Сохранено как ${f.newName!}')
                              : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: selected.contains(f.originalName),
                            onChanged: (_) => toggleSelection(f.originalName),
                          ),
                          IconButton(
                            tooltip: 'Скачать',
                            icon: const Icon(Icons.download_outlined),
                            onPressed:
                                () => context
                                    .read<DocumentUploadCubit>()
                                    .downloadFile(f),
                          ),
                          IconButton(
                            tooltip: 'Удалить',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (ctx) => AlertDialog(
                                      title: const Text('Подтвердите удаление'),
                                      content: Text(
                                        'Удалить "${f.originalName}"?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(ctx).pop(),
                                          child: const Text('Отмена'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(ctx).pop();
                                            context
                                                .read<DocumentUploadCubit>()
                                                .deleteFile(f);
                                          },
                                          child: const Text(
                                            'Удалить',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
  );
}

IconData _getFileIcon(String filename) {
  if (filename.isEmpty) return Icons.insert_drive_file;
  final lower = filename.toLowerCase();
  final dot = lower.lastIndexOf('.');
  final ext = dot >= 0 ? lower.substring(dot + 1) : '';
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'jpg':
    case 'jpeg':
    case 'png':
      return Icons.image;
    case 'doc':
    case 'docx':
      return Icons.description;
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

  UploadedFile? _lastDeleted;

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
    // Determine backend origin. When running Flutter dev server (chrome) the
    // app is served from a different origin and /upload will 404. Fall back
    // to localhost:5040 during local development so requests hit the backend.
    final uploadUrl = '${getBackendOrigin()}/upload';
    debugPrint('Uploading to: $uploadUrl');
    request.open('POST', uploadUrl);
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
        try {
          debugPrint('Upload response: ${request.response}');
        } catch (e) {
          debugPrint('Unable to print upload response: $e');
        }
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
    // keep last deleted for undo
    _lastDeleted = file;

    if (file.newName == null) {
      // Просто удалить из UI
      final updated = state.files.where((f) => f != file).toList();
      emit(state.copyWith(files: updated));
      return;
    }

    final url =
        '${getBackendOrigin()}/delete_file?filename=${Uri.encodeComponent(file.newName!)}';
    debugPrint('DELETE -> $url');

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

  void undoDelete() {
    final file = _lastDeleted;
    if (file == null) return;
    _lastDeleted = null;
    emit(state.copyWith(files: [...state.files, file]));
  }

  void downloadFile(UploadedFile file) {
    if (file.newName != null) {
      final anchor = web.HTMLAnchorElement();
      anchor.href =
          '${getBackendOrigin()}/files/${Uri.encodeComponent(file.newName!)}';
      debugPrint('Downloading file from: ${anchor.href}');
      anchor.setAttribute('download', file.newName!);
      anchor.click();
    }
  }

  void downloadAll() {
    final url =
        '${getBackendOrigin()}/download_zip?name=${Uri.encodeComponent(state.name)}&lastname=${Uri.encodeComponent(state.lastName)}';
    debugPrint('Downloading zip from: $url');

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
  final UploadStatus status;

  UploadedFile({
    required this.originalName,
    this.newName,
    required this.category,
    this.status = UploadStatus.done,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      originalName: json['original_name'] as String,
      newName: json['new_name'] as String?,
      category: json['category'] as String,
      status: UploadStatus.done,
    );
  }
}

enum UploadStatus { queued, uploading, done, failed }
