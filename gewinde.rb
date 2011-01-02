require 'sketchup'
require 'werkzeuge'
module JK
  class Gewinde
    include JK::Werkzeuge
    def initialize(innenradius, aussenradius, laenge, steigung, oeffnungswinkel)
      @innenradius = innenradius.to_f
      @aussenradius = aussenradius.to_f
      @laenge = laenge.to_f
      @steigung = steigung.to_f
      @oeffnungswinkel = oeffnungswinkel.to_f
      
      @definition = modell.definitions.add "Gewinde"
  		@definition.insertion_point = Geom::Point3d.new(0, 0, 0)
  		
      baue_gewinde
    end
    def self.dialog
      # Webdialog erzeugen
      dialog = UI::WebDialog.new("Gewinde", false, 'gewinde-dialog', 600, 600)
      # HTML-Datei zuweisen
      dialog.set_file(File.join(File.dirname(__FILE__), 'html', 'gewinde_formular.html'))
      # Dialog anzeigen
      dialog.show
      # Callback für das ausfüllen der Vorgabe-Werte
      dialog.add_action_callback("gewinde_vorgaben_ausfuellen") do |dialog, parameter|
        dialog.execute_script("gewinde_vorgaben_ausfuellen(#{10},#{13},#{20},#{4},#{60})")
      end
      # Callback für Abbrechen
      dialog.add_action_callback("gewinde_abbrechen") do |dialog, parameter|
        dialog.close
      end
      
      # Callback fürs Erstellen
      dialog.add_action_callback("gewinde_bauen") do |dialog, parameter|
        # Auslesen der Werte aus dem Formular
        innenradius = dialog.get_element_value("innenradius").to_f
        aussenradius = dialog.get_element_value("aussenradius").to_f
        laenge = dialog.get_element_value("laenge").to_f
        steigung = dialog.get_element_value("steigung").to_f
        oeffnungswinkel = dialog.get_element_value("oeffnungswinkel").to_f
        # Dialog schliessen
        dialog.close
        # Gewinde erzeugen
        Gewinde.new(
          innenradius,
          aussenradius, 
          laenge, 
          steigung, 
          oeffnungswinkel
        ).place_component
      end
    end
    
    # Erzeugt Polygon nur, wenn alle Punkte gesetzt sind
    def bedingtes_polygon(pt1, pt2, pt3)
      if pt1 && pt2 && pt3
        @gitter.add_polygon(pt1, pt2, pt3)
      end
    end
           
    def gewindepunkt(bedingung, alpha, radius, z)
      if bedingung
        @gitter.add_point([Math.cos(alpha) * radius, Math.sin(alpha) * radius, z])
      else
        nil
      end
    end
    
    # Durch die übergebenen Punkte-Arrays gehen und bei den punkten
    # untere und obere extrema in jeweils ein array stecken,
    # da diese das gewinde oben und unten abschließen
    
    def sammle_start_und_endpunkte(*punkte_arrays)
      startpunkte = []
      endpunkte = []
      
      punkte_arrays.each do |punkte|
        punkte.each do |punkte_index|
          next if punkte_index.nil?
          punkt = @gitter.point_at(punkte_index)
          startpunkte.push(punkte_index) if punkt.z == 0
          endpunkte.unshift(punkte_index) if punkt.z == @laenge
        end
      end
      return [startpunkte, endpunkte]
    end
    
    # Erzeugen der Polygone für die Abschlussflächen des Gewindes
    def endflaeche(mittelpunkt, punkte)
      punkte.each_with_index do |punkte_index, i|
        second_index = (i + 1) % punkte.length
        @gitter.add_polygon(mittelpunkt, punkte_index, punkte[second_index])
      end      
    end
    
    def segmentpolygone(pt1, pt2, pt3, pt4)
      bedingtes_polygon(pt1, pt2, pt3)
      bedingtes_polygon(pt3, pt4, pt1)
    end
    
    def baue_gewinde
      @gitter = Geom::PolygonMesh.new
      
      # konstanten für die weiteren Berechnungen
      # Radiale Schrittweite pro Segment
      schrittweite = 2 * Math::PI / 24.0
      # Schrittweite in Z-Richtung pro segment
      z_schrittweite = @steigung.to_f / 24.0
      # Dicke des Gewindes
      dicke = @aussenradius - @innenradius

      # Vorberechnung des Tangens für den Öffnungswinkel
      tangens = Math::tan(@oeffnungswinkel / 180 * Math::PI)

      # Differenz in Z-Richtung zwischen inneren und äusseren Punkten des
      # Gewindes
      z_differenz = dicke / tangens
      # Dicke des Stegs des Gewindes
      z_steg = @steigung - z_differenz

      # zähler (der einfachheit halber bei -1 anfangend)
      i = -1
      # Arrays für die Punkte der drei reihen
      innere_punkte = []
      obere_punkte = []
      untere_punkte = []

      # Startposition Z
      z = - (@steigung * 2)
      while z < (@laenge + (@steigung * 2))

        # Weiterzählen
        i += 1
        z += z_schrittweite 
        
        # Winkel
        alpha = schrittweite * i
        # Abspeichern der Radien um sie gleich für die Enden
        # des Gewindes korrigieren zu können
        oberer_radius = @innenradius + dicke
        unterer_radius = @innenradius + dicke
        innenradius = @innenradius
        

        # Z-Positionen der Punkte, noch ohne Korrektur für
        # die Enden des Gewindes
        
        z_unten = z - z_differenz
        z_oben  = z + z_differenz        
        z_mitte = z

        # Überspringen des Schritts, wenn Punkt unten oder oben aus dem Gewinde
        # "herausfällt"
        if z < 0 && z_oben < 0 && z_unten < 0 && z_unten + (z_differenz * 24) < 0
          next
        end
        
        # Korrektur der Punkte für oberen und unteren Gewinderand
        
        # Unten
        if z_unten < 0
          z_unten = 0
          unterer_radius = @innenradius + ((z - z_unten) * tangens)
        end
        if z_unten > @laenge
          z_unten = @laenge
        end

        # Oben
        if z_oben > @laenge
          z_oben = @laenge
          oberer_radius = @innenradius + ((z_oben - z) * tangens)
        end

        if z_oben < 0
          z_oben = 0
        end
        
        # Mitte
        if z_mitte > @laenge
          z_mitte = @laenge
          innenradius = @innenradius + ((z_differenz - (z_mitte - z_unten)) * tangens)
        end
        
        if z_mitte < 0
          z_mitte = 0
          innenradius = @innenradius + ((z_differenz - z_oben) * tangens)
        end
        
        # Punkte hinzufügen
        # Innere Punkte
        innere_punkte << gewindepunkt(
          z_unten <= z_mitte && z_oben >= z_mitte && z_unten < @laenge && z_oben > 0 && innenradius >= @innenradius,
          alpha,
          innenradius,
          z_mitte
        )
        obere_punkte << gewindepunkt(
          z_mitte <= @laenge && (z + z_steg) >= 0 && oberer_radius >= @innenradius,
          alpha,
          oberer_radius,
          z_oben
        )
        untere_punkte << gewindepunkt(
          z_mitte >= 0 && (z + z_differenz - (z_schrittweite * 24)) <= @laenge && unterer_radius >= @innenradius,
          alpha,
          unterer_radius,
          z_unten
        )
      end

      # Punkte um den Zylinder zu schließen
      startmittelpunkt = @gitter.add_point([0,0,0])
      endmittelpunkt = @gitter.add_point([0,0,@laenge])
      
      # Flaechen zeichnen
      
      (innere_punkte.length - 1).times do |i|
        
        segmentpolygone(
          obere_punkte[i],
          obere_punkte[i+1],
          innere_punkte[i+1],
          innere_punkte[i]          
        )        
        segmentpolygone(
          innere_punkte[i], 
          innere_punkte[i + 1],
          untere_punkte[i + 1], 
          untere_punkte[i]
        )                
        segmentpolygone(
          untere_punkte[i], 
          untere_punkte[i + 1],
          obere_punkte[i - 23], 
          obere_punkte[i - 24]
        )
      end
      
      # In der richtigen reihenfolge die Punkte der reihen durchgehen
      # und untere und obere extrema in jeweils ein array stecken
     
      startpunkte, endpunkte = sammle_start_und_endpunkte(innere_punkte, untere_punkte, obere_punkte)
      
      # Start- und Endpunkte mit den Oberen und unteren Mittelpunkten des
      # Inneren Zylinders verbinden
      
      endflaeche(startmittelpunkt, startpunkte)
      endflaeche(endmittelpunkt, endpunkte)
      
      # Aus dem Mesh die Flächen erzeugen und zu der Komponentendefinition
      # hinzufügen
      @definition.entities.add_faces_from_mesh(@gitter, 0)
      
    end
    
    def place_component
      # Komponente durch den Benutzer platzieren lassen
      modell.place_component @definition
    end
  end
end

unless file_loaded? File.basename(__FILE__) 
  # ein Toolbar-Icon wird durch UI::Command definiert
  cmd = UI::Command.new("Gewinde") do
   JK::Gewinde.dialog
  end
  # zwei Bilder für große und kleine Toolbar-Icons
  cmd.small_icon = File.join(File.dirname(__FILE__),'bilder','gewinde_klein.png')
  cmd.large_icon = File.join(File.dirname(__FILE__),'bilder','gewinde.png')

  # neue Toolbar für die Icons erzeugen
  toolbar = UI::Toolbar.new "Formen"
  # Icons hinzufügen
  toolbar = toolbar.add_item cmd
  # Toolbar anzeigen  (ist über das Ansicht-Menü 
  # "Funktionspaletten" (Mac) oder "Symbolleisten" (Windows)
  # von Hand ein- und ausblendbar)
  toolbar.show
end

file_loaded File.basename(__FILE__) 
