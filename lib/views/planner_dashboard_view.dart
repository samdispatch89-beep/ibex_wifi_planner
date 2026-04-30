import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/planner_controller.dart';
import '../models/planner_models.dart';
import 'animated_ui.dart';
import 'responsive_breakpoints.dart';

class PlannerDashboardView extends StatelessWidget {
  const PlannerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerController>(
      builder: (context, controller, child) {
        final snapshot = controller.snapshot;
        final pages = controller.pages;
        final selectedIndex = controller.selectedIndex;
        final selectedPage = controller.selectedPage;
        final isMobile = ResponsiveBreakpoints.isMobile(context);
        final isTablet = ResponsiveBreakpoints.isTablet(context);
        final isDesktop = ResponsiveBreakpoints.isDesktop(context);
        final contentPadding = ResponsiveBreakpoints.contentPadding(context);
        final sectionSpacing = ResponsiveBreakpoints.sectionSpacing(context);

        return Scaffold(
          drawer: isDesktop
              ? null
              : _NavigationDrawer(
                  pages: pages,
                  selectedIndex: selectedIndex,
                  snapshot: snapshot,
                  onSelected: (index) {
                    Navigator.of(context).pop();
                    controller.selectPage(index);
                  },
                ),
          bottomNavigationBar: isDesktop
              ? null
              : isTablet
              ? NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: controller.selectPage,
                  destinations: [
                    for (final page in pages)
                      NavigationDestination(
                        icon: Icon(page.icon),
                        selectedIcon: Icon(page.selectedIcon),
                        label: page.label,
                      ),
                  ],
                )
              : null,
          body: SafeArea(
            child: Builder(
              builder: (context) {
                final pageBody = _buildPageContent(
                  label: selectedPage.label,
                  snapshot: snapshot,
                );

                if (!isDesktop) {
                  return Padding(
                    padding: EdgeInsets.all(contentPadding),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(contentPadding + 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10352A),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              _CompactHeader(
                                title: selectedPage.label,
                                isMobile: isMobile,
                                onMenuPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                              ),
                              SizedBox(height: sectionSpacing),
                              _StatusBanner(snapshot: snapshot),
                            ],
                          ),
                        ),
                        SizedBox(height: sectionSpacing),
                        Expanded(
                          child: Column(
                            children: [
                              _TopBar(
                                title: selectedPage.label,
                                snapshot: snapshot,
                                compact: true,
                              ),
                              SizedBox(height: sectionSpacing),
                              Expanded(
                                child: AnimatedPageSwitcher(
                                  transitionKey: selectedPage.label,
                                  child: pageBody,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Container(
                      width: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10352A),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, sidebarConstraints) {
                          return SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: sidebarConstraints.maxHeight,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _BrandHeader(),
                                  SizedBox(height: sectionSpacing + 6),
                                  _StatusBanner(snapshot: snapshot),
                                  SizedBox(height: sectionSpacing + 6),
                                  SizedBox(
                                    height: pages.length * 72,
                                    child: NavigationRail(
                                      selectedIndex: selectedIndex,
                                      groupAlignment: -1,
                                      onDestinationSelected:
                                          controller.selectPage,
                                      backgroundColor: Colors.transparent,
                                      indicatorColor: const Color(0xFFB7F0C1),
                                      selectedIconTheme: const IconThemeData(
                                        color: Color(0xFF10352A),
                                      ),
                                      unselectedIconTheme: const IconThemeData(
                                        color: Colors.white70,
                                      ),
                                      selectedLabelTextStyle: const TextStyle(
                                        color: Color(0xFFF3FFF6),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      unselectedLabelTextStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      destinations: [
                                        for (final page in pages)
                                          NavigationRailDestination(
                                            icon: Icon(page.icon),
                                            selectedIcon: Icon(
                                              page.selectedIcon,
                                            ),
                                            label: Text(page.label),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: sectionSpacing + 4),
                                  _SidebarFooter(
                                    isExpanded:
                                        controller.isDeploymentProfileExpanded,
                                    onToggle:
                                        controller.toggleDeploymentProfile,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          contentPadding,
                          contentPadding,
                          contentPadding,
                          18,
                        ),
                        child: Column(
                          children: [
                            _TopBar(
                              title: selectedPage.label,
                              snapshot: snapshot,
                            ),
                            SizedBox(height: sectionSpacing + 2),
                            Expanded(
                              child: AnimatedPageSwitcher(
                                transitionKey: selectedPage.label,
                                child: pageBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageContent({
    required String label,
    required PlannerSnapshot snapshot,
  }) {
    switch (label) {
      case 'RF Planner':
        return RfPlannerView(snapshot: snapshot);
      case 'Optimizer':
        return OptimizerView(snapshot: snapshot);
      case 'Insights':
        return InsightsView(snapshot: snapshot);
      case 'Integrations':
        return IntegrationsView(snapshot: snapshot);
      case 'Ops Center':
        return OperationsView(snapshot: snapshot);
      case 'Overview':
      default:
        return OverviewView(snapshot: snapshot);
    }
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.pages,
    required this.selectedIndex,
    required this.snapshot,
    required this.onSelected,
  });

  final List<DashboardPageDefinition> pages;
  final int selectedIndex;
  final PlannerSnapshot snapshot;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF10352A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandHeader(),
                  const SizedBox(height: 16),
                  _StatusBanner(snapshot: snapshot),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: pages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final page = pages[index];
                  final selected = index == selectedIndex;

                  return FadeSlideIn(
                    delay: Duration(milliseconds: 20 * index),
                    child: HoverLift(
                      borderRadius: 16,
                      hoverOffset: -2,
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: selected
                              ? const Color(0xFFE9F6EA)
                              : Colors.transparent,
                          leading: Icon(
                            selected ? page.selectedIcon : page.icon,
                            color: selected
                                ? const Color(0xFF10352A)
                                : Colors.black54,
                          ),
                          title: Text(
                            page.label,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          onTap: () => onSelected(index),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({
    required this.title,
    required this.isMobile,
    required this.onMenuPressed,
  });

  final String title;
  final bool isMobile;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final headerButton = PressScale(
      onTap: onMenuPressed,
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.menu, color: Colors.white),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              headerButton,
              const SizedBox(width: 8),
              const Expanded(child: _BrandHeader()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        headerButton,
        const SizedBox(width: 8),
        const Expanded(child: _BrandHeader()),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.isExpanded, required this.onToggle});

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF174638),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveBreakpoints.panelPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PressScale(
              onTap: onToggle,
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Deployment profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              sizeCurve: Curves.easeOutCubic,
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SidebarMetric(
                      label: 'Frontend',
                      value: 'Flutter control plane',
                    ),
                    _SidebarMetric(
                      label: 'Backend',
                      value: 'API gateway + event mesh',
                    ),
                    _SidebarMetric(
                      label: 'Data',
                      value: 'Postgres + Timeseries + Lakehouse',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFB7F0C1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.router, color: Color(0xFF10352A), size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ibex Planner',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'WiFi planning control plane',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.snapshot});

  final PlannerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFB7F0C1),
      child: HoverLift(
        borderRadius: 24,
        enableHover: !ResponsiveBreakpoints.isMobile(context),
        child: Padding(
          padding: EdgeInsets.all(ResponsiveBreakpoints.panelPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Global health',
                style: TextStyle(
                  color: Color(0xFF10352A),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.96, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Text(
                  '${snapshot.globalHealthScore}/100',
                  style: TextStyle(
                    color: const Color(0xFF10352A),
                    fontSize: ResponsiveBreakpoints.isMobile(context) ? 24 : 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Production-grade, multi-tenant planner with live telemetry and optimization workflows.',
                style: TextStyle(color: Color(0xFF10352A)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarMetric extends StatelessWidget {
  const _SidebarMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 74,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.snapshot,
    this.compact = false,
  });

  final String title;
  final PlannerSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);
    final stats = Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _TopStatChip(label: 'Sites', value: '${snapshot.activeSites}'),
        _TopStatChip(label: 'Vendors', value: '${snapshot.connectedVendors}'),
        _TopStatChip(label: 'Live clients', value: '${snapshot.liveClients}'),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Architecture, simulation, optimization, telemetry, and reporting in one operator workspace.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          SizedBox(height: spacing),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: stats),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Architecture, simulation, optimization, telemetry, and reporting in one operator workspace.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: stats),
      ],
    );
  }
}

class _TopStatChip extends StatelessWidget {
  const _TopStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return HoverLift(
      borderRadius: 18,
      enableHover: !isMobile,
      hoverOffset: -2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 16,
          vertical: isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E7DA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 2),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.98, end: 1),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveSplit extends StatelessWidget {
  const _ResponsiveSplit({
    required this.left,
    required this.right,
    this.leftFlex = 1,
  });

  final Widget left;
  final Widget right;
  final int leftFlex;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 960) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: spacing),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _ResponsiveMetricGrid extends StatelessWidget {
  const _ResponsiveMetricGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < ResponsiveBreakpoints.mobileMaxWidth;
        final isTablet =
            width >= ResponsiveBreakpoints.mobileMaxWidth &&
            width <= ResponsiveBreakpoints.tabletMaxWidth;
        final columns = isMobile ? 1 : (isTablet ? 2 : 3);
        final itemWidth = columns == 1
            ? width
            : (width - ((columns - 1) * 12)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class OverviewView extends StatelessWidget {
  const OverviewView({super.key, required this.snapshot});

  final PlannerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _ResponsiveSplit(
            leftFlex: 2,
            left: _Panel(
              title: 'System architecture',
              subtitle:
                  'Mapped directly from the RF platform requirement into deployable product layers.',
              child: Column(
                children: [
                  for (final layer in snapshot.serviceLayers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ArchitectureLayer(layer: layer),
                    ),
                ],
              ),
            ),
            right: _Panel(
              title: 'Multi-tenant footprint',
              subtitle: 'Regional tenancy and health segmentation.',
              child: Column(
                children: [
                  for (final tenant in snapshot.tenants)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TenantTile(tenant: tenant),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          _ResponsiveSplit(
            left: _Panel(
              title: 'Execution timeline',
              subtitle:
                  'Live events from simulation, optimizer, and integration services.',
              child: Column(
                children: [
                  for (final item in snapshot.timeline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TimelineTile(event: item),
                    ),
                ],
              ),
            ),
            right: const _Panel(
              title: 'Requirement coverage',
              subtitle:
                  'Each major platform module represented in the app shell.',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _RequirementChip(label: 'RF simulation'),
                  _RequirementChip(label: 'AI auto-planner'),
                  _RequirementChip(label: 'Computer vision import'),
                  _RequirementChip(label: 'Optimizer engine'),
                  _RequirementChip(label: 'Insights dashboard'),
                  _RequirementChip(label: 'Vendor integrations'),
                  _RequirementChip(label: 'Real-time analyzer'),
                  _RequirementChip(label: 'PDF reporting'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RfPlannerView extends StatelessWidget {
  const RfPlannerView({super.key, required this.snapshot});

  final PlannerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _ResponsiveSplit(
            leftFlex: 2,
            left: _Panel(
              title: 'Floor heatmap',
              subtitle:
                  'Illustrates high-fidelity propagation with AP placement overlays.',
              child: SizedBox(
                height: ResponsiveBreakpoints.isMobile(context) ? 300 : 380,
                child: CustomPaint(
                  painter: HeatmapPainter(accessPoints: snapshot.accessPoints),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            right: Column(
              children: [
                const _Panel(
                  title: 'Signal model',
                  subtitle:
                      'Core RF engine outputs required by the production planner.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormulaRow(
                        label: 'RSSI',
                        formula:
                            'TxPower - FSPL - attenuation - noise - environmental loss',
                      ),
                      SizedBox(height: 12),
                      _FormulaRow(
                        label: 'FSPL',
                        formula: '20log10(d) + 20log10(f) + 32.44',
                      ),
                      SizedBox(height: 12),
                      _FormulaRow(
                        label: 'Outputs',
                        formula: 'RSSI, SNR, throughput, interference risk',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing),
                _Panel(
                  title: 'Material attenuation',
                  subtitle: 'Profiles ready for planner calibration.',
                  child: Column(
                    children: [
                      for (final material in snapshot.materials)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MaterialTile(material: material),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          _Panel(
            title: 'Access point plan',
            subtitle:
                'Current AP layout with band, channel, and TX power for optimization.',
            child: _ResponsiveMetricGrid(
              children: [
                for (final ap in snapshot.accessPoints)
                  _AccessPointCard(accessPoint: ap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OptimizerView extends StatelessWidget {
  const OptimizerView({super.key, required this.snapshot});

  final PlannerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _Panel(
            title: 'Actionable recommendations',
            subtitle:
                'Decision engine output matching the optimizer requirement.',
            child: Column(
              children: [
                for (final action in snapshot.optimizerActions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _OptimizerTile(action: action),
                  ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          const _ResponsiveSplit(
            left: _Panel(
              title: 'Auto-planner strategy',
              subtitle:
                  'Hybrid solver approach for AP placement, power, and channel planning.',
              child: _BulletedBlock(
                items: [
                  'Constraint pre-pass for walls, floor attenuation, and mandatory no-mount zones.',
                  'Heuristic seeding for initial AP positions based on target RSSI and capacity density.',
                  'Simulated annealing or genetic search for placement and transmit power refinement.',
                  'Policy engine validates vendor capabilities before change publication.',
                ],
              ),
            ),
            right: _Panel(
              title: 'Simulation before apply',
              subtitle:
                  'Every recommendation is tested on a shadow scenario before push.',
              child: _BulletedBlock(
                items: [
                  'Replay current site topology against proposed changes.',
                  'Calculate overlap, channel contention, and expected roaming score.',
                  'Block unsafe actions when coverage drops below SLA target.',
                  'Emit approvals package for human review and vendor sync.',
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightsView extends StatelessWidget {
  const InsightsView({super.key, required this.snapshot});

  final PlannerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final chartHeight = ResponsiveBreakpoints.isMobile(context) ? 260.0 : 340.0;
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);

    return SingleChildScrollView(
      child: _ResponsiveSplit(
        leftFlex: 2,
        left: _Panel(
          title: 'Global analytics',
          subtitle:
              'Multi-site aggregation, health scoring, and historical posture.',
          child: SizedBox(
            height: chartHeight,
            child: CustomPaint(
              painter: TrendPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        right: Column(
          children: [
            const _Panel(
              title: 'Core KPIs',
              subtitle: 'Designed for the insights dashboard requirement.',
              child: Column(
                children: [
                  _MetricRow(label: 'Mean retry rate', value: '2.7%'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'Median roaming score', value: '88/100'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'Capacity headroom', value: '21%'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'Sites under watch', value: '9'),
                ],
              ),
            ),
            SizedBox(height: spacing),
            const _Panel(
              title: 'Inventory posture',
              subtitle: 'Fleet snapshot across tenants and vendors.',
              child: Column(
                children: [
                  _MetricRow(label: 'Managed APs', value: '1,662'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'BLE beacons', value: '302'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'Private 5G nodes', value: '18'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IntegrationsView extends StatelessWidget {
  const IntegrationsView({super.key, required this.snapshot});

  final PlannerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _Panel(
            title: 'Vendor connectivity',
            subtitle:
                'Unified configuration sync and drift detection across controller APIs.',
            child: Column(
              children: [
                for (final integration in snapshot.integrations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _IntegrationTile(integration: integration),
                  ),
              ],
            ),
          ),
          SizedBox(height: spacing),
          const _ResponsiveSplit(
            left: _Panel(
              title: 'Authentication flow',
              subtitle: 'How vendor API access should be established.',
              child: _BulletedBlock(
                items: [
                  'Tenant-scoped credential vault with rotated secrets.',
                  'OAuth where supported, API keys for legacy providers.',
                  'Read-only discovery path separate from write-capable apply path.',
                  'Audit events for every pulled or pushed configuration change.',
                ],
              ),
            ),
            right: _Panel(
              title: 'Data mapping',
              subtitle:
                  'Normalize cross-vendor controller objects into one planner model.',
              child: _BulletedBlock(
                items: [
                  'Site, floor, AP radio, SSID, channel, and power profiles normalized at ingest.',
                  'Drift engine compares desired-state planner values against live configuration.',
                  'Change packages generated per vendor connector before deployment.',
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OperationsView extends StatelessWidget {
  const OperationsView({super.key, required this.snapshot});

  final PlannerSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final spacing = ResponsiveBreakpoints.sectionSpacing(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          _ResponsiveSplit(
            left: const _Panel(
              title: 'Real-time analyzer',
              subtitle:
                  'Live diagnostics feed for RSSI, SNR, and channel quality.',
              child: Column(
                children: [
                  _MetricRow(label: 'Streaming radios', value: '412'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'Median RSSI', value: '-58 dBm'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'Median SNR', value: '31 dB'),
                  SizedBox(height: 12),
                  _MetricRow(label: 'Open alerts', value: '14'),
                ],
              ),
            ),
            right: _Panel(
              title: 'Report generator',
              subtitle:
                  'PDF output queue for coverage maps, assumptions, and recommendations.',
              child: Column(
                children: [
                  for (final report in snapshot.reports)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReportTile(report: report),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          const _Panel(
            title: 'Computer vision import pipeline',
            subtitle:
                'CAD, PDF, and image ingestion flow for auto wall detection.',
            child: _BulletedBlock(
              items: [
                'Parse CAD layers or rasterized floor plans into normalized document objects.',
                'Run detector for walls, doors, and windows; classify material hints when present.',
                'Convert detections to vector geometry for planner editing and RF simulation.',
                'Store immutable source files alongside editable geometry revisions.',
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: HoverLift(
        borderRadius: 24,
        enableHover: !ResponsiveBreakpoints.isMobile(context),
        child: Card(
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(
              ResponsiveBreakpoints.panelPadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchitectureLayer extends StatelessWidget {
  const _ArchitectureLayer({required this.layer});

  final ServiceLayer layer;

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(ResponsiveBreakpoints.panelPadding(context)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E4D7)),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in layer.items)
                      _RequirementChip(label: item),
                  ],
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 170,
                  child: Text(
                    layer.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in layer.items)
                        _RequirementChip(label: item),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  const _RequirementChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF114635),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TenantTile extends StatelessWidget {
  const _TenantTile({required this.tenant});

  final TenantSummary tenant;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF10352A),
                      child: Text(
                        tenant.name.substring(0, 1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tenant.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '${tenant.healthScore}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${tenant.region} • ${tenant.sites} sites',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF10352A),
                  child: Text(
                    tenant.name.substring(0, 1),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${tenant.region} • ${tenant.sites} sites',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${tenant.healthScore}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    final timePill = Container(
      width: isMobile ? null : 72,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10352A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        event.time,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final content = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            event.description,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [timePill, const SizedBox(height: 8), content],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        timePill,
        const SizedBox(width: 12),
        Expanded(child: content),
      ],
    );
  }
}

class _FormulaRow extends StatelessWidget {
  const _FormulaRow({required this.label, required this.formula});

  final String label;
  final String formula;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(formula, style: const TextStyle(color: Colors.black54)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        Expanded(
          child: Text(formula, style: const TextStyle(color: Colors.black54)),
        ),
      ],
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({required this.material});

  final MaterialProfile material;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: material.color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            material.name,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '${material.lossDb.toStringAsFixed(1)} dB',
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _AccessPointCard extends StatelessWidget {
  const _AccessPointCard({required this.accessPoint});

  final AccessPoint accessPoint;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: HoverLift(
        borderRadius: 20,
        enableHover: !ResponsiveBreakpoints.isMobile(context),
        hoverOffset: -2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                accessPoint.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text('Band: ${accessPoint.band}'),
              Text('Channel: ${accessPoint.channel}'),
              Text('TX power: ${accessPoint.powerDbm} dBm'),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptimizerTile extends StatelessWidget {
  const _OptimizerTile({required this.action});

  final OptimizerAction action;

  Color _priorityColor() {
    switch (action.priority) {
      case 'Critical':
        return const Color(0xFFB3261E);
      case 'High':
        return const Color(0xFFBE6A15);
      default:
        return const Color(0xFF1B5E20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor();
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        action.priority,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );

    return FadeSlideIn(
      child: HoverLift(
        borderRadius: 20,
        enableHover: !isMobile,
        hoverOffset: -2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDCE3EC)),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(height: 12),
                    Text(
                      action.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.detail,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      action.savingsImpact,
                      style: const TextStyle(
                        color: Color(0xFF0B6E4F),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    badge,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            action.detail,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      action.savingsImpact,
                      style: const TextStyle(
                        color: Color(0xFF0B6E4F),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _BulletedBlock extends StatelessWidget {
  const _BulletedBlock({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 8),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item)),
              ],
            ),
          ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: isMobile ? TextAlign.right : TextAlign.left,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  const _IntegrationTile({required this.integration});

  final IntegrationStatus integration;

  @override
  Widget build(BuildContext context) {
    final isHealthy = integration.status == 'Healthy';
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    final icon = CircleAvatar(
      backgroundColor: isHealthy
          ? const Color(0xFFE0F3E4)
          : const Color(0xFFFFF4DD),
      child: Icon(
        isHealthy ? Icons.check_circle : Icons.warning_amber,
        color: isHealthy ? const Color(0xFF1B5E20) : const Color(0xFFBE6A15),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          integration.vendor,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        Text(
          '${integration.managedDevices} devices • ${integration.lastSync}',
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );

    return FadeSlideIn(
      child: HoverLift(
        borderRadius: 20,
        enableHover: !isMobile,
        hoverOffset: -2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDEE6DE)),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        icon,
                        const SizedBox(width: 14),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      integration.status,
                      style: TextStyle(
                        color: isHealthy
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFBE6A15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    icon,
                    const SizedBox(width: 14),
                    Expanded(child: details),
                    Text(
                      integration.status,
                      style: TextStyle(
                        color: isHealthy
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFBE6A15),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final GeneratedReport report;

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return FadeSlideIn(
      child: HoverLift(
        borderRadius: 20,
        enableHover: !isMobile,
        hoverOffset: -2,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined),
                    const SizedBox(height: 10),
                    Text(
                      report.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      report.audience,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report.status,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            report.audience,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      report.status,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class HeatmapPainter extends CustomPainter {
  HeatmapPainter({required this.accessPoints});

  final List<AccessPoint> accessPoints;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF8FBF7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      background,
    );

    final wallPaint = Paint()
      ..color = const Color(0xFFCAD6CA)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final shelfPaint = Paint()
      ..color = const Color(0xFF9AA9A0)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final walls = [
      [
        Offset(size.width * 0.08, size.height * 0.18),
        Offset(size.width * 0.9, size.height * 0.18),
      ],
      [
        Offset(size.width * 0.08, size.height * 0.18),
        Offset(size.width * 0.08, size.height * 0.82),
      ],
      [
        Offset(size.width * 0.9, size.height * 0.18),
        Offset(size.width * 0.9, size.height * 0.82),
      ],
      [
        Offset(size.width * 0.08, size.height * 0.82),
        Offset(size.width * 0.9, size.height * 0.82),
      ],
      [
        Offset(size.width * 0.28, size.height * 0.18),
        Offset(size.width * 0.28, size.height * 0.82),
      ],
      [
        Offset(size.width * 0.55, size.height * 0.18),
        Offset(size.width * 0.55, size.height * 0.82),
      ],
      [
        Offset(size.width * 0.08, size.height * 0.46),
        Offset(size.width * 0.9, size.height * 0.46),
      ],
    ];

    for (final wall in walls) {
      canvas.drawLine(wall[0], wall[1], wallPaint);
    }

    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.28),
      Offset(size.width * 0.82, size.height * 0.28),
      shelfPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.62),
      Offset(size.width * 0.82, size.height * 0.62),
      shelfPaint,
    );

    for (int x = 0; x < size.width; x += 8) {
      for (int y = 0; y < size.height; y += 8) {
        final point = Offset(x.toDouble(), y.toDouble());
        double totalSignal = 0;

        for (final ap in accessPoints) {
          final apOffset = Offset(ap.x * size.width, ap.y * size.height);
          final distance = (point - apOffset).distance;
          totalSignal += 1 / math.max(distance, 30);
        }

        final intensity = (totalSignal * 2400).clamp(0.0, 1.0);
        final color = Color.lerp(
          const Color(0xFFFFF5C3),
          const Color(0xFF2E7D32),
          intensity,
        )!;

        canvas.drawCircle(
          point,
          10,
          Paint()..color = color.withValues(alpha: 0.18),
        );
      }
    }

    final apFill = Paint()..color = const Color(0xFF0B6E4F);
    final apStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;

    for (final ap in accessPoints) {
      final center = Offset(ap.x * size.width, ap.y * size.height);
      canvas.drawCircle(center, 16, apFill);
      canvas.drawCircle(center, 16, apStroke);
      canvas.drawCircle(
        center,
        40,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF0B6E4F).withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.accessPoints != accessPoints;
  }
}

class TrendPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE3E9E2)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final dy = size.height * (i / 4);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    final points = [
      Offset(size.width * 0.02, size.height * 0.72),
      Offset(size.width * 0.16, size.height * 0.65),
      Offset(size.width * 0.29, size.height * 0.62),
      Offset(size.width * 0.44, size.height * 0.45),
      Offset(size.width * 0.6, size.height * 0.38),
      Offset(size.width * 0.76, size.height * 0.28),
      Offset(size.width * 0.94, size.height * 0.18),
    ];

    final areaPath = Path()..moveTo(points.first.dx, size.height);
    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(points.last.dx, size.height);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x8026A65B), Color(0x1026A65B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = const Color(0xFF0B6E4F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    for (final point in points) {
      canvas.drawCircle(point, 6, Paint()..color = const Color(0xFF0B6E4F));
      canvas.drawCircle(point, 10, Paint()..color = const Color(0x300B6E4F));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
