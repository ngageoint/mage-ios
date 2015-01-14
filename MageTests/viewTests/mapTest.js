var app = UIATarget.localTarget().frontMostApp();
if (navigateToMap(app)) {
  UIALogger.logDebug("Starting map view tests");

  app.mainWindow().logElementTree();

  test("Hide Observations", function(target, app) {
    var map = app.mainWindow().elements()[1];
    map.logElementTree();
    assertTrue(map.elements().withName("Observation").length != 0, "There are no observations on the map and there should be");
    app.mainWindow().buttons()["Map Settings"].tap();
    app.mainWindow().tableViews()[0].cellNamed("Observations").switches()[0].tap();
    app.mainWindow().navigationBar().leftButton().tap();
    assertTrue(isRootMageView(app), "Did not navigate back to the map");
    map = app.mainWindow().elements()[1];
    assertTrue(map.elements().withName("Observation").length == 0, "There are observations on the map and there should not be");
    map.logElementTree();
    app.mainWindow().buttons()["Map Settings"].tap();
    app.mainWindow().tableViews()[0].cellNamed("Observations").switches()[0].tap();
    app.mainWindow().navigationBar().leftButton().tap();
    assertTrue(isRootMageView(app), "Did not navigate back to the map");
    map = app.mainWindow().elements()[1];
    assertTrue(map.elements().withName("Observation").length != 0, "There are no observations on the map and there should be");

  });

} else {
  UIALogger.logDebug("Tests not run, this is not the map screen");
}
