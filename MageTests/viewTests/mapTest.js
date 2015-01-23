var app = UIATarget.localTarget().frontMostApp();
if (navigateToMap(app)) {
  UIALogger.logDebug("Starting map view tests");

  app.mainWindow().logElementTree();

  // test("Hide Observations", function(target, app) {
  //   var map = app.mainWindow().elements()[1];
  //   map.logElementTree();
  //   var observations = map.elements().withName("Observation");
  //   var foundObservation = false;
  //   for (var i = 0; i < observations.length && !foundObservation; i++) {
  //     UIALogger.logDebug("Observation is visible? " + observations[i].isVisible());
  //     observations[i].logElementJSON();
  //     foundObservation = observations[i].isVisible();
  //   }
  //   assertTrue(foundObservation, "There are no observations on the map and there should be");
  //   app.mainWindow().buttons()["Map Settings"].tap();
  //   app.mainWindow().tableViews()[0].cellNamed("Observations").switches()[0].tap();
  //   app.mainWindow().navigationBar().leftButton().tap();
  //   assertTrue(isRootMageView(app), "Did not navigate back to the map");
  //   map = app.mainWindow().elements()[1];
  //   observations = map.elements().withName("Observation");
  //   var foundHiddenObservation = false;
  //   for (var i = 0; i < observations.length && !foundHiddenObservation; i++) {
  //     UIALogger.logDebug("Observation is visible? " + observations[i].isVisible());
  //     observations[i].logElementJSON();
  //     foundHiddenObservation = observations[i].isVisible();
  //   }
  //   assertFalse(foundHiddenObservation, "There are observations on the map and there should not be");
  //   map.logElementTree();
  //   app.mainWindow().buttons()["Map Settings"].tap();
  //   app.mainWindow().tableViews()[0].cellNamed("Observations").switches()[0].tap();
  //   app.mainWindow().navigationBar().leftButton().tap();
  //   assertTrue(isRootMageView(app), "Did not navigate back to the map");
  //   map = app.mainWindow().elements()[1];
  //   observations = map.elements().withName("Observation");
  //   foundObservation = false;
  //   for (var i = 0; i < observations.length && !foundObservation; i++) {
  //     UIALogger.logDebug("Observation is visible? " + observations[i].isVisible());
  //     observations[i].logElementJSON();
  //     foundObservation = observations[i].isVisible();
  //   }
  //   assertTrue(foundObservation, "There are no observations on the map and there should be");
  // });

  test("Create New Observation", function(target, app) {
    //app.mainWindow().logElementTreeJSON(["name", "label", "value", "isVisible", "isEnabled", "isValid"]);
    var navBar = app.navigationBar();
    navBar.buttons()["New"].tap();
    app.toolbar().buttons()["Gallery"].tap();
    app.mainWindow().tableViews()[0].cells()["Moments"].tap();
    app.mainWindow().collectionViews()[0].cells()[0].tap();

    UIALogger.logDebug("main window buttons " + app.mainWindow().buttons().length);
    // UIALogger.logElementJSON(app.mainWindow().buttons()[2]);
    var chooseButton = app.mainWindow().buttons()[2];
    var hitpoint = chooseButton.hitpoint();
    var rect = chooseButton.rect();

    UIALogger.logDebug(chooseButton);
    UIALogger.logDebug(hitpoint);
    UIALogger.logDebug(rect);

    UIATarget.localTarget().delay(1);
    // app.windows()[0].buttons()["Choose"].tap();
    // this is the only way I can find to tap the Choose button
    target.tap({x:273.50, y:446.00});
    
  });

} else {
  UIALogger.logDebug("Tests not run, this is not the map screen");
}
