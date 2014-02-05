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

Therefore it is neccessary to build a custom Scanner app, in order to run the app.
Register an account at [AppGyver](https://cloud.appgyver.com/users/sign_up), afterwards you can link your local Steroids environment with your account by typing `steroids login`.
For Android goto [your applicatoins](https://cloud.appgyver.com/applications/) and specify following configuration:

**Android Build Settings**

```
[
  {"source": "https://github.com/radshag/PhoneGap-Geofencing.git"}
]
```

Note that you also have to specify other attributes, see [Android Build Configuration](http://guides.appgyver.com/steroids/guides/cloud_services/android-build-config/)

**.keystore file**

`keytool -genkey -v -keystore community-circles-mobile.keystore -alias ccm_keystore_alias
-keyalg RSA -keysize 2048 -validity 10000`

Upload this file, specify a password and use `ccm_keystore_alias` as alias name.

Afterwards you can press `Build Scanner` and upload to your phone.

Debug
-----

Run `steroids connect`, on OSX you can run the simulator then by typing `simulator`.
More information on the [Steroids documentation](http://guides.appgyver.com/steroids/guides/debugging/safari-web-inspector/).

You can also run the project in your browser by typint `steroids connect --serve` (server is available at `http://localhost:4000/`). 

For other platform refere to [http://guides.appgyver.com/steroids/guides/debugging/best-practices/](http://guides.appgyver.com/steroids/guides/debugging/best-practices/).

Deploy
------

`steroids deploy`


Editor
------

Indent using spaces, space width: 2
