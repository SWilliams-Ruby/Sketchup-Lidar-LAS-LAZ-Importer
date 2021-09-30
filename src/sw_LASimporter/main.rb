# A Sketchup extension to import Lidar LAS files
# Usage: In Sketchup select File > Import
# select  *.las in the file type dropdown list
# click on Options to select the classification of the points to import
#
module SW
  module LASimporter
    class LASimporter < Sketchup::Importer
      include SW::LASimporter::Options
      @@verbose = true
      
      def description
        return "Lidar las Importer (*.las)"
      end
    
      def file_extension
        return "las"
      end
      
      def id
        return "SW::LASimporter"
      end
      
      def supports_options?
        return true
      end

      def do_options
        set_import_options()
      end
    
      def load_file(file_name_with_path, status)
        return if file_name_with_path.nil?
        return unless check_for_required_namespaces() # check for the Delunator Gem
        
        begin
          model = Sketchup.active_model
          ents = model.active_entities

          model.start_operation('LAS import', true)
            grp = ents.add_group
            grp.name = 'LAS_import'      
            ents = grp.entities
            las_file = read_las_file(file_name_with_path)
           # las_file.dump_public_header if @verbose# debug info
            triangulate = UI.messagebox("Found #{las_file.num_point_records}\nDo you want a triangulated surface?", MB_YESNO) == IDYES
            import_las_file_points(las_file, ents, triangulate)  
          model.commit_operation
          
          if grp.deleted? || ents.size == 0
            log 'No points imported'
          else
            Sketchup.active_model.active_view.zoom(grp)
          end
          
          return Sketchup::Importer::ImportSuccess

        rescue => exception
          model.abort_operation
          # User error message here
          raise exception
        end
      end    
      
      # Populate the LASfile structure from a *.las file
      # @param file_name_with_path [String]
      # @return [LASfile]
      #
      def read_las_file(file_name_with_path)
        log "Importing #{file_name_with_path}"
        las_file = LASfile.new(file_name_with_path)
        log("\Found #{las_file.num_point_records} point data records")
        log("\nPublic Header Dump")
        las_file
      end
   
      # Import LAS file point records as cpoints ar as
      # a triangulated surface into the entities collection
      # @param las_file [LASfile]
      # @param ents [Sketchup::Entities]
      #
      def import_las_file_points(las_file, ents, triangulate)
        # Wrap the importation with an on screen progressbar  
        ProgressBarBasicLAS.new {|pbar|
          import_point_records(las_file, ents, pbar, triangulate)
        }
      end
      
      # Import the point records that match the user's import options i.e.
      # the user's choice of which classifications to load (Ground, Water, etc.)
      # Each point will be added to the 'ents' collection as a construction point.
      # @param las_file, 
      # @param ents [Sketchup::Entities]
      # @param pbar [SW::ProgressBarBasic]
      # @param triangulate [Boolean]
      #
      def import_point_records(las_file, ents, pbar, triangulate)
        file = las_file.file_name_with_path.split("\\").last
        points = []
        class_counts =[0] *32 # holds a running total of number of points added by classification
        num_point_records = las_file.num_point_records
        user_selected_classifications = get_import_options_classes()

        # TODO: read the WKT/GEOTiff units from the file
        # and select the appropriate Inches per Unit
        # UNIT["US survey foot",0.3048006096012192] is 30.48 centimeters 
        # 1 Yard (International):: Imperial/US length of 3 feet or 36 inches.
        # In 1959 defined in terms of metric units as exactly   meters.
        
        if import_options_horizontal_units() == "Meters"
          ipu_horiz = 39.3701 # meters to sketchup inches
        else
          ipu_horiz = 12.0 # feet to sketchup inches
        end
        
        if import_options_vertical_units() == "Meters"
          ipu_vert = 39.3701
        else
          ipu_vert = 12
        end
        
        # las_file.points.take(10).each_with_index{|pt, i| # debug
        las_file.points.each_with_index{|pt, i|
          ptclass = 0b01 << pt[3]
          if (user_selected_classifications & ptclass) != 0  # bitwise classifications 0 through 23
            points << [pt[0] * ipu_horiz, pt[1] * ipu_horiz, pt[2] * ipu_vert]
            class_counts[pt[3]] += 1
          end
        }

        if triangulate == true
          triangulate(pbar, file, ents, points) 
        else
          points.each_with_index{ |pt, i|
            ents.add_cpoint([pt[0] * ipu_horiz, pt[1] * ipu_horiz, pt[2] * ipu_vert])
            if pbar.update?
              refresh_pbar(pbar, "#{file}: Importing #{@import_options_classes_text}    Remaining points: #{num_point_records - i}", \
              i * 100.0/num_point_records)
            end
          }
        end
        
        log "\nPoints by Classification"
        class_counts.each_with_index{|count, i| log "#{i}: #{count}"}
        log "Total points added #{class_counts.inject(0){|sum,x| sum + x }}"
      end

      def triangulate(pbar, file, ents, points)
        t = Time.now
        log 'start triangulation'
        points.uniq!
        coords = points.map { |e| [e[0], e[1]] }
        
        refresh_pbar(pbar, "#{file}: Triangulating Faces", 0.0)
        triangles = Delaunator.triangulate(coords)
        count = triangles.size/3
        
        start = 0
        refresh_pbar(pbar, "#{file}: Adding Faces,  Remaining faces: #{count - start}", 0.0)

        log Time.now - t
        log 'adding faces'
        while start < count
          print '-'
          start = add_polygons(ents, points, triangles, start, 5000)
          if pbar.update? && start < count
             refresh_pbar(pbar, "#{file}: Adding Faces,  Remaining faces: #{count - start}", start * 100.0/count)
          end
        end
        log Time.now - t
      end # triangulate
      
      def add_polygons(ents, points, triangles, start, count)
        mesh = Geom::PolygonMesh.new
        points.each{ |pt| mesh.add_point(Geom::Point3d.new(*pt)) }

        (start..(start + count - 1)).each { |i|
          break if  ((i + 1) * 3) > triangles.size
          k = i * 3
          mesh.add_polygon(triangles[k+2] + 1, triangles[k+1] + 1, triangles[k] + 1)
        }

        ents.add_faces_from_mesh(mesh)
        return start + count
      end
      
      def refresh_pbar(pbar, label, value)
        pbar.label= label
        pbar.set_value(value)
        pbar.refresh
      end
      
      def log(text)
        puts text if @@verbose
      end
      
      def check_for_required_namespaces()
        require 'delaunator'
        return true
        rescue LoadError
          result = UI.messagebox("The the LAS Importer program needs the Delaunator gem to run. Paste this into the ruby console to install the gem\nGem.install 'delaunator'", MB_OK)
          puts "Copy this > Gem.install 'delaunator'"
        return false
      end
      
    end
    Sketchup.register_importer(LASimporter.new)
  end
end


nil
