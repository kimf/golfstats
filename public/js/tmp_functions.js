//TODO, USE CSS INSTEAD!
var eagle_color = '#d8c32a',
    birdie_color = '#d83a29',
    par_color = '#2ecc71',
    bogey_color = '#999',
    double_color = '#555';
    tripple_color = '#000';

var color_by_strokes = {
  '-2':  eagle_color,
  '-1':  birdie_color,
  '0':  par_color,
  '1':  bogey_color,
  '2':  double_color,
  '3':  tripple_color
}
var get_color_by_stroke = function(value){
  color = color_by_strokes[value];
  if(typeof color === "undefined"){
    return tripple_color;
  }
  return color;
}

var name_by_strokes = {
  '-2': 'eagle',
  '-1': 'birdie',
  '0':  'par',
  '1':  'bogey',
  '2':  'double',
  '3':  'tripple',
  '4':  'quad',
  '5':  'quin'
}
var get_name_by_stroke = function(value){
  name = name_by_strokes[value];
  if(typeof name === "undefined"){
    return "worse";
  }
  return name;
}

var border_top_by_strokes = {
  '-2': 200,
  '-1': 180,
  '0':  160,
  '1':  140,
  '2':  120,
  '3':  100,
  '4':  80,
  '5':  60,
  '6':  40,
  '7':  20,
  '8':  0,
}
var get_border_top_by_stroke = function(value){
  border = border_top_by_strokes[value];
  if(typeof border === "undefined"){
    return 0;
  }
  return border;
}

var scoring_distribution_names = ["eagle", "birdie", "par", "bogey", "double"];
var scoring_distribution_colors = [eagle_color, birdie_color, par_color, bogey_color, double_color];