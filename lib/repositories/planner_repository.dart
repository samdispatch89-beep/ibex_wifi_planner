import 'package:flutter/material.dart';

import '../models/planner_models.dart';

class PlannerRepository {
  PlannerSnapshot loadSnapshot() {
    return const PlannerSnapshot(
      globalHealthScore: 92,
      activeSites: 184,
      connectedVendors: 4,
      liveClients: 18264,
      tenants: [
        TenantSummary(
          name: 'NorthStar Retail',
          region: 'US-West',
          sites: 48,
          healthScore: 94,
        ),
        TenantSummary(
          name: 'Apex Logistics',
          region: 'EU-Central',
          sites: 37,
          healthScore: 89,
        ),
        TenantSummary(
          name: 'Valence Health',
          region: 'US-East',
          sites: 22,
          healthScore: 97,
        ),
      ],
      materials: [
        MaterialProfile(
          name: 'Glass wall',
          lossDb: 3.2,
          color: Color(0xFF90CAF9),
        ),
        MaterialProfile(
          name: 'Concrete',
          lossDb: 14.7,
          color: Color(0xFFB0BEC5),
        ),
        MaterialProfile(
          name: 'Metal rack',
          lossDb: 18.4,
          color: Color(0xFFA1887F),
        ),
        MaterialProfile(name: 'Drywall', lossDb: 4.6, color: Color(0xFFC5E1A5)),
      ],
      accessPoints: [
        AccessPoint(
          name: 'AP-01',
          x: 0.18,
          y: 0.28,
          channel: 36,
          powerDbm: 17,
          band: '6 GHz',
        ),
        AccessPoint(
          name: 'AP-02',
          x: 0.52,
          y: 0.18,
          channel: 44,
          powerDbm: 15,
          band: '6 GHz',
        ),
        AccessPoint(
          name: 'AP-03',
          x: 0.72,
          y: 0.58,
          channel: 149,
          powerDbm: 14,
          band: '5 GHz',
        ),
        AccessPoint(
          name: 'AP-04',
          x: 0.34,
          y: 0.72,
          channel: 1,
          powerDbm: 12,
          band: '2.4 GHz',
        ),
      ],
      optimizerActions: [
        OptimizerAction(
          priority: 'Critical',
          title: 'Reduce AP-04 transmit power to 14 dBm',
          detail:
              'Cuts overlap in the southeast office and improves sticky-client roaming.',
          savingsImpact: '+7 roaming score',
        ),
        OptimizerAction(
          priority: 'High',
          title: 'Move AP-02 to channel 100',
          detail:
              'Avoids co-channel contention with the neighboring Meraki pod on floor 3.',
          savingsImpact: '-11% retry rate',
        ),
        OptimizerAction(
          priority: 'Medium',
          title: 'Add 1 Wi-Fi 7 AP near loading bay',
          detail:
              'Warehouse handheld density exceeds target during evening peak shift.',
          savingsImpact: '+220 Mbps median throughput',
        ),
      ],
      integrations: [
        IntegrationStatus(
          vendor: 'Cisco Meraki',
          status: 'Healthy',
          lastSync: '22 sec ago',
          managedDevices: 641,
        ),
        IntegrationStatus(
          vendor: 'Aruba Central',
          status: 'Healthy',
          lastSync: '44 sec ago',
          managedDevices: 522,
        ),
        IntegrationStatus(
          vendor: 'Juniper Mist',
          status: 'Warning',
          lastSync: '4 min ago',
          managedDevices: 301,
        ),
        IntegrationStatus(
          vendor: 'ExtremeCloud IQ',
          status: 'Healthy',
          lastSync: '1 min ago',
          managedDevices: 198,
        ),
      ],
      timeline: [
        TimelineEvent(
          time: '09:14',
          title: 'RF simulation completed',
          description:
              'Floor 2 heatmaps recalculated in 1.8 seconds using GPU workers.',
        ),
        TimelineEvent(
          time: '09:09',
          title: 'Auto-planner proposed update',
          description:
              'Placed one additional AP in logistics corridor to meet -65 dBm target.',
        ),
        TimelineEvent(
          time: '09:03',
          title: 'Vendor drift detected',
          description:
              'Aruba profile diverged from planned TX settings on 12 devices.',
        ),
      ],
      reports: [
        GeneratedReport(
          title: 'Executive coverage report',
          status: 'Ready for export',
          audience: 'Leadership',
        ),
        GeneratedReport(
          title: 'Implementation runbook',
          status: 'Awaiting approval',
          audience: 'Field engineers',
        ),
        GeneratedReport(
          title: 'Standards compliance appendix',
          status: 'Building PDF',
          audience: 'Customer delivery',
        ),
      ],
      serviceLayers: [
        ServiceLayer(
          title: 'Experience Layer',
          items: [
            'Flutter control console',
            'Technician mobile workflows',
            'Role-based workspace shell',
          ],
        ),
        ServiceLayer(
          title: 'Control Plane APIs',
          items: [
            'API gateway',
            'Tenant auth + RBAC',
            'Planning orchestration',
            'Reporting APIs',
          ],
        ),
        ServiceLayer(
          title: 'Intelligence Services',
          items: [
            'RF propagation engine',
            'AI auto-planner',
            'Optimizer rules engine',
            'Computer vision ingestion',
          ],
        ),
        ServiceLayer(
          title: 'Data Platform',
          items: [
            'Postgres metadata store',
            'Timeseries telemetry store',
            'Object storage for plans/reports',
            'Event stream for live updates',
          ],
        ),
      ],
    );
  }

  List<DashboardPageDefinition> loadPages() {
    return const [
      DashboardPageDefinition(
        label: 'Overview',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
      ),
      DashboardPageDefinition(
        label: 'RF Planner',
        icon: Icons.wifi_tethering_outlined,
        selectedIcon: Icons.wifi_tethering,
      ),
      DashboardPageDefinition(
        label: 'Optimizer',
        icon: Icons.auto_graph_outlined,
        selectedIcon: Icons.auto_graph,
      ),
      DashboardPageDefinition(
        label: 'Insights',
        icon: Icons.query_stats_outlined,
        selectedIcon: Icons.query_stats,
      ),
      DashboardPageDefinition(
        label: 'Integrations',
        icon: Icons.hub_outlined,
        selectedIcon: Icons.hub,
      ),
      DashboardPageDefinition(
        label: 'Ops Center',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long,
      ),
    ];
  }
}
