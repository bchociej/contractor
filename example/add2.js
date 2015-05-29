// Example: add 2 to input
var Contractor = require('../');
var c = new Contractor();

// the work function, which is executed in a different process
// adds 2 to the input argument, or throws if argument isn't a number
function add2(x) {
	if(typeof(x) !== 'number') {
		throw new TypeError('not a number: ' + x);
	}

	return x + 2;
}

// successful example
c.doWork(add2, [5]).then(function(result) { console.log(result); });

// error example, 1 second later
setTimeout(function() {
	c.doWork(add2, ['hi mom']).catch(function(error) { console.trace(error); });
}, 1000);
