// Diese Funktion wird aufgerufen, sobald das Dokument im Browser von
// Sketchup vollständig geladen ist.
$(function() {
  
  /* Debug-Log-Funktion. In dem HTML ist ein verstecktes Element vorhanden,
  ** in das die Ausgaben ausgegeben werden. Durch das entfernen des Zeilen-
  ** Kommentars in der nächsten Zeile werden die Ausgaben sichtbar
  */
  // $('#debug').show();
  var log = function(string, text) {
    $('#debug')[0].value += (string + ": " + text + "\n");
  };
  
  // Hilfsfunktion für Zahlenvalidierungen  
  var ifNaN = function(val, fun) {
    if(isNaN(val)) fun();
  };

  /* Callback für das Ausfüllen der Vorgabewerte. Da man von Ruby aus nur 
  ** globale JavaScript-Funktionen aufrufen kann, wird die Funktion an das
  ** window-Objekt gehängt.
  */ 

  window.gewinde_vorgaben_ausfuellen = function(innerRadius,outerRadius,length,lead,angle) {
    $('#innenradius').val(innerRadius);
    $('#aussenradius').val(outerRadius);
    $('#laenge').val(length);
    $('#steigung').val(lead);
    $('#oeffnungswinkel').val(angle);
  };

  /* Validierungen für das Formular. Hier wird das Abschicken des Formulars
  ** Mit Hilfe des submit-Events abgefangen und im Fehlerfall unterbunden
  */ 
  $('#gewinde').submit(function(e) {
    var fehler = [];
    // Zurücksetzen der Fehleranzeigen
    $("#fehler").html("");
    $('#gewinde input').removeClass("fehler");
    // Ist Innenradius eine Zahl?
    var innenradius = parseFloat($('#innenradius').val());
    ifNaN(innenradius, function() {
      $('#innenradius').addClass('fehler');
      fehler.push("Innenradius ist keine gültige Zahl oder fehlt");
    });
    // ...
    var aussenradius = parseFloat($('#aussenradius').val());
    ifNaN(aussenradius, function() {
      $('#aussenradius').addClass('fehler');
      fehler.push("Aussenradius ist keine gültige Zahl oder fehlt");
    });    
    // ...
    var dicke = parseFloat($('#aussenradius').val()) - parseFloat($('#innenradius').val());
    if (dicke <= 0) {
      $('#aussenradius', '#innenradius').addClass('error');
      fehler.push("Aussenradius muss größer als Innenradius sein");
    }
    // ...
    var steigung = parseFloat($('#steigung').val());
    ifNaN(steigung, function() {
      $('#steigung').addClass('fehler');
      fehler.push("Steigung ist keine gültige Zahl oder fehlt");
      
    });
    // Der Öffnungswinkel wird zur weiteren Betrachtung gleich ins Bogenmaß konvertiert
    var oeffnungswinkel = (parseFloat($('#oeffnungswinkel').val()) / 180) * Math.PI;
    ifNaN(oeffnungswinkel, function() {
      $('#oeffnungswinkel').addClass('fehler');
      fehler.push("Flankenwinkel ist keine gültige Zahl oder fehlt");
      
    });
    /* Überprüfung der minimal notwendigen Steigung bei gegebenem Öffnungswinkel
    ** Der Tangens-Winkel entspricht dabei 90°  (bzw. 1/2 * PI im Bogenmaß) minus
    ** dem halben Öffnungswinkel.
    */
    
    var minimalsteigung = dicke / Math.tan((Math.PI / 2) - (oeffnungswinkel / 2 ));
    log("minlead", minimalsteigung);
    if (minimalsteigung > (steigung / 2)) {
      $('#steigung', '#aussenradius', '#innenradius', '#oeffnungswinkel').addClass('fehler');
      fehler.push("Die Werte ergeben kein wohlgeformtes Gewinde");
    }
    // Anzeige der Fehler, wenn vorhanden
    if (fehler.length > 0) {
      var fehlerMarkup = "<ul>";
      $.each(fehler, function(){
        fehlerMarkup += ("<li>" + this + "</li>");
      });
      fehlerMarkup += "</ul>";
      $("#fehler").html(fehlerMarkup);
      // Rückgabe von false verhindert das Absenden des Formulars
      return false;
    } else {
      return true;
    }
    
  });
  // Am Ende wird der Ruby-Callback aufgerufen, der die Vorgabewerte setzt.
  window.location = "skp:gewinde_vorgaben_ausfuellen@bitte";
});