// Please put only the following in this file:
// 1. verification tests for each view
// 2. special methods to get back to known screens for starting a test

function isLoginScreen(mainWindow) {
  var buttonArray = mainWindow.buttons();
  return buttonArray.withName("Log In").length == 1;
}

function isDisclaimerScreen(mainWindow) {
  var buttonArray = mainWindow.buttons();
  return buttonArray.length == 1 && buttonArray.withName("Agree").length == 1;
}

function isRootMageView(app) {
  return app.navigationTitle() == "Map";
}

function isSignUpScreen(mainWindow) {
  var buttonArray = mainWindow.buttons();
  return buttonArray.withName("Sign Up").length == 1;
}
