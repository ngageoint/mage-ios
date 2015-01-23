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

function navigateToLogin(app) {
  if (isLoginScreen(app.mainWindow())) return true;
  if (isDisclaimerScreen(app.mainWindow())) return navigateFromDisclaimerToLogin(app);
  logout(app);
  navigateFromDisclaimerToLogin(app);
}

function navigateFromDisclaimerToLogin(app) {
  var buttonArray = app.mainWindow().buttons();
  app.mainWindow().buttons()["Agree"].tap();
}

function isLoggedIn(app) {

}

function logout(app) {
  var navBar = app.navigationBar();
  if (navBar != null) {
    while (navBar != null && navBar.leftButton().checkIsValid()) {
      navBar.leftButton().tap();
      navBar = app.navigationBar();
    }
    var tabBar = app.tabBar();
    tabBar.buttons()["More"].tap();
    var table = app.mainWindow().tableViews()[0];
    table.cellNamed("Log Out").tap();
  }
}

function login(mainWindow) {
  mainWindow.textFields()["Username"].setValue(username);
  mainWindow.secureTextFields()["Password"].setValue(password);
  mainWindow.buttons()["Log In"].tap();
  mainWindow.waitUntilNotFoundByName("Log In", 5);
}

function badLogin(mainWindow) {
  mainWindow.textFields()["Username"].setValue(username);
  mainWindow.secureTextFields()["Password"].setValue("Wrong");
  mainWindow.buttons()["Log In"].tap();
  mainWindow.textViews()["Login Status"].waitUntilVisible(5);
}

function navigateToMap(app) {
  var navBar = app.navigationBar();
  if (isRootMageView(app)) return true;
  if (navBar != null) {
    while (navBar != null && navBar.leftButton().checkIsValid()) {
      navBar.leftButton().tap();
      navBar = app.navigationBar();
    }
  } else {
    login(app.mainWindow());
  }
  return isRootMageView(app);
}
