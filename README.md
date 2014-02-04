Community Circles
=================

Mobile client for Community Circles

Install
-------

- If `dist` folder in `www/components/mapbox.js/` doesn't exist, run `make` inside folder.
  Afterwards a build of mapbox.js is in `dist`, however `node_modules` in the same directory must be removed (`rm -rf node_modules`, otherwise steroids has troubles with malformed coffee scripts).
- Run `npm install` and `bower install` in project root folder.


Debug
-----

Run `steroids connect`, on OSX you can run the simulator then by typing `simulator`.
More information on the [Steroids documentation](http://guides.appgyver.com/steroids/guides/debugging/safari-web-inspector/).

You can also run the project in your browser by typint `steroids connect --serve` (server is available at `http://localhost:4000/`). 

For other platform refere to [http://guides.appgyver.com/steroids/guides/debugging/best-practices/](http://guides.appgyver.com/steroids/guides/debugging/best-practices/).

Editor
------

Indent using spaces, space width: 2
