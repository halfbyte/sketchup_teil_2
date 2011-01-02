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
      dialog = UI::WebDialog.new("Gewinde", false, 'gewinde-dialog', 600, 600)
      dialog.set_file(File.join(File.dirname(__FILE__), 'html', 'gewinde_formular.html'))
      dialog.show
      dialog.add_action_callback("gewinde_vorgaben_ausfuellen") do |dialog, parameter|
        dialog.execute_script("gewinde_vorgaben_ausfuellen(#{10},#{13},#{20},#{4},#{60})")
      end
      
      dialog.add_action_callback("gewinde_abbrechen") do |dialog, parameter|
        dialog.close
      end
      
      dialog.add_action_callback("gewinde_bauen") do |dialog, parameter|
        
        innenradius = dialog.get_element_value("innenradius").to_f
        aussenradius = dialog.get_element_value("aussenradius").to_f
        laenge = dialog.get_element_value("laenge").to_f
        steigung = dialog.get_element_value("steigung").to_f
        oeffnungswinkel = dialog.get_element_value("oeffnungswinkel").to_f
        dialog.close
        Gewinde.new(
          innenradius,
          aussenradius, 
          laenge, 
          steigung, 
          oeffnungswinkel
        ).place_component
      end
    end
    
    def bedingtes_polygon(gitter, pt1, pt2, pt3)
      if pt1 && pt2 && pt3
        gitter.add_polygon(pt1, pt2, pt3)
      end
    end
           
    def baue_gewinde
      @gitter = Geom::PolygonMesh.new
      
      schrittweite = 2 * Math::PI / 24.0
      z_schrittweite = @steigung.to_f / 24.0
      dicke = @aussenradius - @innenradius
      z_differenz = dicke / Math::tan(@oeffnungswinkel / 180 * Math::PI)
      z_steg = @steigung - z_differenz
      
      
      
      i = -1
      innere_punkte = []
      obere_punkte = []
      untere_punkte = []
      z = - (@steigung * 2)
      
      
      
      
      while z < (@laenge + (@steigung * 2))
        
        i += 1
        z += z_schrittweite 
        
        alpha = schrittweite * i
        oberer_radius = @innenradius + dicke
        unterer_radius = @innenradius + dicke
        innenradius = @innenradius
        
        tangens = Math::tan(@oeffnungswinkel / 180 * Math::PI)

        z_unten = z - z_differenz
        z_oben  = z + z_differenz        
        z_mitte = z

        if z < 0 && z_oben < 0 && z_unten < 0 && z_unten + (z_differenz * 24) < 0
          next
        end



        if z_unten < 0
          z_unten = 0
          unterer_radius = @innenradius + ((z - z_unten) * tangens)
        end
        if z_unten > @laenge
          z_unten = @laenge
        end

        if z_oben > @laenge
          z_oben = @laenge
          oberer_radius = @innenradius + ((z_oben - z) * tangens)
        end

        if z_oben < 0
          z_oben = 0
        end
        
        # mitte
        if z_mitte > @laenge
          z_mitte = @laenge
          innenradius = @innenradius + ((z_differenz - (z_mitte - z_unten)) * tangens)
        end
        
        if z_mitte < 0
          z_mitte = 0
          innenradius = @innenradius + ((z_differenz - z_oben) * tangens)
        
        end
        
        # adding points
        puts "#{innenradius}"
        if z_unten <= z_mitte && z_oben >= z_mitte && z_unten < @laenge && z_oben > 0 && innenradius >= @innenradius
          innere_punkte << gitter.add_point([Math.cos(alpha) * innenradius, Math.sin(alpha) * innenradius, z_mitte ])
        else
          innere_punkte << nil
        end
         #puts (z + z_steg)
        if z_mitte <= @laenge && (z + z_steg) >= 0 && oberer_radius >= @innenradius
          obere_punkte << gitter.add_point([Math.cos(alpha) * oberer_radius, Math.sin(alpha) * oberer_radius, z_oben ])
        else
          obere_punkte << nil
        end
        
        if z_mitte >= 0 && (z + z_differenz - (z_schrittweite * 24)) <= @laenge && unterer_radius >= @innenradius
          #puts "#{unterer_radius} - #{@innenradius}"
          untere_punkte << gitter.add_point([Math.cos(alpha) * unterer_radius, Math.sin(alpha) * unterer_radius, z_unten ])
        else
          untere_punkte << nil
        end
        
        # outer_points << mesh.add_point([Math.sin(alpha) * @outer_radius, Math.cos(alpha) * @outer_radius, z ])
        # inner_points_top << mesh.add_point([Math.sin(alpha) * @inner_radius, Math.cos(alpha) * @inner_radius, z_top])
        # inner_points_bottom << mesh.add_point([Math.sin(alpha) * @inner_radius, Math.cos(alpha) * @inner_radius, z_bottom])
        
        
        # Punkte um den Zylinder zu schließen
        startpunkt = gitter.add_point([0,0,0])
        endpunkt = gitter.add_point([0,0,@laenge])
       
      end
      
      # Flaechen zeichnen
      
      (innere_punkte.length - 1).times do |i|
        # untere flaeche
        bedingtes_polygon(
          gitter, 
          innere_punkte[i], 
          obere_punkte[i], 
          innere_punkte[i+1]
        )
        bedingtes_polygon(
          gitter,
          innere_punkte[i+1],
          obere_punkte[i], 
          obere_punkte[i+1]
        )
        # obere flaeche
        bedingtes_polygon(
          gitter,
          innere_punkte[i], 
          innere_punkte[i+1],
          untere_punkte[i+1]
          
        )        
        bedingtes_polygon(
          gitter,
          untere_punkte[i+1],
          untere_punkte[i],
          innere_punkte[i]
        )
        # aussenflaeche
        bedingtes_polygon(
          gitter,
          untere_punkte[i], 
          untere_punkte[i + 1],
          obere_punkte[i - 23]        
        )
        bedingtes_polygon(
          gitter,
          obere_punkte[i - 23], 
          obere_punkte[i - 24],
          untere_punkte[i]
        )
      end
      
      # Endpunkte suchen und mit Mittelpunkt verbinden
     
      startpunkte = []
      endpunkte = []
      
      # In der richtigen reihenfolge die Punkte der reihen durchgehen
      # und untere und obere extrema in jeweils ein array stecken
      innere_punkte.each do |punkte_index|
        next if punkte_index.nil?
        punkt = gitter.point_at(punkte_index)
        startpunkte.push(punkte_index) if punkt.z == 0
        endpunkte.unshift(punkte_index) if punkt.z == @laenge
      end
      untere_punkte.each do |punkte_index|
        next if punkte_index.nil?
        punkt = gitter.point_at(punkte_index)
        startpunkte.push(punkte_index) if punkt.z == 0
        endpunkte.unshift(punkte_index) if punkt.z == @laenge
      end
      obere_punkte.each do |punkte_index|
        next if punkte_index.nil?
        punkt = gitter.point_at(punkte_index)
        startpunkte.push(punkte_index) if punkt.z == 0
        endpunkte.unshift(punkte_index) if punkt.z == @laenge
      end
      
      # r
      
      startpunkte.each_with_index do |punkte_index, i|
        second_index = (i + 1) % startpunkte.length
        gitter.add_polygon(startpunkt, punkte_index, startpunkte[second_index])
      end
      endpunkte.each_with_index do |punkte_index, i|
        second_index = (i + 1) % endpunkte.length
        gitter.add_polygon(endpunkt, punkte_index, endpunkte[second_index])
      end
      
      @definition.entities.add_faces_from_mesh(gitter, 0)
      
      
    end
    
    def place_component
      modell.place_component @definition
    end
    
   
    
  end
end

# JK::ScrewThread.new(20,22, 100, 5, 60)

unless file_loaded? File.basename(__FILE__) 
  UI.menu("Plug-Ins").add_item("Gewinde") do 
    JK::Gewinde.dialog
  end
end

file_loaded File.basename(__FILE__) 
