# Changelog

## 0.5.3

  * Maintenance update
      * Remove dependency on test package, conflicts with latest Flutter
      * Update docs
      * Update example dependencies to latest versions
      * Apply stricter analysis options

## 0.5.2

  * Add `onDidChange` -- This callback will be run after the ViewModel has changed and the builder method is called
  * Add `onInitialBuild` -- This callback will be run after the builder method is called the first time

## 0.5.1

  * Add more advice to error message

## 0.5.0

  * Updated to work with latest version of Redux: 3.0.0

## 0.4.1

  * Update example to wrap entire app with StoreProvider
  * Throw more helpful error message if no StoreProvider is found in the tree

## 0.4.0

  * Works with Dart 2 (no longer supports Dart 1)
  * Stronger Type info Required
  * Breaking Changes: 
    * `StoreProvider` now requires generic type info: `new StoreProvider<AppState>`
    * `new StoreProvider.of(context).store` is now `StoreProvider.of<AppState>(context)`
    
## 0.3.6

  * Add `onWillChange`. This function will be called before the builder and can be used for working with Imperative APIs, such as Navigator, TextEditingController, or TabController.

## 0.3.6

  * Add `onWillChange`. This function will be called before the builder and can be used for working with Imperative APIs, such as Navigator, TextEditingController, or TabController.

## 0.3.5

  * Bugfix: `onInit` was not called before the initial ViewModel is constructed. 

## 0.3.4

  * Fix Changelog. 

## 0.3.3

  * Optional `onDispose` function - The `StoreConnector` and `StoreBuilder` Widgets now accept an `onDispose` function that will be run when the Widget is removed from the Widget tree (using State.dispose under the hood). The `onDispose` function takes the Store as the first parameter, and can be used to dispatch actions that remove stale data from your State tree.
  * Move to github

## 0.3.2

  * Optional `onInit` function - The `StoreConnector` and `StoreBuilder` Widgets now accept an `onInit` function that will be run the first time the Widget is created (using State.initState under the hood). The `onInit` function takes the Store as the first parameter, and can be used to dispatch actions when your Widget is first starting up. This can be useful for data fetching.
  * `ignoreChange` function - `StoreConnector` now takes an advanced usage / optional function `ignoreChange`. It will be run on every store `onChange` event to determine whether or not the `ViewModel` and `Widget` should be rebuilt. This can be useful in some edge cases, such as displaying information that has been deleted from the store while it is animating off screen. 
  * Documentation updates

## 0.3.1

  * Add the ability to build only once, while avoiding rebuilding on change. This can be handy if you need to manage access to the Store, but want to handle when to update your own Widgets. 
  
## 0.3.0

  * Make `StoreProvider.of` a factory rather than a static method
  * Additional documentation based on questions from the community
  
## 0.2.0

  * Update for Redux 2.0.0
  
## 0.1.1

  * Update documentation

## 0.1.0

Initial Version of the library. 

  * Includes the ability to pass a Redux `Store` down to descendant Widgets using a `StoreProvider`. 
  * Includes the `StoreConnector` and `StoreBuilder` Widgets that capture the `Store` from the `StoreProvider` and build a Widget in response.
