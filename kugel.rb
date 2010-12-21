require 'sketchup'
require 'werkzeuge'
module JK
  class Kugel
    # Methoden aus lib/werkzeuge.rb einfügen
    include JK::Werkzeuge
    
    def self.dialog
      # Beschriftung der Dialogfelder
      namen = ['Radius (in cm)', 'Anzahl Segmente']
      # Vorgaben
      werte = [20, 10]
      # Werte werden als Array zurückgegeben und in der folgenden Zeile
      # aufgelöst
      radius, segmente = UI.inputbox namen, werte, "Kugel"
      # Erzeugen der Komponentendefinition und platzieren einer Instanz
      Kugel.new(radius.cm, segmente).komponente_platzieren
    end
    
    def initialize(radius, segmente)
      # abspeichern der Parameter in Instanzvariablen
      @radius = radius
      @segmente = segmente
      # Komponenten-Definition erzeugen
      @definition = Sketchup.active_model.definitions.add "Kugel"
      # Punkt, an dem der Körper platziert wird 
      # (in diesem Falle: Kugelmittelpunkt)
      @definition.insertion_point = Geom::Point3d.new(0, 0, -@radius)
      punkte = punkte_fuer_kugel
      flaechen_hinzufuegen(punkte)
    end
    
    def komponente_platzieren
      # place_component lässt den Benutzer die Komponenten-Instanz frei
      # im Raum mit der Maus platzieren
      modell.place_component @definition
    end
    
    def punkte_fuer_kugel
      # durchgehen aller Reihen und Spalten (Breiten- und Längengrade) und
      # erzeugen eines Punktes
      reihen = @segmente / 2
      (1...(reihen)).to_a.map do |reihe|
        (0...@segmente).to_a.map do |spalte|
          punkt_fuer(reihe, spalte)
        end
      end      
    end
    
    def punkt_fuer(reihe, spalte)
      # erzeugt einen Punkt für die angegebene Reihe und Spalte
      schrittweite = 2 * Math::PI / @segmente
      [
        @radius * Math.cos(schrittweite * spalte) * Math.sin(schrittweite * reihe), 
        @radius * Math.sin(schrittweite * spalte) * Math.sin(schrittweite * reihe), 
        @radius * Math.cos(schrittweite * reihe)
      ]      
    end
    
    def flaechen_hinzufuegen(punkte)
      # Das obere und untere Ende der Kugel wird mit jeweils
      # einem Endpunkt verbunden, in der Mitte werden
      # die Segmente untereinander verbunden.
      
      @segmente.times do |spalte|
        # Oben
        @definition.entities.add_face([
          [0,0,@radius], 
          punkte.first[spalte],
          punkte.first[spalte-1]
        ])
        (punkte.size - 1).times do |reihe|
          # Mitte
          @definition.entities.add_face([
            punkte[reihe][spalte-1], 
            punkte[reihe][spalte], 
            punkte[reihe + 1][spalte], 
            punkte[reihe + 1][spalte - 1]
          ])
        end
        # Unten
        @definition.entities.add_face([
          punkte.last[spalte-1], 
          punkte.last[spalte], 
          [0,0, -@radius]
        ])
      end      
    end
    
  end
end

unless file_loaded? File.basename(__FILE__)
  # Ein Toolbar-Icon wird durch ein UI::Command definiert
  cmd = UI::Command.new("Kugel") do
    JK::Kugel.dialog
  end
  # Zwei Bilder für große und kleine Toolbar-Icons
  cmd.small_icon = File.join(File.dirname(__FILE__),'bilder','kugel_klein.png')
  cmd.large_icon = File.join(File.dirname(__FILE__),'bilder','kugel.png')
  
  # Erzeugen einer neuen Toolbar für unsere Icons
  toolbar = UI::Toolbar.new "Formen"
  # Hinzufügen unseres Icons
  toolbar = toolbar.add_item cmd
  # Anzeigen der Toolbar (ist über das Ansicht-Menü "Funktionspaletten" von
  # Hand ein- und ausblendbar)
  toolbar.show
  
end
file_loaded File.basename(__FILE__) 
