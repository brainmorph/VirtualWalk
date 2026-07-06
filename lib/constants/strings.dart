class AppStrings {
  AppStrings._();

  static const appName = 'VirtualWalker';
  static const version = 'v0.0.28';
  static const osmAttribution = '© OpenStreetMap contributors';
  static const locationPermissionDenied =
      'Location permission is required to track your walk.';
  static const locationPermissionPermanentlyDenied =
      'Location permission is permanently denied. Please enable it in app settings.';
  static const openSettings = 'Open Settings';
  static const noWalksYet = 'No walks yet. Go for a walk!';
  static const walkSaved = 'Walk saved!';
  static const confirmStopTitle = 'Stop walk?';
  static const confirmStopBody = 'Stop and save this walk?';
  static const cancel = 'Cancel';
  static const stopAndSave = 'Stop & Save';
  static const waitingForGps = 'Waiting for GPS signal…';
  static const gpsRateTitle = 'GPS snapshot rate';
  static const gpsRateTooltip = 'App options';
  static const gpsRateOpenLoop = 'Open loop — as fast as possible';
  static const gpsRateEverySecond = 'Every second';
  static const gpsRateEvery2s = 'Every 2 seconds';
  static const gpsRateEvery5s = 'Every 5 seconds';
  static const gpsRateEvery10s = 'Every 10 seconds';
  static const gpsRateEvery30s = 'Every 30 seconds';
  static const gpsRateEveryMinute = 'Every minute';
  static const recenterTooltip = 'Center on my position';
  static const saveWalkTitle = 'Save walk?';
  static const saveWalkBody =
      'Save the raw GPS points to a CSV file before they are cleared by the next walk?';
  static const saveWalkDiscard = 'Discard';
  static const saveWalkSave = 'Save CSV';
  static const saveWalkDone = 'Walk saved.';
  static const saveWalkCancelled = 'Walk not saved.';
  static const importWalkTooltip = 'Import saved walk';
  static const clearImportTooltip = 'Clear imported walk';
  static const importWalkFailed = 'Could not read a walk from that file.';
  static const projectNoWalk =
      'Record or import a walk first, then long-press to anchor it.';
  static const clearAnchorTooltip = 'Remove projected walk';
  static const centerOnProjectedTooltip = 'Center on projected position';
  static const centerOnRealTooltip = 'Center on real position';
}
