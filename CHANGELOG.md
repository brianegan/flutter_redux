# Changelog

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
