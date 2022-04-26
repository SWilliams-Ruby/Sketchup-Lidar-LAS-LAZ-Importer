# A Sketchup extension to import Lidar LAS files
# Usage: In Sketchup select File > Import
# select  *.las in the file type dropdown list
# click on Options to select the classification of the points to import
#
module SW
  module LASimporter
    class LASimporter < Sketchup::Importer
      include ImporterOptions
      include ImporterOptions2
      include ThinLas
      @@verbose = true
      
      def version()
        '2.0.1'
      end
      
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
        set_importer_options()
      end
    
      def load_file(file_name_with_path, status)
        return if file_name_with_path.nil?
        log "Loading #{file_name_with_path}"
        @las_file = read_las_file(file_name_with_path)
        p import_options = get_import_options_2()
        import_file(*import_options) if import_options
        return Sketchup::Importer::ImportSuccess
      end
        
      def import_file(type, thin, selected_regions, dump_details)
        begin
          @las_file.dump_public_header if dump_details # debug info
          model = Sketchup.active_model
          ents = model.active_entities
          model.start_operation('LAS import', true)
            ProgressBarBasicLASDoubleBar.new {|pbar|
              grp = ents.add_group
              grp.name = 'LAS_import'      
              ents = grp.entities
              result = import_las_file_points(@las_file, pbar, ents, type, thin, selected_regions) if type
              unless grp.deleted? || ents.size == 0
                Sketchup.active_model.active_view.zoom(grp)
              end
            }
          model.commit_operation
          return Sketchup::Importer::ImportSuccess
        rescue => e
          model.abort_operation
          if (defined? SW::Util::UserEscapeException) && e.is_a?(SW::Util::UserEscapeException)
            puts 'Import Cancelled by User Escape'
          else
            raise e
          end
        end
      end
      
      # Populate the LASfile structure from a *.las file
      # @param file_name_with_path [String]
      # @return [LASfile]
      #
      def read_las_file(file_name_with_path)
        las_file = LASfile.new(file_name_with_path)
        log("Found #{las_file.num_point_records} point data records")
        las_file
      end
   
      # Import LAS file point records as cpoints or as
      # a triangulated surface into the entities collection
      # @param las_file [LASfile]
      # @param ents [Sketchup::Entities]
      # @param type [String]
      # @param thin [Numerical]
      #
      def import_las_file_points(las_file, pbar, ents, type, thin, selected_regions)
          refresh_pbar(pbar, "Checking for duplicate points", 0.0)
 
          t = Time.now
          points = import_point_records(pbar, las_file, ents, selected_regions)
          return if points.size == 0
          

          points.uniq!
          points = thin(points, pbar, thin) if thin
          log "Thinned Point Count: #{points.size}"
          
          case type

          when :surface2
            triangles = triangulate_with_bbox(pbar, ents, points, las_file) 
            add_surface_large(pbar, ents, points, triangles) 
          else
            add_construction_points(pbar, ents, points)
          end
          log 'Elapsed time: ' + (Time.now - t).to_s        
      end
  
      # Import the point records that match the user's import options i.e.
      # the user's choice of which classifications to load (Ground, Water, etc.)
      # Each point will be added to the 'ents' collection as a construction point,
      # or as a triangulted surface.
      # @param las_file [LASfile], 
      # @param ents [Sketchup::Entities]
      # @param pbar [SW::ProgressBarBasic]
      ##### @param triangulate [Boolean]
      # @return array of points [Array]
      #
      # TODO: read the WKT/GEOTiff units from the file
      # and select the appropriate Inches per Unit
      # UNIT["US survey foot",0.3048006096012192] is 30.48 centimeters 
      # 1 Yard (International):: Imperial/US length of 3 feet or 36 inches.
      # In 1959 defined in terms of metric units as exactly   meters.
      #
      def import_point_records(pbar, las_file, ents, selected_regions)
        file = las_file.file_name_with_path.split("\\").last
        points = []
        num_point_records = las_file.num_point_records
        user_selected_classifications = get_importer_options_classes()
        
        if importer_options_horizontal_units() == "Meters"
          ipu_horiz = 39.3701 # meters to sketchup inches
        else
          ipu_horiz = 12.0 # feet to sketchup inches
        end
        
        if importer_options_vertical_units() == "Meters"
          ipu_vert = 39.3701
        else
          ipu_vert = 12
        end
        
        pbar.label = "Total Progress"
        pbar.set_value(0.0)
        refresh_pbar(pbar, "Reading Point Data, Remaining points: #{num_point_records}", 0.0)
        
        # las_file.points.take(10).each_with_index{|pt, i| # debug
        las_file.set_user_selected_classifications(user_selected_classifications)
        las_file.set_selected_regions(selected_regions)
        points, class_counts = las_file.classified_points(pbar, ipu_horiz, ipu_vert)

        #p  "\nPoints by Classification"
        #class_counts.each_with_index{|count, i| log "#{i}: #{count}"}
        log "Total points Matching Classifications #{class_counts.inject(0){|sum,x| sum + x }}"
        points
      end

      # add points to model as construction points
      #
      def add_construction_points(pbar, ents, points)
        size = points.size
        pbar.label = "Total Progress"
        pbar.set_value(50.0)
        refresh_pbar(pbar, "Adding Points, Remaining points: #{size}", 0.0)
        points.each_with_index{ |pt, i|
          ents.add_cpoint(pt[0..2])
          if pbar.update?
            refresh_pbar(pbar, "Adding Points, Remaining points: #{size - i}", \
            i * 100.0/size)
          end
        }
      end

      # triangulte with a bounding box to make clean up easier
      #
      def triangulate_with_bbox(pbar, ents, points, las_file)
        # add the bounding box
        minx, maxx = points.minmax { |pt1, pt2| pt1[0] <=> pt2[0]}
        # p maxx[0]
        # p minx[0]
        miny, maxy = points.minmax { |pt1, pt2| pt1[1] <=> pt2[1]}
        # p maxy[1]
        # p miny[1]
        real_size = points.size
        points << [minx[0] - 1000.0, miny[1] - 1000.0, 0.0, 9999]
        points << [minx[0] - 1000.0, maxy[1] + 1000.0, 0.0, 9999]
        points << [maxx[0] + 1000.0, miny[1] - 1000, 0.0, 9999]
        points << [maxx[0] + 1000.0, maxy[1] + 1000.0, 0.0, 9999]

       
        triangles = triangulate(pbar, ents, points)
        # remove any triangles containing a BB point
        
        count = triangles.size / 3
        result = []
        count.times { |i|
          next if triangles[3 * i] >= real_size
          next if triangles[3 * i + 1] >= real_size
          next if triangles[3 * i + 2] >= real_size
          result << triangles[3 * i]
          result << triangles[3 * i + 1]
          result << triangles[3 * i + 2]
        }
        result
      end

      # triangulate points
      #
      def triangulate(pbar, ents, points)
        pbar.label = "Total Progress"
        pbar.set_value(33.0)
        refresh_pbar(pbar, "Triangulating Faces, Please wait", 0.0)
        
        coords = points.map { |e| [e[0], e[1]] }
        coords.flatten!
        triangulator = Delaunator::Triangulator.new(coords)
        triangles = triangulator.triangulate(pbar)
        triangles
      end


      # experimental: make point sets smaller 
      #
      def add_surface_large(pbar, ents, points, triangles)
        log "Adding #{triangles.size/3} faces"
        pbar.label = "Total Progress"
        pbar.set_value(66.0)
        refresh_pbar(pbar, "Adding #{triangles.size/3} Faces, This may take a few seconds", 0)
        add_triangles_large(ents, points, triangles) 
      end
     
      # Add 'count' triangles to the model
      #
      def add_triangles_large(ents, points, triangles)
        #tm = Time.now
        count = triangles.size/3
        mesh = Geom::PolygonMesh.new(points.size, count)
        
        points.each { |pt| mesh.add_point(pt[0..2]) }
        #log 'Added points to mesh: ' + (Time.now - tm).to_s

        count.times { |i|
          k = i * 3
          mesh.add_polygon(triangles[k+2] + 1, triangles[k+1] + 1, triangles[k] + 1)
        }
        #log 'Added triangles to mesh: ' + (Time.now - tm).to_s
        ents.fill_from_mesh(mesh, false, 0x0c, nil, nil)
        #log 'Added mesh to entities: ' + (Time.now - tm).to_s
      end
      
      def refresh_pbar(pbar, label, value)
        pbar.label2= label
        pbar.set_value2(value)
        pbar.refresh
      end
      
      def log(text)
        puts text if @@verbose
      end
      
    end
    Sketchup.register_importer(LASimporter.new)
  end
end


nil
