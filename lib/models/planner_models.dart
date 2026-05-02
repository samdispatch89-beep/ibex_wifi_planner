import 'package:flutter/material.dart';

class PlannerSnapshot {
  const PlannerSnapshot({
    required this.globalHealthScore,
    required this.activeSites,
    required this.connectedVendors,
    required this.liveClients,
    required this.rfEngineModules,
    required this.rfPromptSequence,
    required this.performanceStrategies,
    required this.tenants,
    required this.materials,
    required this.accessPoints,
    required this.optimizerActions,
    required this.integrations,
    required this.timeline,
    required this.reports,
    required this.serviceLayers,
  });

  final int globalHealthScore;
  final int activeSites;
  final int connectedVendors;
  final int liveClients;
  final List<RfEngineModule> rfEngineModules;
  final List<RfPromptSequence> rfPromptSequence;
  final List<PerformanceStrategy> performanceStrategies;
  final List<TenantSummary> tenants;
  final List<MaterialProfile> materials;
  final List<AccessPoint> accessPoints;
  final List<OptimizerAction> optimizerActions;
  final List<IntegrationStatus> integrations;
  final List<TimelineEvent> timeline;
  final List<GeneratedReport> reports;
  final List<ServiceLayer> serviceLayers;
}

class TenantSummary {
  const TenantSummary({
    required this.name,
    required this.region,
    required this.sites,
    required this.healthScore,
  });

  final String name;
  final String region;
  final int sites;
  final int healthScore;
}

class MaterialProfile {
  const MaterialProfile({
    required this.name,
    required this.lossDb,
    required this.color,
    this.notes = '',
  });

  final String name;
  final double lossDb;
  final Color color;
  final String notes;
}

class AccessPoint {
  const AccessPoint({
    required this.name,
    required this.x,
    required this.y,
    required this.channel,
    required this.powerDbm,
    required this.band,
  });

  final String name;
  final double x;
  final double y;
  final int channel;
  final int powerDbm;
  final String band;
}

class OptimizerAction {
  const OptimizerAction({
    required this.priority,
    required this.title,
    required this.detail,
    required this.savingsImpact,
  });

  final String priority;
  final String title;
  final String detail;
  final String savingsImpact;
}

class IntegrationStatus {
  const IntegrationStatus({
    required this.vendor,
    required this.status,
    required this.lastSync,
    required this.managedDevices,
  });

  final String vendor;
  final String status;
  final String lastSync;
  final int managedDevices;
}

class TimelineEvent {
  const TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
  });

  final String time;
  final String title;
  final String description;
}

class GeneratedReport {
  const GeneratedReport({
    required this.title,
    required this.status,
    required this.audience,
  });

  final String title;
  final String status;
  final String audience;
}

class ServiceLayer {
  const ServiceLayer({required this.title, required this.items});

  final String title;
  final List<String> items;
}

class DashboardPageDefinition {
  const DashboardPageDefinition({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class RfEngineModule {
  const RfEngineModule({
    required this.title,
    required this.summary,
    required this.bullets,
  });

  final String title;
  final String summary;
  final List<String> bullets;
}

class RfPromptSequence {
  const RfPromptSequence({
    required this.step,
    required this.title,
    required this.goal,
  });

  final int step;
  final String title;
  final String goal;
}

class PerformanceStrategy {
  const PerformanceStrategy({required this.label, required this.description});

  final String label;
  final String description;
}
