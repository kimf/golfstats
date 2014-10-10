var eagle_color = '#d8c32a',
    birdie_color = '#d83a29',
    par_color = '#2ecc71',
    bogey_color = '#999',
    double_color = '#555';

var color_by_strokes = {
  '-2':  eagle_color,
  '-1':  birdie_color,
  '0':  par_color,
  '1':  bogey_color,
  '2':  double_color
}


var app = {
  // Application Constructor
  initialize: function() {
    this.bindEvents();
  },
  // Bind Event Listeners
  //
  // Bind any events that are required on startup. Common events are:
  // 'load', 'deviceready', 'offline', and 'online'.
  bindEvents: function() {
    document.addEventListener('DOMContentLoaded', this.onDeviceReady, false); //tmp to be able to play in browser

    $( "#scorecards" ).on( "addedToScreen", function( event ) {
      $(this).find(".smallpie:not(:has(*))").smallPie();
      $(this).find(".smalldonut:not(:has(*))").smallDonut();
      $(this).trigger( 'liAddedToScreen' );
    });

    $( "#scorecards" ).on( "liAddedToScreen", function( event ) {
      var ball = Impulse($(this).find('li:first-child')).style('scale', function(s) { return s })
      var li = $(this);
      ball.spring({ tension: 50, damping: 10 })
      .from(0)
      .to(1).start().then( $(li).removeClass('notanimated') );
    });
  },

  onDeviceReady: function() {
    app.getScorecards();
  },

  getScorecards: function() {
    $.getJSON('http://localhost:9292/scorecards', function(data){
       $.each( data, function( key, val ) {
          $.each( val, function( key, val ) {
            app.addScorecardToList(val);
          });
        });
    });
  },

  addScorecardToList: function(scorecard) {

    if(scorecard.scores_count != 18){
      return false ;
    }

    var source   = $("#scorecard-template").html();
    var template = Handlebars.compile(source);
    var html     = template(scorecard);

    $("#scorecards").prepend(html);
    $('#scorecards').trigger('addedToScreen');

  }
};


Handlebars.registerHelper('shortDate', function(date) {
  return moment(date).format('Do MMMM YYYY');
});

Handlebars.registerHelper('strokebar', function(strokes) {
  string = '';

  function createStrokeBar(element, index, array) {
    barHeight = (parseInt(element)*-6);
    // color = color_by_strokes[element];
    // if(typeof color === "undefined"){
    //   color = "#000";
    // }
    string = string + '<span class="bar" style="margin-top: '+barHeight+'px;"></span>';
  };

  strokes.forEach(createStrokeBar);

  return new Handlebars.SafeString(string);
});

Handlebars.registerHelper ('truncate', function (str, len) {
  if (str.length > len && str.length > 0) {
    var new_str = str + " ";
    new_str = str.substr (0, len);
    new_str = str.substr (0, new_str.lastIndexOf(" "));
    new_str = (new_str.length > 0) ? new_str : str.substr (0, len);

    return new Handlebars.SafeString ( new_str +'...' );
  }
  return str;
});

Handlebars.registerHelper('donutChart', function(values, size){
  html = '<div class="inside"><span class="smalldonut" data-values="'+values+'" data-size="'+size+'"></span></div>';
  return new Handlebars.SafeString (html);
});

Handlebars.registerHelper('pieChart', function(percentage, of, size){
  percentage = parseFloat((percentage/of)*100).toFixed(0);
  html = '<div class="inside"><span class="smallpie" data-percentage="'+percentage+'" data-size="'+size+'"></span></div>';
  return new Handlebars.SafeString (html);
});

Handlebars.registerHelper('percentage', function(size, of){
  percentage = parseFloat((size/of)*100).toFixed(0);
  return new Handlebars.SafeString (percentage+'%');
});

Handlebars.registerHelper('green_or_red', function(value, green_value, orange_value){
  if(value <= green_value){
    color = par_color;
  } else if(value <= orange_value) {
    color = eagle_color;
  } else {
    color = birdie_color;
  }
  return new Handlebars.SafeString ('<span style="color: '+color+';">'+value+'</span>');
});

jQuery.fn.smallPie = function() {
  return this.each(function() {
    p = $(this).data('percentage');
    s = $(this).data('size');
    c = $(this).data('color');
    $(this).append(pieChart(p, s, c));
  });
};

jQuery.fn.smallDonut = function() {
  return this.each(function() {
    v = $(this).data('values').split(',');
    s = $(this).data('size');
    c = $(this).data('color');
    $(this).append(donutChart(v, s, c));
  });
};


function donutChart(values, size) {
  svgns = "http://www.w3.org/2000/svg";
  chart = document.createElementNS(svgns, "svg:svg");
  chart.setAttribute("width", size);
  chart.setAttribute("height", size);
  chart.setAttribute("viewBox", "0 0 " + size + " " + size);

  colors = [eagle_color, birdie_color, par_color, bogey_color, double_color];


  var centerX = size/2,
      centerY = size/2,
      cos = Math.cos,
      sin = Math.sin,
      PI = Math.PI;

  doughnutRadius = Math.min.apply(null, ([size/2,size/2])),
  cutoutRadius = doughnutRadius / 2;

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
  // // foreground circle
  // var front = document.createElementNS(svgns, "circle");
  // front.setAttributeNS(null, "cx", (size / 2));
  // front.setAttributeNS(null, "cy", (size / 2));
  // front.setAttributeNS(null, "r",  (size * 0.17)); //about 34% as big as back circle
  // front.setAttributeNS(null, "fill", "#ecf0f1");
  // chart.appendChild(front);
  return chart;
}


function pieChart(percentage, size) {
    var svgns = "http://www.w3.org/2000/svg";
    var chart = document.createElementNS(svgns, "svg:svg");
    chart.setAttribute("width", size);
    chart.setAttribute("height", size);
    chart.setAttribute("viewBox", "0 0 " + size + " " + size);
    // Background circle
    var back = document.createElementNS(svgns, "circle");
    back.setAttributeNS(null, "cx", size / 2);
    back.setAttributeNS(null, "cy", size / 2);
    back.setAttributeNS(null, "r",  size / 2);
    back.setAttributeNS(null, "fill", "#ccc");
    back.setAttributeNS(null, "fill-opacity", "0.5");
    chart.appendChild(back);
    // primary wedge
    var path = document.createElementNS(svgns, "path");
    var unit = (Math.PI *2) / 100;
    var startangle = 0;
    var endangle = percentage * unit - 0.001;
    var x1 = (size / 2) + (size / 2) * Math.sin(startangle);
    var y1 = (size / 2) - (size / 2) * Math.cos(startangle);
    var x2 = (size / 2) + (size / 2) * Math.sin(endangle);
    var y2 = (size / 2) - (size / 2) * Math.cos(endangle);
    var big = 0;
    if (endangle - startangle > Math.PI) {
        big = 1;
    }
    var d = "M " + (size / 2) + "," + (size / 2) +  // Start at circle center
        " L " + x1 + "," + y1 +     // Draw line to (x1,y1)
        " A " + (size / 2) + "," + (size / 2) +       // Draw an arc of radius r
        " 0 " + big + " 1 " +       // Arc details...
        x2 + "," + y2 +             // Arc goes to to (x2,y2)
        " Z";                       // Close path back to (cx,cy)
    path.setAttribute("d", d); // Set this path

    if(percentage > 70){
      col = par_color;
    } else if (percentage > 50) {
      col = eagle_color;
    } else {
      col = birdie_color;
    }

    path.setAttribute("fill", col);
    chart.appendChild(path); // Add wedge to chart
    // // foreground circle
    // var front = document.createElementNS(svgns, "circle");
    // front.setAttributeNS(null, "cx", (size / 2));
    // front.setAttributeNS(null, "cy", (size / 2));
    // front.setAttributeNS(null, "r",  (size * 0.17)); //about 34% as big as back circle
    // front.setAttributeNS(null, "fill", "#ecf0f1");
    // chart.appendChild(front);
    return chart;
}