$.ajaxSetup({ cache: true });
var scorecard_template  = Handlebars.compile($("#scorecard-template").html());
var barchart_template   = Handlebars.compile($("#barchart-template").html());
var summaries_template  = Handlebars.compile($("#summaries-template").html());

var app = {
  // Application Constructor
  initialize: function() {
    document.addEventListener('DOMContentLoaded', this.onDeviceReady, false);
    app.getHostname();
  },

  year: '',
  apiurl: '',

  onDeviceReady: function() {
    app.setActiveYear();

    $('.nav-tabs li a').click(function(e){
      e.preventDefault();
      $('#scorecards li').remove();
      app.setActiveYear( $(this).attr('href').split('=')[1] );
    });

    $('#strokes_over_par_bar').on('mouseenter', 'li', function(){
      $('.barchart li').removeClass('active');
      $("#scorecards > li").hide();

      $li = $(this);
      $li.addClass('active');

      $("#scorecards li[data-id='"+$li.data('rel')+"']").show();
    });
  },

  getUrlParameter: function(sParam){
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++)
    {
      var sParameterName = sURLVariables[i].split('=');
      if (sParameterName[0] == sParam)
      {
        return sParameterName[1];
      }
    }
  },

  getHostname: function(href) {
    var l = document.createElement("a");
    l.href = href;
    app.apiurl = l.host;
    return app.apiurl;
  },

  setActiveYear: function(year){
    if(app.year == ''){
      app.year = app.getUrlParameter('year');
      if(typeof app.year === "undefined"){ app.year = "2015"; }
    }
    $('.nav-tabs li').removeClass('active');
    $('a[href*="'+app.year+'"]').addClass('active');
    app.getScorecards();
  },

  getScorecards: function() {
    $.getJSON('http://'+app.apiurl+'/scorecards?year='+app.year, function(data){
      $.each( data, function( key, val ) {
        app.createCharts(val);
        app.setupSummaries(val);
        $.each( val, function( key, val ) {
          app.addScorecardToList(val);
        });
      });
    });
  },

  addScorecardToList: function(scorecard) {
    $("#scorecards").prepend( scorecard_template(scorecard) );
    app.setupScorecardGraphs(scorecard);
  },

  setupScorecardGraphs: function(scorecard){
    var id = scorecard.id;
    $list = $('li[data-id="scorecard_'+id+'"]');

    $list.find(".smallDonut").smallDonut(scorecard.scoring_distribution, 100);

    gir_percentage = parseFloat((scorecard.girs/scorecard.scores_count)*100).toFixed(0);
    $list.find(".gir .smallPie").smallDonut([gir_percentage, (100-gir_percentage)], 100);

    fir_percentage = parseFloat((scorecard.firs/scorecard.not_par_three_holes)*100).toFixed(0);
    $list.find(".fir .smallPie").smallDonut([fir_percentage, (100-fir_percentage)], 100);


    var consistency = scorecard.consistency;
    var width  = $list.width();
    var bargap = 1;
    var all = consistency.length;
    var barwidth = Math.floor((width-bargap)/(all));

    function createStrokeBar(element, index, array) {
      border_top = get_border_top_by_stroke(element);
      color = get_color_by_stroke(element);
      name  = get_name_by_stroke(element);

      data = {score_color: color, value: name, border_top: border_top, width: barwidth, bargap: bargap, color: color}
      // html += barchart_template(data);
      $list.find('#strokebar').append( barchart_template(data) );
    };
    consistency.forEach(createStrokeBar);

  },

  createCharts: function(raw_scorecards){
    var $el = $('#strokes_over_par_bar')

    var height = $el.height();
    var width  = $el.width();
    var bargap = 1;

    var maxvalue = Array.maxProp(raw_scorecards, 'strokes')+10;
    var factor = height/maxvalue;
    var all = raw_scorecards.length;
    var barwidth = Math.floor((width-bargap)/(all));

    last_id = 0;
    $.each( raw_scorecards, function( key, val ) {
      var value = val.strokes;
      border_top = Math.floor(height-(value*factor));

      data = { id: val.id, value: value, border_top: border_top, width: barwidth, bargap: bargap}
      last_id = val.id;
      $el.append( barchart_template(data) );
    });

    $('li[data-rel="scorecard_'+last_id+'"]').addClass('active');
  },

  setupSummaries: function(raw_scorecards){
    var $el = $('#summaries');
    rounds    = raw_scorecards.length;
    avg_score = Array.avgProp(raw_scorecards, 'strokes');
    gir_avg   = parseFloat(((Array.sumProp(raw_scorecards, 'girs')/ Array.sumProp(raw_scorecards, 'scores_count')) * 100).toFixed(1));
    fir_avg   = parseFloat(((Array.sumProp(raw_scorecards, 'firs')/ Array.sumProp(raw_scorecards, 'not_par_three_holes')) * 100).toFixed(1));
    avg_putts = parseFloat((Array.sumProp(raw_scorecards, 'putts')/ Array.sumProp(raw_scorecards, 'scores_count')).toFixed(2));

    //TEMPORARY PLAY DATA
    aggregated_data = {
      'ROUNDS': rounds,
      'AVG. SCORE': avg_score,
      'GIR': gir_avg+'%',
      'FIR': fir_avg+'%',
      'AVG. PUTTS': avg_putts,
      'AVG. GIR PUTTS': 1.9,
      // scoring_distribution_avg: [0, 6, 56, 34, 4],
      // par_3: 3.6,
      // par_4: 4.2,
      // par_5: 5.5,
      // scrambling: 24,
      // sand_saves: 45
    }


    $.each( aggregated_data, function( key, val ) {
      data = { what: key, value: val }
      $el.append( summaries_template(data) );
    });
  }
};
