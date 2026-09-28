import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:farmer_market_app/core/constants/app_spacing.dart';
import 'package:farmer_market_app/core/widgets/app_bar/app_top_bar.dart';
import 'package:farmer_market_app/core/widgets/app_card.dart';
import 'package:farmer_market_app/core/widgets/buttons/app_button.dart';
import 'package:farmer_market_app/core/widgets/dropdowns/app_dropdown.dart';
import 'package:farmer_market_app/core/widgets/empty_state_widget.dart';
import 'package:farmer_market_app/core/widgets/error_state_widget.dart';
import 'package:farmer_market_app/core/widgets/inputs/app_text_field.dart';
import 'package:farmer_market_app/core/widgets/snackbars/app_snack_bar.dart';
import 'package:farmer_market_app/features/auth/presentation/controllers/auth_providers.dart';
import 'package:farmer_market_app/features/farmer/domain/models/crop_calendar_event_model.dart';
import 'package:farmer_market_app/features/farmer/presentation/controllers/farmer_providers.dart';

class CropCalendarScreen extends ConsumerStatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  ConsumerState<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends ConsumerState<CropCalendarScreen> {
  static const Map<String, String> _eventTypes = {
    'sowing': 'Sowing',
    'irrigation': 'Irrigation',
    'fertilizer': 'Fertilizer',
    'pest_control': 'Pest Control',
    'harvest': 'Harvest',
    'other': 'Other',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final farmerId = ref.read(authNotifierProvider).profile?.id;
    if (farmerId != null) {
      ref.read(cropCalendarControllerProvider.notifier).fetchEvents(farmerId);
    }
  }

  Future<void> _openAddEventSheet() async {
    final farmerId = ref.read(authNotifierProvider).profile?.id;
    if (farmerId == null) return;

    final cropController = TextEditingController();
    final noteController = TextEditingController();
    final notifyDaysController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    var eventType = 'sowing';
    var selectedDate = DateTime.now().add(const Duration(days: 1));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.sm,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'New Crop Reminder',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Crop Name',
                        hint: 'e.g. Wheat, Cotton',
                        controller: cropController,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Enter crop name' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDropdownFormField<String>(
                        label: 'Activity Type',
                        value: eventType,
                        items: _eventTypes.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setSheetState(() => eventType = v ?? eventType),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Event Date',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Remind me (days before)',
                        controller: notifyDaysController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = int.tryParse((v ?? '').trim());
                          if (n == null || n < 0 || n > 30) return 'Enter 0 to 30 days';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Note (optional)',
                        controller: noteController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Consumer(
                        builder: (context, ref, _) {
                          final isSubmitting =
                              ref.watch(cropCalendarControllerProvider).isSubmitting;
                          return AppButton(
                            label: 'Save Reminder',
                            icon: Icons.check_circle_outline_rounded,
                            isLoading: isSubmitting,
                            onPressed: () async {
                              if (!(formKey.currentState?.validate() ?? false)) return;
                              final note = noteController.text.trim();
                              final event = CropCalendarEventModel(
                                id: '',
                                farmerId: farmerId,
                                cropName: cropController.text.trim(),
                                eventType: eventType,
                                eventDate: selectedDate,
                                notifyBeforeDays: int.parse(notifyDaysController.text.trim()),
                                note: note.isEmpty ? null : note,
                              );
                              final ok = await ref
                                  .read(cropCalendarControllerProvider.notifier)
                                  .addEvent(event);
                              if (!context.mounted) return;
                              if (ok) {
                                Navigator.of(context).pop();
                                AppSnackBar.show(
                                  this.context,
                                  message: 'Reminder added!',
                                  type: SnackBarType.success,
                                );
                              } else {
                                final err = ref.read(cropCalendarControllerProvider).errorMessage;
                                if (err != null) {
                                  AppSnackBar.show(context, message: err, type: SnackBarType.error);
                                }
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    cropController.dispose();
    noteController.dispose();
    notifyDaysController.dispose();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'sowing':
        return Icons.grass_rounded;
      case 'irrigation':
        return Icons.water_drop_outlined;
      case 'fertilizer':
        return Icons.science_outlined;
      case 'pest_control':
        return Icons.pest_control_outlined;
      case 'harvest':
        return Icons.agriculture_outlined;
      default:
        return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropCalendarControllerProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);

    Widget body;
    if (state.isLoading && state.events.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.errorMessage != null && state.events.isEmpty) {
      body = ErrorStateWidget(
        title: 'Unable to load crop calendar',
        message: state.errorMessage!,
        onRetry: _load,
      );
    } else if (state.events.isEmpty) {
      body = const EmptyStateWidget(
        icon: Icons.calendar_month_outlined,
        title: 'No reminders yet',
        message: 'Add sowing, irrigation, fertilizer, or harvest reminders for your crops.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async => _load(),
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.huge + AppSpacing.xxxl,
          ),
          itemCount: state.events.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final event = state.events[index];
            final isOverdue = !event.isCompleted && event.eventDate.isBefore(startOfToday);
            return AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: event.isCompleted,
                    onChanged: (val) => ref
                        .read(cropCalendarControllerProvider.notifier)
                        .toggleCompleted(event.id, val ?? false),
                  ),
                  Icon(_iconFor(event.eventType), color: colorScheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.cropName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            decoration:
                                event.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_eventTypes[event.eventType] ?? event.eventType} • ${DateFormat('dd MMM yyyy').format(event.eventDate)}${isOverdue ? '  (overdue)' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? colorScheme.error : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (event.note != null && event.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              event.note!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete reminder',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => ref
                        .read(cropCalendarControllerProvider.notifier)
                        .deleteEvent(event.id),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Crop Calendar'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddEventSheet,
        icon: const Icon(Icons.add),
        label: const Text('New Reminder'),
      ),
      body: body,
    );
  }
}
