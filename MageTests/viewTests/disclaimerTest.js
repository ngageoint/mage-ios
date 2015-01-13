
test("Disclaimer Screen", function(target, app) {
  var mainWindow = app.mainWindow();

  if (!isDisclaimerScreen(mainWindow)) {
    UIALogger.logDebug("Test not run, this is not the disclaimer screen");
    return;
  }

  var buttonArray = mainWindow.buttons();
  mainWindow.buttons()["Agree"].tap();
  assertTrue(isLoginScreen(target.frontMostApp().mainWindow()), "Did not navigate to the log in screen");
});
