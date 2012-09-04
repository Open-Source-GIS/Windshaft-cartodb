/*
 * Windshaft-CartoDB
 * ===============
 *
 * ./app.js [environment]
 *
 * environments: [development, production]
 */

var Cluster = require('cluster2');

// sanity check
var ENV = process.argv[2]
if (ENV != 'development' && ENV != 'production' && ENV != 'staging'){
    console.error("\nnode app.js [environment]");
    console.error("environments: [development, production, staging]\n");
    process.exit(1);
}

var _ = require('underscore')
    , Step       = require('step')
	, CartodbWindshaft = require('./lib/cartodb/cartodb_windshaft');
    

// set environment specific variables
global.settings     = require(__dirname + '/config/settings');
global.environment  = require(__dirname + '/config/environments/' + ENV);
_.extend(global.settings, global.environment);

// Include cart_data.js only _after_ the "global" variable is set
// See https://github.com/Vizzuality/Windshaft-cartodb/issues/28
var cartoData = require('./lib/cartodb/carto_data');

var Windshaft = require('windshaft');
var serverOptions = require('./lib/cartodb/server_options');

var ws = CartodbWindshaft(serverOptions);

//.use(cluster.logger('logs'))
//.use(cluster.stats())
//.use(cluster.pidfiles('pids'))
var cluster = new Cluster({
  port: global.environment.port,
  monPort: global.environment.port+1,
  noWorkers: 1 // .set('workers', 1)
});

cluster.listen(function(cb) {
  cb(ws);
});

console.log("Windshaft tileserver started on port " + global.environment.port);
