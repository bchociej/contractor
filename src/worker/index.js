require('coffee-script').register();
var Worker = require('./worker');

new Worker(process.argv[2] || process.cwd());
