require 'sketchup'
require 'werkzeuge'

module Formen
  class Kugel
    # Methoden aus lib/werkzeuge.rb einfügen
    include Formen::Werkzeuge
    
    def self.dialog
      # Beschriftung der Dialogfelder
      namen = ['Radius (in cm)', 'Anzahl Segmente']
      # Vorgabewerte
      werte = [20, 10]
      # Werte werden als Array zurückgegeben 
      # und in der folgenden Zeile aufgelöst
      radius, segmente = UI.inputbox namen, werte, "Kugel"
      # Komponentendefinition erzeugen und Instanz platzieren
      Kugel.new(radius.cm, segmente).komponente_platzieren
    end
    
    # Kugel-Konstruktor
    def initialize(radius, segmente)
      # Parameter in Instanzvariablen speichern
      @radius = radius
      # Zahl horizontaler Reihen entspricht der Segmentzahl
	  @reihen = segmente
	  # Zahl vertikaler Spalten entspricht doppelter Segmentzahl
      @spalten = segmente * 2
      # Komponentendefinition erzeugen
      @definition = Sketchup.active_model.definitions.add "Kugel"
      # Punkt, an dem der Körper platziert wird 
      # (in diesem Fall: Kugelmittelpunkt)
      @definition.insertion_point = Geom::Point3d.new(0, 0, -@radius)
      # Punkte erzeugen und in ein zweidimensionales Array schreiben
      punkte = punkte_fuer_kugel
      # zwischen den Punkten Flächen einfügen
      flaechen_hinzufuegen(punkte)
    end
    
    def komponente_platzieren
      # Methode place_component lässt den Benutzer 
	  # die Komponenten-Instanz frei mit der Maus im Raum platzieren
      modell.place_component @definition
    end
    
    # Legt für jeden Schnittpunkt zwischen einem Längen- 
    # und einem Breitengrad je einen Punkt an;
    # gibt ein zweidimensionales Array zurück
    def punkte_fuer_kugel
      # alle Reihen und Spalten (Breiten- und Längengrade) durchgehen 
      # und je einen Punkt erzeugen
      # Pole sind keine Reihen, sondern werden später separat hinzugefügt
      (1...@reihen).to_a.map do |reihe|
        (0...@spalten).to_a.map do |spalte|
          punkt_fuer(reihe, spalte)
        end
      end      
    end
    
    # Erzeugt einen dreidimensionalen Punkt 
    # für den Schnittpunkt der Breiten- und Längengrade 
    # an der angegebenen Position
    def punkt_fuer(reihe, spalte)
      schrittweite = 2 * Math::PI / @spalten
      [
        @radius * Math.cos(schrittweite * spalte) * Math.sin(schrittweite * reihe), 
        @radius * Math.sin(schrittweite * spalte) * Math.sin(schrittweite * reihe), 
        @radius * Math.cos(schrittweite * reihe)
      ]      
    end
    
    def flaechen_hinzufuegen(punkte)
      # Die Punkte an den Positionen spalte und spalte -1
      # der obersten und der untersten Reihe werden jeweils 
      # mit dem Nord- oder Südpol zu einem Dreieck verbunden, 
      # bei allen anderen Reihen entstehen Vierecke zwischen 
      # reihe und reihe+1 sowie spalte-1 und spalte.
      @spalten.times do |spalte|
        # oben:
        @definition.entities.add_face([
          [0,0,@radius], 
          punkte.first[spalte],
          punkte.first[spalte-1]
        ])
        (punkte.size - 1).times do |reihe|
          # Mitte:
          @definition.entities.add_face([
            punkte[reihe][spalte-1], 
            punkte[reihe][spalte], 
            punkte[reihe + 1][spalte], 
            punkte[reihe + 1][spalte - 1]
          ])
        end
        # unten:
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
  # ein Toolbar-Icon wird durch UI::Command definiert
  cmd = UI::Command.new("Kugel") do
    Formen::Kugel.dialog
  end
  # zwei Bilder für große und kleine Toolbar-Icons
  cmd.small_icon = File.join(File.dirname(__FILE__),'bilder','kugel_klein.png')
  cmd.large_icon = File.join(File.dirname(__FILE__),'bilder','kugel.png')
  
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