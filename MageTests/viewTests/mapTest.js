var app = UIATarget.localTarget().frontMostApp();
if (isRootMageView(app)) {
  UIALogger.logDebug("Starting map view tests");
} else {
  UIALogger.logDebug("Tests not run, this is not the map screen");
}
