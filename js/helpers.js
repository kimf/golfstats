/* Handlebars helpers */

Handlebars.registerHelper('shortDate', function(date) {
  return moment(date).format('Do MMMM YYYY');
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
