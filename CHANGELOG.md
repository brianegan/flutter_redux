# Changelog

## 0.3.2

  * Optional `onInit` function - The `StoreConnector` and `StoreBuilder` Widgets now accept an `onInit` function that will be run the first time the Widget is created (using Store.initState under the hood). The `onInit` function takes the Store as the first parameter, and can be used to dispatch actions when your Widget is first starting up. This can be useful for data fetching.
  * `rebuildOnNull` boolean option - `StoreConnector` now has an optional boolean `rebuildOnNull`. If your `converter` function produces a null value in response to a store `onChange` event, it will not rebuilt the Widget using the `builder` function. This can be useful for Widgets that need to display information that has been removed from the Store, but needs to be displayed as it animates off the screen.
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
