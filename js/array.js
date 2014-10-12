/* Functions to work with arrays more easily */

Array.maxProp = function (array, prop) {
  var values = array.map(function (el) {
    return el[prop];
  });
  return values.max()
};

Array.sumProp = function (array, prop) {
  var values = array.map(function (el) {
    return el[prop];
  });
  return values.reduce(function (a, b) { return a + b; }, 0);
};

Array.prototype.max = function() {
  return Math.max.apply(null, this);
};

Array.avgProp = function (array, prop) {
  var values = array.map(function (el) {
    return el[prop];
  });
  return values.avg()
}

Array.prototype.avg = function(){
    var l=this.length
    var t=0;
    for(var i=0;i<l;i++){
        t+=this[i];
    }
    return Math.floor(t/l);
}