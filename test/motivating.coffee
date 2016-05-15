Contractor = require '../lib/'
Promise = require 'bluebird'
assert = require 'assert'

# instantiate a new Contractor
c = new Contractor {workers: 8}




# Work Functions.

# synchronous example
addSync = (a, b) -> a + b

# callback example
addCb = (a, b, cb) -> cb(null, a + b)

# Promise example
addProm = (a, b) -> Promise.resolve().then -> a + b

# using require within work function
getCpus = -> require('os').cpus().length



# Dispatching Work.

# immediately and directly
c.dispatch addSync, 2, 3
.then (sum) -> assert.equal sum, 5


# wait for workers to be ready before proceeding
c.ready()
.then -> c.dispatch addSync, 'a', 'b'
.then (sum) -> assert.equal sum, 'ab'


# using a callback-style work function
c.dispatch addCb, 10, -1, c.wrapback()
.then (sum) -> assert.equal sum, 9


# using a Promise-style work function
c.dispatch addProm, 4, 7
.then (sum) -> assert.equal sum, 11


# with a convenient wrapper
wrappedAdd = c.wrap add
wrappedAdd(1, 2).then (sum) -> assert.equal sum, 3


# even wrap callback-style
wrappedAdd = c.wrap addCb
wrappedAdd(1, 2, c.wrapback()).then (sum) -> assert.equal sum, 3


# or consume the result in a callback
c.dispatch(addSync, 2, 3)
.asCallback (err, sum) -> assert.equal sum, 5
