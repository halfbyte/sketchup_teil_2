$(function() {
  
  var log = function(string, text) {
    $('#debug')[0].value += (string + ": " + text + "\n");
  };
  
  var ifNaN = function(val, fun) {
    if(isNaN(val)) fun();
  };
  
  window.gewinde_vorgaben_ausfuellen = function(innerRadius,outerRadius,length,lead,angle) {
    $('#innenradius').val(innerRadius);
    $('#aussenradius').val(outerRadius);
    $('#laenge').val(length);
    $('#steigung').val(lead);
    $('#oeffnungswinkel').val(angle);
  };
  
  $('#gewinde').submit(function(e) {
    var fehler = [];
    $("#fehler").html("");
    $('#gewinde input').removeClass("fehler");
    
    var innenradius = parseFloat($('#innenradius').val());
    ifNaN(innenradius, function() {
      $('#innenradius').addClass('fehler');
      fehler.push("Innenradius ist keine gültige Zahl oder fehlt");
    });        
    var aussenradius = parseFloat($('#aussenradius').val());
    ifNaN(aussenradius, function() {
      $('#aussenradius').addClass('fehler');
      errors.push("Aussenradius ist keine gültige Zahl oder fehlt");
    });    
    var thickness = outer_radius - inner_radius;
    if (thickness <= 0) {
      $('#aussenradius', '#innenradius').addClass('error');
      errors.push("Aussenradius muss größer als Innenradius sein");
    }

    var steigung = parseFloat($('#steigung').val());
    ifNaN(lead, function() {
      $('#steigung').addClass('fehler');
      fehler.push("Steigung ist keine gültige Zahl oder fehlt");
      
    });
    var oeffnungswinkel = parseFloat($('#oeffnungswinkel').val()) / 180 * Math.PI;
    ifNaN(oeffnungswinkel, function() {
      $('#oeffnungswinkel').addClass('fehler');
      fehler.push("Flankenwinkel ist keine gültige Zahl oder fehlt");
      
    });
    var minimalsteigung = Math.tan(angle/2) * dicke;
    log("minlead", minimalsteigung);
    if (minimalsteigung > (lead / 2)) {
      $('#steigung', '#aussenradius', '#innenradius', '#oeffnungswinkel').addClass('fehler');
      fehler.push("Die Werte ergeben kein wohlgeformtes Gewinde");
    }
    if (fehler.length > 0) {
      var fehlerMarkup = "<ul>";
      $.each(fehler, function(){
        fehlerMarkup += ("<li>" + this + "</li>");
      });
      fehlerMarkup += "</ul>";
      $("#fehler").html(fehlerMarkup);
      return false;
    } else {
      return true;
    }
    
  });
  window.location = "skp:gewinde_vorgaben_ausfuellen@bitte";
});