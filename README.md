Community Circles
=================

Mobile client for Community Circles

Install
-------

- If `dist` folder in `www/components/mapbox.js/` doesn't exist, run `make` inside folder.
  Afterwards a build of mapbox.js is in `dist`, however `node_modules` in the same directory must be removed (`rm -rf node_modules`, otherwise steroids has troubles with malformed coffee scripts).
- Run `npm install` and `bower install` in project root folder.

The app uses following custom PhoneGap plugins:

- [PhoneGap-Geofencing](https://github.com/radshag/PhoneGap-Geofencing)
- [Cordova LocalNotification-Plugin](https://github.com/katzer/cordova-plugin-local-notifications)
- [Background Tracking plugin](https://github.com/AppGyver/BackgroundTracking)

Therefore it is neccessary to build a custom Scanner app, in order to run the app.
Register an account at [AppGyver](https://cloud.appgyver.com/users/sign_up), afterwards you can link your local Steroids environment with your account by typing `steroids login`.
For Android goto [your applicatoins](https://cloud.appgyver.com/applications/) and specify following configuration:

**Android Build Settings**

```
[
  {"source": "https://github.com/radshag/PhoneGap-Geofencing.git"},
  {"source": "https://github.com/katzer/cordova-plugin-local-notifications"},
  {"source": "https://github.com/AppGyver/BackgroundTracking"}
]
```

Note that you also have to specify other attributes, see [Android Build Configuration](http://guides.appgyver.com/steroids/guides/cloud_services/android-build-config/)

**.keystore file**

`keytool -genkey -v -keystore community-circles-mobile.keystore -alias ccm_keystore_alias
-keyalg RSA -keysize 2048 -validity 10000`

Upload this file, specify a password and use `ccm_keystore_alias` as alias name.

Afterwards you can press `Build Scanner` and upload to your phone.

**API Keys**

The client needs severeal API keys, e.g. from Foursquare.

- To create a Foursquare app go to [https://foursquare.com/developers/register](https://foursquare.com/developers/register).

Provide a `key.coffee` file in `app/community-circles/` with following content:

```
@key =
  FOURSQUARE_CLIENT_ID: <client_id>
  FOURSQAURE_CLIENT_SECTRET: <client_secret>
```

Debug
-----

Run `steroids connect`, on OSX you can run the simulator then by typing `simulator`.
More information on the [Steroids documentation](http://guides.appgyver.com/steroids/guides/debugging/safari-web-inspector/).

You can also run the project in your browser by typing `steroids connect --serve` (server is available at `http://localhost:4000/`). 

For other platforms refere to [http://guides.appgyver.com/steroids/guides/debugging/best-practices/](http://guides.appgyver.com/steroids/guides/debugging/best-practices/).

Deploy
------

`steroids deploy`


Editor
------

Indent using spaces, space width: 2

Contributors
------------

- [Leaflet MaskCanvas](https://github.com/domoritz/leaflet-maskcanvas) by [domoritz](https://github.com/domoritz)
