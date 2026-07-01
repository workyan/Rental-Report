import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final launchConfig = await AppLaunchConfig.fromPlatform();
  final model = launchConfig.screenshotMode
      ? AppModel.showcase()
      : AppModel.empty();
  runApp(RentalReportApp(launchConfig: launchConfig, model: model));
}

class RentalReportApp extends StatelessWidget {
  const RentalReportApp({
    super.key,
    required this.launchConfig,
    required this.model,
  });

  final AppLaunchConfig launchConfig;
  final AppModel model;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Rental Report',
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            fontFamily: '.SF Pro Text',
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.04,
              ),
              headlineMedium: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.12,
              ),
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              titleMedium: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              bodyLarge: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              bodySmall: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
          home: AppShell(launchConfig: launchConfig, model: model),
        );
      },
    );
  }
}

enum ScreenshotScene {
  home,
  inspectionType,
  roomList,
  roomDetail,
  addIssue,
  signatures,
  exportPreview,
  history,
  settings,
}

class AppLaunchConfig {
  const AppLaunchConfig({
    this.screenshotMode = false,
    this.scene = ScreenshotScene.home,
  });

  final bool screenshotMode;
  final ScreenshotScene scene;

  static const _channel = MethodChannel('rentalreport/screenshot');

  static const Map<String, AppLaunchConfig> _sceneConfigs = {
    'home-overview': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.home,
    ),
    'inspection-type': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.inspectionType,
    ),
    'room-list-progress': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.roomList,
    ),
    'room-detail-photos': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.roomDetail,
    ),
    'issue-detail': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.addIssue,
    ),
    'signatures-review': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.signatures,
    ),
    'pdf-export-preview': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.exportPreview,
    ),
    'history-reports': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.history,
    ),
    'settings-preferences': AppLaunchConfig(
      screenshotMode: true,
      scene: ScreenshotScene.settings,
    ),
  };

  static Future<AppLaunchConfig> fromPlatform() async {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      try {
        final context = await _channel.invokeMapMethod<String, dynamic>(
          'getLaunchContext',
        );
        final screenshotMode = context?['screenshotMode'] == true;
        final scene = context?['scene'] as String?;
        if (!screenshotMode || scene == null || scene.isEmpty) {
          return const AppLaunchConfig();
        }

        return _sceneConfigs[scene] ?? const AppLaunchConfig();
      } on MissingPluginException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      } on PlatformException {
        return const AppLaunchConfig();
      }
    }

    return const AppLaunchConfig();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.launchConfig, required this.model});

  final AppLaunchConfig launchConfig;
  final AppModel model;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;
  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    if (widget.launchConfig.screenshotMode) {
      return _buildScreenshotScene(widget.launchConfig.scene);
    }

    final body = switch (_tabIndex) {
      0 => _showHistory
          ? HistoryScreen(
              model: widget.model,
              onBack: () => setState(() => _showHistory = false),
            )
          : HomeScreen(
              model: widget.model,
              onOpenHistory: () => setState(() => _showHistory = true),
              onNewInspection: _startInspectionFlow,
            ),
      1 => PropertiesScreen(
          model: widget.model,
          onCreateProperty: _openCreatePropertySheet,
          onStartInspection: _startInspectionFlow,
        ),
      _ => SettingsScreen(model: widget.model, showStandaloneHeader: false),
    };

    return Scaffold(
      body: SafeArea(child: body),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _tabIndex,
            onTap: (index) {
              setState(() {
                _tabIndex = index;
                if (index != 0) {
                  _showHistory = false;
                }
              });
            },
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textTertiary,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.house_fill),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.building_2_fill),
                label: 'Properties',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.gear_alt_fill),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreenshotScene(ScreenshotScene scene) {
    final showcaseInspection = widget.model.inspections.first;
    final showcaseRoom = showcaseInspection.rooms[1];

    return switch (scene) {
      ScreenshotScene.home => HomeScreen(
          model: widget.model,
          onOpenHistory: () {},
          onNewInspection: () {},
        ),
      ScreenshotScene.inspectionType => const InspectionTypeScreen(),
      ScreenshotScene.roomList => RoomListScreen(
          model: widget.model,
          inspectionId: showcaseInspection.id,
        ),
      ScreenshotScene.roomDetail => RoomDetailScreen(
          model: widget.model,
          inspectionId: showcaseInspection.id,
          roomName: showcaseRoom.name,
        ),
      ScreenshotScene.addIssue => AddIssueScreen(
          model: widget.model,
          inspectionId: showcaseInspection.id,
          roomName: showcaseRoom.name,
        ),
      ScreenshotScene.signatures => SignaturesScreen(
          model: widget.model,
          inspectionId: showcaseInspection.id,
        ),
      ScreenshotScene.exportPreview => ExportPreviewScreen(
          model: widget.model,
          inspectionId: showcaseInspection.id,
        ),
      ScreenshotScene.history => HistoryScreen(model: widget.model, onBack: () {}),
      ScreenshotScene.settings => SettingsScreen(
          model: widget.model,
          showStandaloneHeader: true,
        ),
    };
  }

  Future<void> _startInspectionFlow() async {
    setState(() => _showHistory = false);
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (selectionContext) => InspectionTypeScreen(
          onSelected: (type) async {
            final navigator = Navigator.of(selectionContext);
            final property = await navigator.push<PropertyRecord>(
              CupertinoPageRoute<PropertyRecord>(
                builder: (context) => PropertyPickerScreen(
                  model: widget.model,
                  onCreateProperty: _openCreatePropertySheet,
                ),
              ),
            );
            if (property == null) {
              return;
            }

            final inspectionId = widget.model.createInspection(
              propertyId: property.id,
              type: type,
            );

            if (!mounted) {
              return;
            }

            navigator.pushReplacement(
              CupertinoPageRoute<void>(
                builder: (context) => RoomListScreen(
                  model: widget.model,
                  inspectionId: inspectionId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<PropertyRecord?> _openCreatePropertySheet() {
    return showModalBottomSheet<PropertyRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPropertySheet(model: widget.model),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.model,
    required this.onOpenHistory,
    required this.onNewInspection,
  });

  final AppModel model;
  final VoidCallback onOpenHistory;
  final VoidCallback onNewInspection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = model.recentInspections.take(3).toList();
    final stats = model.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF7FCFF), Color(0xFFF8F3EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/welcome_hero.png',
                    height: 188,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Move-in reports that look\nclear, fast, and credible.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Build a room-by-room record with notes, issue tracking, signatures, and a polished export summary.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Start New Inspection',
                    leading: CupertinoIcons.add,
                    onPressed: onNewInspection,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Properties',
                  value: '${stats.propertyCount}',
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Active Drafts',
                  value: '${stats.draftCount}',
                  accent: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Exports',
                  value: '${stats.exportedCount}',
                  accent: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TappableCard(
            onTap: onOpenHistory,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_search,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Inspection History', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${model.inspections.length} saved inspections',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_forward,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: 'Recent Activity',
            actionLabel: model.inspections.isEmpty ? null : 'See all',
            onAction: model.inspections.isEmpty ? null : onOpenHistory,
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            EmptyStateCard(
              image: 'assets/images/property_beach.png',
              title: 'No inspections yet',
              body:
                  'Create your first property, walk the rooms, and keep a clean record ready for tenants, owners, or hosts.',
              actionLabel: 'Create First Inspection',
              onAction: onNewInspection,
            )
          else
            ...recent.map(
              (inspection) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InspectionSummaryCard(
                  inspection: inspection,
                  property: model.propertyById(inspection.propertyId)!,
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (context) => RoomListScreen(
                          model: model,
                          inspectionId: inspection.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.model, required this.onBack});

  final AppModel model;
  final VoidCallback onBack;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final history = widget.model.filterInspections(_query);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Column(
        children: [
          HeaderBar(
            title: 'History',
            leading: HeaderAction.icon(
              icon: CupertinoIcons.back,
              label: 'Back',
              onTap: widget.onBack,
            ),
          ),
          const SizedBox(height: 18),
          SearchField(
            hint: 'Search inspections',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: history.isEmpty
                ? EmptyStateCard(
                    image: 'assets/images/property_maple.png',
                    title: 'Nothing matches this search',
                    body:
                        'Try a property name, address, inspection type, or clear the search to see every saved inspection.',
                  )
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final inspection = history[index];
                      final property =
                          widget.model.propertyById(inspection.propertyId)!;
                      return InspectionSummaryCard(
                        inspection: inspection,
                        property: property,
                        onTap: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (context) => RoomListScreen(
                                model: widget.model,
                                inspectionId: inspection.id,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({
    super.key,
    required this.model,
    required this.onCreateProperty,
    required this.onStartInspection,
  });

  final AppModel model;
  final Future<PropertyRecord?> Function() onCreateProperty;
  final VoidCallback onStartInspection;

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final properties = widget.model.filterProperties(_query);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        children: [
          const HeaderBar(title: 'Properties'),
          const SizedBox(height: 18),
          SearchField(
            hint: 'Search properties',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: properties.isEmpty
                ? EmptyStateCard(
                    image: 'assets/images/property_sunset.png',
                    title: 'No properties saved yet',
                    body:
                        'Add a property once, then reuse it for move-in, move-out, and routine inspections.',
                    actionLabel: 'Add Property',
                    onAction: _handleCreateProperty,
                  )
                : ListView.separated(
                    itemCount: properties.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == properties.length) {
                        return TappableCard(
                          onTap: _handleCreateProperty,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.add,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Add New Property',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }

                      final property = properties[index];
                      final count = widget.model.inspectionCountForProperty(
                        property.id,
                      );
                      return TappableCard(
                        onTap: widget.onStartInspection,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                property.image,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    property.name,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    property.address,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$count inspections',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_forward,
                              size: 16,
                              color: AppColors.textTertiary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateProperty() async {
    await widget.onCreateProperty();
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.model,
    required this.showStandaloneHeader,
  });

  final AppModel model;
  final bool showStandaloneHeader;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showStandaloneHeader) const HeaderBar(title: 'Settings'),
          if (widget.showStandaloneHeader) const SizedBox(height: 18),
          if (!widget.showStandaloneHeader)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          LabelText(label: 'PREFERENCES'),
          const SizedBox(height: 10),
          TappableCard(
            onTap: () {},
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                SettingsRow(
                  title: 'Date Format',
                  trailing: widget.model.datePreview,
                ),
                const Divider(height: 1, color: AppColors.border),
                SettingsRow(
                  title: 'Default Report Title',
                  trailing: 'Rental Inspection Report',
                ),
                const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Include Empty Checklist Items',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Keep untouched checklist rows in the export summary.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: widget.model.includeEmptyItems,
                        activeTrackColor: AppColors.primary,
                        onChanged: widget.model.setIncludeEmptyItems,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LabelText(label: 'ABOUT'),
          const SizedBox(height: 10),
          TappableCard(
            onTap: () {},
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: const [
                SettingsRow(title: 'Privacy Policy'),
                Divider(height: 1, color: AppColors.border),
                SettingsRow(title: 'Support', trailing: 'support@rentalreport.app'),
                Divider(height: 1, color: AppColors.border),
                SettingsRow(title: 'App Version', trailing: '1.0.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InspectionTypeScreen extends StatelessWidget {
  const InspectionTypeScreen({super.key, this.onSelected});

  final ValueChanged<InspectionType>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: Column(
            children: [
              const SizedBox(height: 18),
              Text(
                'Choose an inspection type',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Start with the right report format, then select the property and walk each room.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ...InspectionType.values.map(
                (type) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TappableCard(
                    onTap: () {
                      if (onSelected != null) {
                        onSelected!(type);
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    background: Colors.white,
                    borderColor: type.tint,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: type.tint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(type.icon, color: type.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.label,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.subtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              SecondaryButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PropertyPickerScreen extends StatefulWidget {
  const PropertyPickerScreen({
    super.key,
    required this.model,
    required this.onCreateProperty,
  });

  final AppModel model;
  final Future<PropertyRecord?> Function() onCreateProperty;

  @override
  State<PropertyPickerScreen> createState() => _PropertyPickerScreenState();
}

class _PropertyPickerScreenState extends State<PropertyPickerScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final properties = widget.model.filterProperties(_query);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              HeaderBar(
                title: 'Select Property',
                leading: HeaderAction.icon(
                  icon: CupertinoIcons.back,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 18),
              SearchField(
                hint: 'Search properties',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: properties.isEmpty
                    ? EmptyStateCard(
                        image: 'assets/images/property_beach.png',
                        title: 'Add a property first',
                        body:
                            'Create a property profile with a clear name and address, then launch the inspection from there.',
                        actionLabel: 'Add Property',
                        onAction: _handleCreateProperty,
                      )
                    : ListView.separated(
                        itemCount: properties.length + 1,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == properties.length) {
                            return TappableCard(
                              onTap: _handleCreateProperty,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.add,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add New Property',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              ),
                            );
                          }

                          final property = properties[index];
                          return TappableCard(
                            onTap: () => Navigator.of(context).pop(property),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    property.image,
                                    width: 58,
                                    height: 58,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        property.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        property.address,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  CupertinoIcons.chevron_forward,
                                  color: AppColors.textTertiary,
                                  size: 16,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateProperty() async {
    final property = await widget.onCreateProperty();
    if (!mounted || property == null) {
      return;
    }
    Navigator.of(context).pop(property);
  }
}

class RoomListScreen extends StatelessWidget {
  const RoomListScreen({
    super.key,
    required this.model,
    required this.inspectionId,
  });

  final AppModel model;
  final String inspectionId;

  @override
  Widget build(BuildContext context) {
    final inspection = model.inspectionById(inspectionId)!;
    final property = model.propertyById(inspection.propertyId)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            children: [
              HeaderBar(
                title: 'Inspection',
                subtitle: inspection.type.label,
                leading: HeaderAction.icon(
                  icon: CupertinoIcons.back,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(height: 18),
              TappableCard(
                onTap: () {},
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${property.address}\n${inspection.formattedDate}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            property.image,
                            width: 74,
                            height: 74,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Overall Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          inspection.progressLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProgressBar(progress: inspection.progress),
                    const SizedBox(height: 12),
                    Text(
                      '${inspection.issueCount} flagged issues · ${inspection.completedRoomCount} of ${inspection.rooms.length} rooms complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: inspection.rooms.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room = inspection.rooms[index];
                    return TappableCard(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (context) => RoomDetailScreen(
                              model: model,
                              inspectionId: inspection.id,
                              roomName: room.name,
                            ),
                          ),
                        );
                      },
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          StatusBullet(
                            color: room.condition.color,
                            icon: room.condition.icon,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  room.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  room.subtitle,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            room.condition.shortLabel,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: room.condition.color),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: 'Review & Export',
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (context) => SignaturesScreen(
                  model: model,
                  inspectionId: inspection.id,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.model,
    required this.inspectionId,
    required this.roomName,
  });

  final AppModel model;
  final String inspectionId;
  final String roomName;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late final TextEditingController _noteController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: room.note);
  }

  InspectionRecord get inspection => widget.model.inspectionById(widget.inspectionId)!;

  RoomRecord get room =>
      inspection.rooms.firstWhere((element) => element.name == widget.roomName);

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.model.propertyById(inspection.propertyId)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderBar(
                  title: room.name,
                  leading: HeaderAction.icon(
                    icon: CupertinoIcons.back,
                    label: 'Rooms',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 18),
                TappableCard(
                  onTap: () {},
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          property.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              inspection.type.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${property.name} · ${inspection.formattedDate}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text('Condition', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: RoomCondition.values
                      .where((condition) => condition != RoomCondition.notStarted)
                      .map(
                        (condition) => ConditionChip(
                          label: condition.chipLabel,
                          accent: condition.color,
                          icon: condition.icon,
                          selected: room.condition == condition,
                          onTap: () {
                            widget.model.updateRoomCondition(
                              inspectionId: inspection.id,
                              roomName: room.name,
                              condition: condition,
                            );
                            setState(() {});
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                NoteField(
                  controller: _noteController,
                  maxLength: 250,
                  hint: 'Add room notes, wear details, and anything worth highlighting in the report.',
                  onChanged: (value) {
                    widget.model.updateRoomNote(
                      inspectionId: inspection.id,
                      roomName: room.name,
                      note: value,
                    );
                    setState(() {});
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Photos', style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${room.photoAssets.length} attached',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    PhotoAddTile(
                      onTap: _showPhotoSourceSheet,
                    ),
                    ...room.photoAssets.map(
                      (asset) => PhotoThumb(
                        image: asset,
                        onRemove: () {
                          widget.model.removeRoomPhoto(
                            inspectionId: inspection.id,
                            roomName: room.name,
                            asset: asset,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Issues (${room.issues.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (room.issues.isNotEmpty)
                      Text(
                        'Tap to review',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (room.issues.isEmpty)
                  TappableCard(
                    onTap: _openAddIssue,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_bubble,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add an issue for damage, missing items, cleaning, or wear.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...room.issues.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TappableCard(
                        onTap: () {},
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            StatusBullet(
                              color: issue.condition.color,
                              icon: issue.condition.icon,
                              small: true,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    issue.item,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${issue.condition.shortLabel} · ${issue.severity.label}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                widget.model.removeIssue(
                                  inspectionId: inspection.id,
                                  roomName: room.name,
                                  issueId: issue.id,
                                );
                                setState(() {});
                              },
                              child: const Icon(
                                CupertinoIcons.trash,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: 'Add Issue',
          leading: CupertinoIcons.add,
          onPressed: _openAddIssue,
        ),
      ),
    );
  }

  Future<void> _openAddIssue() async {
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => AddIssueScreen(
          model: widget.model,
          inspectionId: inspection.id,
          roomName: room.name,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showPhotoSourceSheet() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Add Photo'),
        message: const Text('Choose a real photo from the camera or photo library.'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await _pickPhoto(ImageSource.camera);
            },
            child: const Text('Take Photo'),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.of(context).pop();
              await _pickPhoto(ImageSource.gallery);
            },
            child: const Text('Choose From Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2200,
      );
      if (pickedFile == null || !mounted) {
        return;
      }

      widget.model.addRoomPhoto(
        inspectionId: inspection.id,
        roomName: room.name,
        path: pickedFile.path,
      );
      setState(() {});
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo picker is not loaded yet. Fully restart the app.'),
        ),
      );
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      final message = switch (error.code) {
        'camera_access_denied' => 'Camera access was denied. Enable it in iPhone Settings.',
        'photo_access_denied' => 'Photo Library access was denied. Enable it in iPhone Settings.',
        'camera_unavailable' => 'Camera is unavailable on this device. Use Photo Library instead.',
        'invalid_image' => 'The selected image could not be loaded.',
        _ => 'Unable to add photo right now. ${error.message ?? ''}'.trim(),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      debugPrint('Photo pick failed: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add photo right now.')),
      );
    }
  }
}

class AddIssueScreen extends StatefulWidget {
  const AddIssueScreen({
    super.key,
    required this.model,
    required this.inspectionId,
    required this.roomName,
  });

  final AppModel model;
  final String inspectionId;
  final String roomName;

  @override
  State<AddIssueScreen> createState() => _AddIssueScreenState();
}

class _AddIssueScreenState extends State<AddIssueScreen> {
  late final TextEditingController _itemController;
  late final TextEditingController _noteController;
  RoomCondition _condition = RoomCondition.damaged;
  IssueSeverity _severity = IssueSeverity.medium;

  @override
  void initState() {
    super.initState();
    _itemController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderBar(
                  title: 'Add Issue',
                  leading: HeaderAction.text(
                    label: 'Cancel',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  trailing: HeaderAction.text(label: 'Save', onTap: _save),
                ),
                const SizedBox(height: 20),
                Text('Item', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                DetailField(
                  controller: _itemController,
                  hint: 'Window frame, oven, sink, flooring...',
                ),
                const SizedBox(height: 16),
                Text('Condition', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: RoomCondition.values
                      .where((condition) => condition != RoomCondition.notStarted)
                      .map(
                        (condition) => ConditionChip(
                          label: condition.chipLabel,
                          accent: condition.color,
                          icon: condition.icon,
                          selected: _condition == condition,
                          onTap: () => setState(() => _condition = condition),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text('Severity', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: IssueSeverity.values
                      .map(
                        (severity) => SeverityChip(
                          label: severity.label,
                          accent: severity.color,
                          selected: _severity == severity,
                          onTap: () => setState(() => _severity = severity),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text('Note', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                NoteField(
                  controller: _noteController,
                  maxLength: 250,
                  hint: 'Describe what was found and what follow-up may be needed.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    final item = _itemController.text.trim();
    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the item name before saving.')),
      );
      return;
    }

    widget.model.addIssue(
      inspectionId: widget.inspectionId,
      roomName: widget.roomName,
      item: item,
      condition: _condition,
      severity: _severity,
      note: _noteController.text.trim(),
    );
    Navigator.of(context).pop();
  }
}

class SignaturesScreen extends StatefulWidget {
  const SignaturesScreen({
    super.key,
    required this.model,
    required this.inspectionId,
  });

  final AppModel model;
  final String inspectionId;

  @override
  State<SignaturesScreen> createState() => _SignaturesScreenState();
}

class _SignaturesScreenState extends State<SignaturesScreen> {
  late final TextEditingController _landlordController;
  late final TextEditingController _tenantController;

  InspectionRecord get inspection => widget.model.inspectionById(widget.inspectionId)!;

  @override
  void initState() {
    super.initState();
    _landlordController = TextEditingController(
      text: inspection.landlordSignature?.name ?? '',
    );
    _tenantController = TextEditingController(
      text: inspection.tenantSignature?.name ?? '',
    );
  }

  @override
  void dispose() {
    _landlordController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.model.inspectionById(widget.inspectionId)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              HeaderBar(
                title: 'Signatures',
                leading: HeaderAction.text(
                  label: 'Back',
                  onTap: () => Navigator.of(context).pop(),
                ),
                trailing: HeaderAction.text(
                  label: 'Clear All',
                  onTap: () {
                    widget.model.clearSignatures(widget.inspectionId);
                    _landlordController.clear();
                    _tenantController.clear();
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SignaturePanel(
                        role: 'Landlord / Manager',
                        subtitle: 'Required before export',
                        controller: _landlordController,
                        signature: current.landlordSignature,
                        accent: AppColors.primary,
                        onSign: () {
                          widget.model.captureSignature(
                            inspectionId: widget.inspectionId,
                            role: SignatureRole.landlord,
                            name: _landlordController.text.trim(),
                          );
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      SignaturePanel(
                        role: 'Tenant / Occupant',
                        subtitle: 'Optional but recommended',
                        controller: _tenantController,
                        signature: current.tenantSignature,
                        accent: AppColors.success,
                        onSign: () {
                          widget.model.captureSignature(
                            inspectionId: widget.inspectionId,
                            role: SignatureRole.tenant,
                            name: _tenantController.text.trim(),
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(
          label: 'Continue',
          onPressed: current.landlordSignature == null
              ? () {
                  if (_landlordController.text.trim().isNotEmpty) {
                    widget.model.captureSignature(
                      inspectionId: widget.inspectionId,
                      role: SignatureRole.landlord,
                      name: _landlordController.text.trim(),
                    );
                  }
                  setState(() {});
                }
              : () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (context) => ExportPreviewScreen(
                        model: widget.model,
                        inspectionId: widget.inspectionId,
                      ),
                    ),
                  );
                },
        ),
      ),
    );
  }
}

class ExportPreviewScreen extends StatelessWidget {
  const ExportPreviewScreen({
    super.key,
    required this.model,
    required this.inspectionId,
  });

  final AppModel model;
  final String inspectionId;

  @override
  Widget build(BuildContext context) {
    final inspection = model.inspectionById(inspectionId)!;
    final property = model.propertyById(inspection.propertyId)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              HeaderBar(
                title: 'Export Preview',
                leading: HeaderAction.icon(
                  icon: CupertinoIcons.back,
                  label: 'Back',
                  onTap: () => Navigator.of(context).pop(),
                ),
                trailing: HeaderAction.icon(
                  icon: CupertinoIcons.share,
                  onTap: () => _export(context),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: TappableCard(
                    onTap: () {},
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'RENTAL INSPECTION REPORT',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontSize: 13, letterSpacing: 0.6),
                          ),
                        ),
                        Center(
                          child: Text(
                            inspection.type.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            property.image,
                            height: 172,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          property.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${property.address}\n${inspection.formattedDate}\nPrepared by ${inspection.landlordSignature?.name ?? 'Property Manager'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Overview',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        OverviewTable(inspection: inspection),
                        const SizedBox(height: 18),
                        Text(
                          'Report Includes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        const ChecklistLine(label: 'Room conditions'),
                        const ChecklistLine(label: 'Issue summary'),
                        const ChecklistLine(label: 'Room notes'),
                        const ChecklistLine(label: 'Signatures'),
                        const SizedBox(height: 18),
                        Text(
                          'Flagged Rooms',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        ...inspection.rooms
                            .where((room) => room.condition != RoomCondition.good)
                            .map(
                              (room) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    StatusBullet(
                                      color: room.condition.color,
                                      icon: room.condition.icon,
                                      small: true,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${room.name}: ${room.subtitle}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: PrimaryButton(label: 'Export PDF', onPressed: () => _export(context)),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final inspection = model.inspectionById(inspectionId)!;
    final property = model.propertyById(inspection.propertyId)!;
    final navigator = Navigator.of(context, rootNavigator: true);
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 12),
              Text('Preparing PDF...'),
            ],
          ),
        ),
      ),
    );

    try {
      final file = await _buildPdfFile(inspection, property);
      model.markExported(inspectionId);

      if (!context.mounted) {
        return;
      }
      navigator.pop();

      final box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${property.name} ${inspection.type.label} Report',
        text: 'Rental inspection report for ${property.name}.',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } catch (error) {
      if (context.mounted) {
        navigator.pop();
        showCupertinoDialog<void>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Export Failed'),
            content: Text(
              'The PDF could not be created right now.\n$error',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class AddPropertySheet extends StatefulWidget {
  const AddPropertySheet({super.key, required this.model});

  final AppModel model;

  @override
  State<AddPropertySheet> createState() => _AddPropertySheetState();
}

class _AddPropertySheetState extends State<AddPropertySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Add Property', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('Property Name', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            DetailField(
              controller: _nameController,
              hint: 'West Harbor Loft',
            ),
            const SizedBox(height: 14),
            Text('Address', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            DetailField(
              controller: _addressController,
              hint: '145 Harbor St, Unit 4B',
            ),
            const SizedBox(height: 18),
            PrimaryButton(label: 'Save Property', onPressed: _save),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      return;
    }
    final property = widget.model.addProperty(name: name, address: address);
    Navigator.of(context).pop(property);
  }
}

class HeaderBar extends StatelessWidget {
  const HeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final HeaderAction? leading;
  final HeaderAction? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (leading != null)
            Align(alignment: Alignment.centerLeft, child: leading!),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing!),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeaderAction extends StatelessWidget {
  const HeaderAction._({required this.child, required this.onTap});

  factory HeaderAction.icon({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
  }) {
    return HeaderAction._(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  factory HeaderAction.text({
    required String label,
    required VoidCallback onTap,
  }) {
    return HeaderAction._(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: child);
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, this.onChanged});

  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodySmall,
          prefixIcon: const Icon(
            CupertinoIcons.search,
            size: 18,
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class TappableCard extends StatelessWidget {
  const TappableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding,
    this.background,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: background ?? Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor ?? AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: child,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              Icon(leading, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          value: progress,
          color: AppColors.primary,
          backgroundColor: const Color(0xFFE9EDF5),
        ),
      ),
    );
  }
}

class StatusBullet extends StatelessWidget {
  const StatusBullet({
    super.key,
    required this.color,
    required this.icon,
    this.small = false,
  });

  final Color color;
  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 20.0 : 28.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: small ? 11 : 14, color: color),
    );
  }
}

class ConditionChip extends StatelessWidget {
  const ConditionChip({
    super.key,
    required this.label,
    required this.accent,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? accent : AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: accent),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: selected ? accent : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SeverityChip extends StatelessWidget {
  const SeverityChip({
    super.key,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.16) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? accent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? accent : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteField extends StatelessWidget {
  const NoteField({
    super.key,
    required this.controller,
    required this.maxLength,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final int maxLength;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.bodyMedium,
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${controller.text.characters.length}/$maxLength',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.image,
    required this.onRemove,
    this.compact = false,
  });

  final String image;
  final VoidCallback onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 76.0 : 84.0;
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AppImage(
            image,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AppImage extends StatelessWidget {
  const AppImage(
    this.path, {
    super.key,
    this.width,
    this.height,
    this.fit,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(path, width: width, height: height, fit: fit);
    }
    return Image.file(File(path), width: width, height: height, fit: fit);
  }
}

class PhotoAddTile extends StatelessWidget {
  const PhotoAddTile({super.key, required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 76.0 : 84.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF5FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.camera_fill,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePanel extends StatelessWidget {
  const SignaturePanel({
    super.key,
    required this.role,
    required this.subtitle,
    required this.controller,
    required this.signature,
    required this.accent,
    required this.onSign,
  });

  final String role;
  final String subtitle;
  final TextEditingController controller;
  final SignatureRecord? signature;
  final Color accent;
  final VoidCallback onSign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(role, style: Theme.of(context).textTheme.titleMedium),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
        TappableCard(
          onTap: () {},
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailField(
                controller: controller,
                hint: 'Full name',
              ),
              const SizedBox(height: 12),
              Container(
                height: 72,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    signature?.name.isNotEmpty == true
                        ? signature!.name
                        : 'Tap Sign to confirm',
                    style: TextStyle(
                      fontSize: signature == null ? 15 : 30,
                      fontStyle:
                          signature == null ? FontStyle.normal : FontStyle.italic,
                      color: signature == null
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      signature?.name.isNotEmpty == true
                          ? signature!.name
                          : 'Awaiting signature',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (signature != null) ...[
                    Text(
                      signature!.dateLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      size: 14,
                      color: AppColors.success,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: signature == null ? 'Sign' : 'Update Signature',
                onPressed: onSign,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DetailField extends StatelessWidget {
  const DetailField({
    super.key,
    required this.controller,
    required this.hint,
  });

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium,
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (trailing != null) ...[
            Text(trailing!, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
          ],
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 15,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class OverviewTable extends StatelessWidget {
  const OverviewTable({super.key, required this.inspection});

  final InspectionRecord inspection;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodySmall;
    final valueStyle = Theme.of(context).textTheme.titleMedium;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MetricColumn(
              label: 'Rooms Complete',
              value: '${inspection.completedRoomCount}/${inspection.rooms.length}',
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
          ),
          Expanded(
            child: _MetricColumn(
              label: 'Issues',
              value: '${inspection.issueCount}',
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
          ),
          Expanded(
            child: _MetricColumn(
              label: 'Signatures',
              value: inspection.signatureCountLabel,
              labelStyle: labelStyle,
              valueStyle: valueStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class ChecklistLine extends StatelessWidget {
  const ChecklistLine({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.check_mark_circled_solid,
            size: 16,
            color: AppColors.success,
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: child,
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class InspectionSummaryCard extends StatelessWidget {
  const InspectionSummaryCard({
    super.key,
    required this.inspection,
    required this.property,
    required this.onTap,
  });

  final InspectionRecord inspection;
  final PropertyRecord property;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              property.image,
              width: 68,
              height: 68,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property.name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${inspection.type.label} · ${inspection.formattedDate}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${inspection.completedRoomCount}/${inspection.rooms.length} rooms complete · ${inspection.issueCount} issues',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          StatusPill(label: inspection.status.label, color: inspection.status.color),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.image,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String image;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return TappableCard(
      onTap: onAction ?? () {},
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              image,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(label: actionLabel!, onPressed: onAction!),
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class LabelText extends StatelessWidget {
  const LabelText({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            letterSpacing: 0.5,
            color: AppColors.textTertiary,
          ),
    );
  }
}

class AppColors {
  static const Color primary = Color(0xFF156FF7);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textTertiary = Color(0xFF98A2B3);
  static const Color border = Color(0xFFE4E7EC);
  static const Color success = Color(0xFF2E9B67);
  static const Color warning = Color(0xFFF39C32);
  static const Color orange = Color(0xFFE97A2F);
  static const Color danger = Color(0xFFE8503A);
  static const Color inactive = Color(0xFFC3CAD8);
}

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF0B1320).withValues(alpha: 0.05),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: const Color(0xFF0B1320).withValues(alpha: 0.025),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

enum InspectionType {
  moveIn,
  moveOut,
  routine;

  String get label => switch (this) {
        InspectionType.moveIn => 'Move-In',
        InspectionType.moveOut => 'Move-Out',
        InspectionType.routine => 'Routine',
      };

  String get subtitle => switch (this) {
        InspectionType.moveIn =>
          'Capture the starting condition before keys are handed over.',
        InspectionType.moveOut =>
          'Document the final condition before turnover or deposit review.',
        InspectionType.routine =>
          'Run a periodic condition check and keep a clean inspection trail.',
      };

  IconData get icon => switch (this) {
        InspectionType.moveIn => CupertinoIcons.arrow_down_doc_fill,
        InspectionType.moveOut => CupertinoIcons.arrow_up_doc_fill,
        InspectionType.routine => CupertinoIcons.calendar,
      };

  Color get color => switch (this) {
        InspectionType.moveIn => AppColors.success,
        InspectionType.moveOut => AppColors.danger,
        InspectionType.routine => AppColors.primary,
      };

  Color get tint => switch (this) {
        InspectionType.moveIn => const Color(0xFFEAF8F0),
        InspectionType.moveOut => const Color(0xFFFFF0EE),
        InspectionType.routine => const Color(0xFFEEF5FF),
      };
}

enum InspectionStatus {
  draft,
  reviewReady,
  exported;

  String get label => switch (this) {
        InspectionStatus.draft => 'Draft',
        InspectionStatus.reviewReady => 'Ready',
        InspectionStatus.exported => 'Exported',
      };

  Color get color => switch (this) {
        InspectionStatus.draft => AppColors.warning,
        InspectionStatus.reviewReady => AppColors.primary,
        InspectionStatus.exported => AppColors.success,
      };
}

enum RoomCondition {
  notStarted,
  good,
  needsCleaning,
  worn,
  damaged,
  missing;

  String get shortLabel => switch (this) {
        RoomCondition.notStarted => 'Not started',
        RoomCondition.good => 'Good',
        RoomCondition.needsCleaning => 'Cleaning',
        RoomCondition.worn => 'Worn',
        RoomCondition.damaged => 'Damaged',
        RoomCondition.missing => 'Missing',
      };

  String get chipLabel => switch (this) {
        RoomCondition.notStarted => 'Not\nStarted',
        RoomCondition.good => 'Good',
        RoomCondition.needsCleaning => 'Needs\nCleaning',
        RoomCondition.worn => 'Worn',
        RoomCondition.damaged => 'Damaged',
        RoomCondition.missing => 'Missing',
      };

  IconData get icon => switch (this) {
        RoomCondition.notStarted => CupertinoIcons.circle_fill,
        RoomCondition.good => CupertinoIcons.check_mark,
        RoomCondition.needsCleaning => CupertinoIcons.sparkles,
        RoomCondition.worn => CupertinoIcons.circle_lefthalf_fill,
        RoomCondition.damaged => CupertinoIcons.exclamationmark,
        RoomCondition.missing => CupertinoIcons.xmark,
      };

  Color get color => switch (this) {
        RoomCondition.notStarted => AppColors.inactive,
        RoomCondition.good => AppColors.success,
        RoomCondition.needsCleaning => AppColors.warning,
        RoomCondition.worn => AppColors.orange,
        RoomCondition.damaged => AppColors.danger,
        RoomCondition.missing => AppColors.textSecondary,
      };
}

enum IssueSeverity {
  low,
  medium,
  high;

  String get label => switch (this) {
        IssueSeverity.low => 'Low',
        IssueSeverity.medium => 'Medium',
        IssueSeverity.high => 'High',
      };

  Color get color => switch (this) {
        IssueSeverity.low => AppColors.success,
        IssueSeverity.medium => AppColors.warning,
        IssueSeverity.high => AppColors.danger,
      };
}

enum SignatureRole { landlord, tenant }

class PropertyRecord {
  const PropertyRecord({
    required this.id,
    required this.name,
    required this.address,
    required this.image,
  });

  final String id;
  final String name;
  final String address;
  final String image;
}

class IssueRecord {
  const IssueRecord({
    required this.id,
    required this.item,
    required this.condition,
    required this.severity,
    required this.note,
  });

  final String id;
  final String item;
  final RoomCondition condition;
  final IssueSeverity severity;
  final String note;
}

class RoomRecord {
  const RoomRecord({
    required this.name,
    this.condition = RoomCondition.notStarted,
    this.note = '',
    this.photoAssets = const [],
    this.issues = const [],
  });

  final String name;
  final RoomCondition condition;
  final String note;
  final List<String> photoAssets;
  final List<IssueRecord> issues;

  RoomRecord copyWith({
    RoomCondition? condition,
    String? note,
    List<String>? photoAssets,
    List<IssueRecord>? issues,
  }) {
    return RoomRecord(
      name: name,
      condition: condition ?? this.condition,
      note: note ?? this.note,
      photoAssets: photoAssets ?? this.photoAssets,
      issues: issues ?? this.issues,
    );
  }

  String get subtitle {
    if (issues.isNotEmpty) {
      return '${issues.length} issue${issues.length == 1 ? '' : 's'} flagged';
    }
    if (note.isNotEmpty) {
      return note;
    }
    return condition.shortLabel;
  }
}

class SignatureRecord {
  const SignatureRecord({required this.name, required this.signedAt});

  final String name;
  final DateTime signedAt;

  String get dateLabel => formatDate(signedAt);
}

class InspectionRecord {
  const InspectionRecord({
    required this.id,
    required this.propertyId,
    required this.type,
    required this.date,
    required this.rooms,
    required this.status,
    required this.updatedAt,
    this.landlordSignature,
    this.tenantSignature,
  });

  final String id;
  final String propertyId;
  final InspectionType type;
  final DateTime date;
  final List<RoomRecord> rooms;
  final InspectionStatus status;
  final DateTime updatedAt;
  final SignatureRecord? landlordSignature;
  final SignatureRecord? tenantSignature;

  InspectionRecord copyWith({
    List<RoomRecord>? rooms,
    InspectionStatus? status,
    DateTime? updatedAt,
    SignatureRecord? landlordSignature,
    SignatureRecord? tenantSignature,
    bool clearLandlordSignature = false,
    bool clearTenantSignature = false,
  }) {
    return InspectionRecord(
      id: id,
      propertyId: propertyId,
      type: type,
      date: date,
      rooms: rooms ?? this.rooms,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      landlordSignature:
          clearLandlordSignature ? null : landlordSignature ?? this.landlordSignature,
      tenantSignature:
          clearTenantSignature ? null : tenantSignature ?? this.tenantSignature,
    );
  }

  int get completedRoomCount =>
      rooms.where((room) => room.condition != RoomCondition.notStarted).length;

  int get issueCount =>
      rooms.fold(0, (sum, room) => sum + room.issues.length);

  double get progress => rooms.isEmpty ? 0 : completedRoomCount / rooms.length;

  String get progressLabel => '${(progress * 100).round()}%';

  String get formattedDate => formatDate(date);

  String get signatureCountLabel {
    var count = 0;
    if (landlordSignature != null) {
      count += 1;
    }
    if (tenantSignature != null) {
      count += 1;
    }
    return '$count/2';
  }
}

class AppSummary {
  const AppSummary({
    required this.propertyCount,
    required this.draftCount,
    required this.exportedCount,
  });

  final int propertyCount;
  final int draftCount;
  final int exportedCount;
}

class AppModel extends ChangeNotifier {
  AppModel._({
    required List<PropertyRecord> properties,
    required List<InspectionRecord> inspections,
    required this.includeEmptyItems,
  })  : _properties = properties,
        _inspections = inspections;

  factory AppModel.empty() {
    return AppModel._(
      properties: const [],
      inspections: const [],
      includeEmptyItems: true,
    );
  }

  factory AppModel.showcase() {
    const property = PropertyRecord(
      id: 'property_showcase',
      name: 'Harbor View Loft',
      address: '145 Harbor St, Unit 4B',
      image: 'assets/images/property_sunset.png',
    );
    final inspection = InspectionRecord(
      id: 'inspection_showcase',
      propertyId: property.id,
      type: InspectionType.moveIn,
      date: DateTime(2026, 7, 1),
      rooms: [
        const RoomRecord(name: 'Entry', condition: RoomCondition.good),
        RoomRecord(
          name: 'Living Room',
          condition: RoomCondition.needsCleaning,
          note: 'Window tracks and baseboards need attention.',
          photoAssets: const [
            'assets/images/room_living.png',
            'assets/images/room_bedroom.png',
          ],
          issues: const [
            IssueRecord(
              id: 'issue_1',
              item: 'Window tracks',
              condition: RoomCondition.needsCleaning,
              severity: IssueSeverity.low,
              note: 'Visible dust along the lower rail.',
            ),
          ],
        ),
        const RoomRecord(name: 'Kitchen', condition: RoomCondition.good),
        const RoomRecord(
          name: 'Bedroom',
          condition: RoomCondition.damaged,
          issues: [
            IssueRecord(
              id: 'issue_2',
              item: 'Closet door',
              condition: RoomCondition.damaged,
              severity: IssueSeverity.medium,
              note: 'Track alignment is off.',
            ),
          ],
        ),
        const RoomRecord(name: 'Bathroom', condition: RoomCondition.good),
        const RoomRecord(name: 'Hallway'),
      ],
      status: InspectionStatus.reviewReady,
      updatedAt: DateTime(2026, 7, 1, 10, 45),
      landlordSignature: SignatureRecord(
        name: 'Alex Morgan',
        signedAt: DateTime(2026, 7, 1),
      ),
      tenantSignature: SignatureRecord(
        name: 'Taylor Reed',
        signedAt: DateTime(2026, 7, 1),
      ),
    );
    return AppModel._(
      properties: const [property],
      inspections: [inspection],
      includeEmptyItems: true,
    );
  }

  List<PropertyRecord> _properties;
  List<InspectionRecord> _inspections;
  bool includeEmptyItems;
  int _imageCursor = 0;

  List<PropertyRecord> get properties => List.unmodifiable(_properties);
  List<InspectionRecord> get inspections => List.unmodifiable(_inspections);
  List<InspectionRecord> get recentInspections =>
      [..._inspections]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  String get datePreview => formatDate(DateTime(2026, 7, 1));

  AppSummary get summary => AppSummary(
        propertyCount: _properties.length,
        draftCount:
            _inspections.where((inspection) => inspection.status != InspectionStatus.exported).length,
        exportedCount:
            _inspections.where((inspection) => inspection.status == InspectionStatus.exported).length,
      );

  PropertyRecord? propertyById(String id) {
    for (final property in _properties) {
      if (property.id == id) {
        return property;
      }
    }
    return null;
  }

  InspectionRecord? inspectionById(String id) {
    for (final inspection in _inspections) {
      if (inspection.id == id) {
        return inspection;
      }
    }
    return null;
  }

  List<PropertyRecord> filterProperties(String query) {
    if (query.trim().isEmpty) {
      return properties;
    }
    final normalized = query.trim().toLowerCase();
    return _properties
        .where(
          (property) =>
              property.name.toLowerCase().contains(normalized) ||
              property.address.toLowerCase().contains(normalized),
        )
        .toList();
  }

  List<InspectionRecord> filterInspections(String query) {
    final sorted = recentInspections;
    if (query.trim().isEmpty) {
      return sorted;
    }
    final normalized = query.trim().toLowerCase();
    return sorted.where((inspection) {
      final property = propertyById(inspection.propertyId);
      return inspection.type.label.toLowerCase().contains(normalized) ||
          inspection.formattedDate.toLowerCase().contains(normalized) ||
          (property?.name.toLowerCase().contains(normalized) ?? false) ||
          (property?.address.toLowerCase().contains(normalized) ?? false);
    }).toList();
  }

  int inspectionCountForProperty(String propertyId) {
    return _inspections
        .where((inspection) => inspection.propertyId == propertyId)
        .length;
  }

  PropertyRecord addProperty({
    required String name,
    required String address,
  }) {
    final property = PropertyRecord(
      id: _newId('property'),
      name: name,
      address: address,
      image: propertyImages[_imageCursor++ % propertyImages.length],
    );
    _properties = [..._properties, property];
    notifyListeners();
    return property;
  }

  String createInspection({
    required String propertyId,
    required InspectionType type,
  }) {
    final inspection = InspectionRecord(
      id: _newId('inspection'),
      propertyId: propertyId,
      type: type,
      date: DateTime.now(),
      rooms: roomTemplate.map((name) => RoomRecord(name: name)).toList(),
      status: InspectionStatus.draft,
      updatedAt: DateTime.now(),
    );
    _inspections = [inspection, ..._inspections];
    notifyListeners();
    return inspection.id;
  }

  void updateRoomCondition({
    required String inspectionId,
    required String roomName,
    required RoomCondition condition,
  }) {
    _updateInspection(inspectionId, (inspection) {
      final rooms = inspection.rooms
          .map(
            (room) => room.name == roomName
                ? room.copyWith(condition: condition)
                : room,
          )
          .toList();
      return inspection.copyWith(
        rooms: rooms,
        status: _deriveStatus(inspection.copyWith(rooms: rooms)),
        updatedAt: DateTime.now(),
      );
    });
  }

  void updateRoomNote({
    required String inspectionId,
    required String roomName,
    required String note,
  }) {
    _updateInspection(inspectionId, (inspection) {
      final rooms = inspection.rooms
          .map(
            (room) =>
                room.name == roomName ? room.copyWith(note: note) : room,
          )
          .toList();
      return inspection.copyWith(
        rooms: rooms,
        status: _deriveStatus(inspection.copyWith(rooms: rooms)),
        updatedAt: DateTime.now(),
      );
    });
  }

  void addRoomPhoto({
    required String inspectionId,
    required String roomName,
    required String path,
  }) {
    _updateInspection(inspectionId, (inspection) {
      final rooms = inspection.rooms.map((room) {
        if (room.name != roomName) {
          return room;
        }
        return room.copyWith(photoAssets: [...room.photoAssets, path]);
      }).toList();
      return inspection.copyWith(rooms: rooms, updatedAt: DateTime.now());
    });
  }

  void removeRoomPhoto({
    required String inspectionId,
    required String roomName,
    required String asset,
  }) {
    _updateInspection(inspectionId, (inspection) {
      final rooms = inspection.rooms.map((room) {
        if (room.name != roomName) {
          return room;
        }
        final photos = [...room.photoAssets]..remove(asset);
        return room.copyWith(photoAssets: photos);
      }).toList();
      return inspection.copyWith(rooms: rooms, updatedAt: DateTime.now());
    });
  }

  void addIssue({
    required String inspectionId,
    required String roomName,
    required String item,
    required RoomCondition condition,
    required IssueSeverity severity,
    required String note,
  }) {
    _updateInspection(inspectionId, (inspection) {
      final rooms = inspection.rooms.map((room) {
        if (room.name != roomName) {
          return room;
        }
        final issues = [
          ...room.issues,
          IssueRecord(
            id: _newId('issue'),
            item: item,
            condition: condition,
            severity: severity,
            note: note,
          ),
        ];
        return room.copyWith(
          issues: issues,
          condition: room.condition == RoomCondition.notStarted
              ? condition
              : room.condition,
        );
      }).toList();
      return inspection.copyWith(
        rooms: rooms,
        status: _deriveStatus(inspection.copyWith(rooms: rooms)),
        updatedAt: DateTime.now(),
      );
    });
  }

  void removeIssue({
    required String inspectionId,
    required String roomName,
    required String issueId,
  }) {
    _updateInspection(inspectionId, (inspection) {
      final rooms = inspection.rooms.map((room) {
        if (room.name != roomName) {
          return room;
        }
        final issues = room.issues.where((issue) => issue.id != issueId).toList();
        return room.copyWith(issues: issues);
      }).toList();
      return inspection.copyWith(rooms: rooms, updatedAt: DateTime.now());
    });
  }

  void captureSignature({
    required String inspectionId,
    required SignatureRole role,
    required String name,
  }) {
    if (name.isEmpty) {
      return;
    }
    final signature = SignatureRecord(name: name, signedAt: DateTime.now());
    _updateInspection(inspectionId, (inspection) {
      final updated = switch (role) {
        SignatureRole.landlord => inspection.copyWith(
            landlordSignature: signature,
            updatedAt: DateTime.now(),
          ),
        SignatureRole.tenant => inspection.copyWith(
            tenantSignature: signature,
            updatedAt: DateTime.now(),
          ),
      };
      return updated.copyWith(status: _deriveStatus(updated));
    });
  }

  void clearSignatures(String inspectionId) {
    _updateInspection(inspectionId, (inspection) {
      final updated = inspection.copyWith(
        clearLandlordSignature: true,
        clearTenantSignature: true,
        updatedAt: DateTime.now(),
      );
      return updated.copyWith(status: _deriveStatus(updated));
    });
  }

  void markExported(String inspectionId) {
    _updateInspection(
      inspectionId,
      (inspection) => inspection.copyWith(
        status: InspectionStatus.exported,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void setIncludeEmptyItems(bool value) {
    includeEmptyItems = value;
    notifyListeners();
  }

  void _updateInspection(
    String inspectionId,
    InspectionRecord Function(InspectionRecord inspection) update,
  ) {
    _inspections = _inspections.map((inspection) {
      if (inspection.id != inspectionId) {
        return inspection;
      }
      return update(inspection);
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  InspectionStatus _deriveStatus(InspectionRecord inspection) {
    if (inspection.status == InspectionStatus.exported) {
      return InspectionStatus.exported;
    }
    if (inspection.completedRoomCount >= 3) {
      return InspectionStatus.reviewReady;
    }
    return InspectionStatus.draft;
  }

  String _newId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

Future<File> _buildPdfFile(
  InspectionRecord inspection,
  PropertyRecord property,
) async {
  final pdf = pw.Document();
  final heroImage = await _loadPdfImage(property.image);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(18),
            border: pw.Border.all(color: PdfColor.fromHex('#E4E7EC')),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'RENTAL INSPECTION REPORT',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#475467'),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                property.name,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '${inspection.type.label} - ${inspection.formattedDate}',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                property.address,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColor.fromHex('#667085'),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.ClipRRect(
                horizontalRadius: 16,
                verticalRadius: 16,
                child: pw.Image(heroImage, height: 180, fit: pw.BoxFit.cover),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          children: [
            _pdfMetricCard('Rooms Complete',
                '${inspection.completedRoomCount}/${inspection.rooms.length}'),
            pw.SizedBox(width: 10),
            _pdfMetricCard('Issues', '${inspection.issueCount}'),
            pw.SizedBox(width: 10),
            _pdfMetricCard('Signatures', inspection.signatureCountLabel),
          ],
        ),
        pw.SizedBox(height: 22),
        pw.Text(
          'Room Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        ...inspection.rooms.map((room) => _pdfRoomSection(room)),
        pw.SizedBox(height: 18),
        pw.Text(
          'Signatures',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        _pdfSignatureRow(
          'Landlord / Manager',
          inspection.landlordSignature?.name ?? 'Not signed',
          inspection.landlordSignature?.dateLabel ?? '-',
        ),
        pw.SizedBox(height: 8),
        _pdfSignatureRow(
          'Tenant / Occupant',
          inspection.tenantSignature?.name ?? 'Not signed',
          inspection.tenantSignature?.dateLabel ?? '-',
        ),
      ],
    ),
  );

  final directory = await getApplicationDocumentsDirectory();
  final fileName =
      '${_sanitizeFileName(property.name)}-${inspection.type.label.toLowerCase()}-${inspection.date.year}${inspection.date.month.toString().padLeft(2, '0')}${inspection.date.day.toString().padLeft(2, '0')}.pdf';
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(await pdf.save(), flush: true);
  return file;
}

Future<pw.MemoryImage> _loadPdfImage(String path) async {
  final Uint8List bytes;
  if (path.startsWith('assets/')) {
    final asset = await rootBundle.load(path);
    bytes = asset.buffer.asUint8List();
  } else {
    bytes = await File(path).readAsBytes();
  }
  return pw.MemoryImage(bytes);
}

pw.Widget _pdfMetricCard(String label, String value) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#667085'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _pdfRoomSection(RoomRecord room) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      borderRadius: pw.BorderRadius.circular(14),
      border: pw.Border.all(color: PdfColor.fromHex('#E4E7EC')),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              room.name,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              room.condition.shortLabel,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('#475467'),
              ),
            ),
          ],
        ),
        if (room.note.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            room.note,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColor.fromHex('#667085'),
            ),
          ),
        ],
        if (room.issues.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          ...room.issues.map(
            (issue) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '- ${issue.item}: ${issue.condition.shortLabel} (${issue.severity.label})${issue.note.isEmpty ? '' : ' - ${issue.note}'}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _pdfSignatureRow(String role, String name, String date) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#F8FAFC'),
      borderRadius: pw.BorderRadius.circular(12),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              role,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#667085'),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              name,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
        pw.Text(
          date,
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColor.fromHex('#667085'),
          ),
        ),
      ],
    ),
  );
}

String _sanitizeFileName(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

const roomTemplate = [
  'Entry',
  'Living Room',
  'Kitchen',
  'Bedroom',
  'Bathroom',
  'Hallway',
  'Laundry',
  'Garage',
  'Exterior',
];

const propertyImages = [
  'assets/images/property_sunset.png',
  'assets/images/property_maple.png',
  'assets/images/property_beach.png',
];

const roomPhotoImages = [
  'assets/images/room_living.png',
  'assets/images/room_bedroom.png',
  'assets/images/room_living.png',
];
