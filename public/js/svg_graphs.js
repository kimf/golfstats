jQuery.fn.smallDonut = function(value_array, size) {
  return this.each(function() {
    $(this).append(donutChart(value_array, size));
  });
};


function donutChart(values, size) {
  svgns = "http://www.w3.org/2000/svg";
  chart = document.createElementNS(svgns, "svg:svg");
  chart.setAttribute("width", size);
  chart.setAttribute("height", size);
  chart.setAttribute("viewBox", "0 0 " + size + " " + size);

  if(values.length == 2){
    colors = [par_color, "#ccc"];
  } else {
    colors = [eagle_color, birdie_color, par_color, bogey_color, double_color];
  }



  var centerX = size/2,
      centerY = size/2,
      cos = Math.cos,
      sin = Math.sin,
      PI = Math.PI;

  doughnutRadius = Math.min.apply(null, ([size/2,size/2])),
  cutoutRadius = doughnutRadius / 2.5;

  var startRadius = -Math.PI/2;//-90 degree
  for (var i = 0, len = values.length; i < len; i++){
    // primary wedge
    path = document.createElementNS(svgns, "path");
    value = parseInt(values[i]);

    var segmentAngle = (value/100) * (PI*2),
      endRadius = startRadius + segmentAngle,
      largeArc = ((endRadius - startRadius) % (PI * 2)) > PI ? 1 : 0,
      startX = centerX + cos(startRadius) * doughnutRadius,
      startY = centerY + sin(startRadius) * doughnutRadius,
      endX2 = centerX + cos(startRadius) * cutoutRadius,
      endY2 = centerY + sin(startRadius) * cutoutRadius,
      endX = centerX + cos(endRadius) * doughnutRadius,
      endY = centerY + sin(endRadius) * doughnutRadius,
      startX2 = centerX + cos(endRadius) * cutoutRadius,
      startY2 = centerY + sin(endRadius) * cutoutRadius;

    var cmd = [
      'M', startX, startY,//Move pointer
      'A', doughnutRadius, doughnutRadius, 0, largeArc, 1, endX, endY,//Draw outer arc path
      'L', startX2, startY2,//Draw line path(this line connects outer and innner arc paths)
      'A', cutoutRadius, cutoutRadius, 0, largeArc, 0, endX2, endY2,//Draw inner arc path
      'Z'//Cloth path
    ];

    path.setAttribute("d", cmd.join(' ')); // Set this path
    path.setAttribute("fill", colors[i]);
    chart.appendChild(path); // Add wedge to chart

    startRadius += segmentAngle;
  }
  return chart;
}