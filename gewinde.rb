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
  		
      baue_zylinder
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
        
    def baue_zylinder
      kreis = @definition.entities.add_circle([0,0,0], [0,0,1], @innenradius, 24)
      flaeche = @definition.entities.add_face kreis
      flaeche.pushpull(-@laenge)
    end
   
    def baue_gewinde
      schrittweite = 2 * Math::PI / 24.0
      z_schrittweite = @steigung.to_f / 24.0
      dicke = @aussenradius - @innenradius
      z_differenz = dicke / Math::tan(@oeffnungswinkel / 180 * Math::PI)
      
      gitter = Geom::PolygonMesh.new
      
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
        inner_radius = @innenradius
        
        tangens = Math::tan(@oeffnungswinkel / 180 * Math::PI)

        z_unten = z - z_differenz
        z_oben  = z + z_differenz        
        z_mitte = z

        if z < 0 && z_oben < 0 && z_unten < 0 && z_unten + (z_differenz * 24) < 0
          puts "alles < null"
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
          puts(z_differenz - (z_mitte - z_unten))
        end
        
        if z_mitte < 0
          z_mitte = 0
          innenradius = @innenradius + ((z_differenz - z_oben) * tangens)
        
        end
        
        # adding points
        if z_unten <= z_mitte && z_oben >= z_mitte && z_unten < @laenge && z_oben > 0
          innere_punkte << gitter.add_point([Math.cos(alpha) * innenradius, Math.sin(alpha) * innenradius, z_mitte ])
        else
          innere_punkte << nil
        end
        if z_mitte <= @laenge && z_oben != z_unten
          obere_punkte << gitter.add_point([Math.cos(alpha) * oberer_radius, Math.sin(alpha) * oberer_radius, z_oben ])
        else
          obere_punkte << nil
        end
        if z_mitte >= 0 && (z + z_differenz - (z_schrittweite * 25)) <= @laenge 
          untere_punkte << gitter.add_point([Math.cos(alpha) * unterer_radius, Math.sin(alpha) * unterer_radius, z_unten ])
        else
          untere_punkte << nil
        end
        
        # outer_points << mesh.add_point([Math.sin(alpha) * @outer_radius, Math.cos(alpha) * @outer_radius, z ])
        # inner_points_top << mesh.add_point([Math.sin(alpha) * @inner_radius, Math.cos(alpha) * @inner_radius, z_top])
        # inner_points_bottom << mesh.add_point([Math.sin(alpha) * @inner_radius, Math.cos(alpha) * @inner_radius, z_bottom])
        
       
      end
      
      # Flaechen zeichnen
      
      (innere_punkte.length - 1).times do |i|
        if (innere_punkte[i] && obere_punkte[i] && innere_punkte[i + 1] && obere_punkte[i + 1])
          gitter.add_polygon([
            innere_punkte[i], 
            obere_punkte[i], 
            innere_punkte[i+1]
          ])
          gitter.add_polygon([
            innere_punkte[i+1],
            obere_punkte[i], 
            obere_punkte[i+1]
          ])
        end
        if (innere_punkte[i] && untere_punkte[i] && innere_punkte[i+1] && untere_punkte[i+1])
          gitter.add_polygon([
            innere_punkte[i], 
            innere_punkte[i+1],
            untere_punkte[i]
          
          ])
          gitter.add_polygon([
            innere_punkte[i+1],
            untere_punkte[i+1],
            untere_punkte[i]
          ])    
        end
        if untere_punkte[i] && obere_punkte[i - 24] && untere_punkte[i+1] && obere_punkte [i - 23]
          gitter.add_polygon([
            untere_punkte[i], 
            untere_punkte[i + 1],
            obere_punkte[i - 24]
            
          ])
          gitter.add_polygon([
            untere_punkte[i + 1],
            obere_punkte[i - 23], 
            obere_punkte[i - 24]
          ])        
        end
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
