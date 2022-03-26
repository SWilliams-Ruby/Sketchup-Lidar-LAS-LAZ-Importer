# A Sketchup extension to import Lidar LAS files
# Usage: In Sketchup select File > Import
# select  *.las in the file type dropdown list
# click on Options to select the classification of the points to import
#
module SW
  module LASimporter
    class LASimporter < Sketchup::Importer
      include Options
      include ThinLas
      @@verbose = true
      
      def version()
        '1.0.0'
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
        set_import_options()
      end
    
      def load_file(file_name_with_path, status)
        return if file_name_with_path.nil?
        begin
          model = Sketchup.active_model
          ents = model.active_entities
          model.start_operation('LAS import', true)
            grp = ents.add_group
            grp.name = 'LAS_import'      
            ents = grp.entities
            las_file = read_las_file(file_name_with_path)
            # las_file.dump_public_header if @verbose# debug info
            type, thin = get_options(las_file.num_point_records)
            if type == :cancel # false is a Cancel
              log 'Import Canceled'
              model.abort_operation
              return
            end
            result = import_las_file_points(las_file, ents, type, thin) if type
          model.commit_operation
          unless grp.deleted? || ents.size == 0
            Sketchup.active_model.active_view.zoom(grp)
          end
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
      def import_las_file_points(las_file, ents, type, thin)
        ProgressBarBasicLASDoubleBar.new {|pbar|
        t = Time.now
        points = import_point_records(pbar, las_file, ents, type)
        points.uniq!
        return if points.size == 0
        
        points = thin(points, pbar, thin) if thin
        
        case type
        when :surface
          #triangles = triangulate(pbar, ents, points) 
          triangles = triangulate_with_bbox(pbar, ents, points, las_file) 
          add_surface(pbar, ents, points, triangles) 
        when :surface2
          #triangles = triangulate(pbar, ents, points) 
          triangles = triangulate_with_bbox(pbar, ents, points, las_file) 
          add_surface_large(pbar, ents, points, triangles) 
        # when :SUContours
          # add_via_contours(pbar, ents, points)
        else
          add_construction_points(pbar, ents, points)
        end
        log 'Elapsed time: ' + (Time.now - t).to_s        }
      end
  
      # Import the point records that match the user's import options i.e.
      # the user's choice of which classifications to load (Ground, Water, etc.)
      # Each point will be added to the 'ents' collection as a construction point,
      # or as a triangulted surface.
      # @param las_file [LASfile], 
      # @param ents [Sketchup::Entities]
      # @param pbar [SW::ProgressBarBasic]
      # @param triangulate [Boolean]
      # @return array of points [Array]
      #
      # TODO: read the WKT/GEOTiff units from the file
      # and select the appropriate Inches per Unit
      # UNIT["US survey foot",0.3048006096012192] is 30.48 centimeters 
      # 1 Yard (International):: Imperial/US length of 3 feet or 36 inches.
      # In 1959 defined in terms of metric units as exactly   meters.
      #
      def import_point_records(pbar, las_file, ents, triangulate)
        file = las_file.file_name_with_path.split("\\").last
        points = []
        num_point_records = las_file.num_point_records
        user_selected_classifications = get_import_options_classes()
        
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
        
        pbar.label = "Total Progress"
        pbar.set_value(0.0)
        refresh_pbar(pbar, "Reading Point Data, Remaining points: #{num_point_records}", 0.0)
        
        # las_file.points.take(10).each_with_index{|pt, i| # debug
        las_file.set_user_selected_classifications(user_selected_classifications)
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
        #triangles = Delaunator.triangulate(coords, pbar)
        triangulator = Delaunator::Triangulator.new(coords)
        triangles = triangulator.triangulate(pbar)
        # hull = triangulator.hull
        # draw_hull(ents, points, hull)
        triangles
      end

      #experiment this is the Hull
      #
      # def draw_hull(ents, points, hull)
        # grp = ents.add_group()
        # hull_verts = hull.collect { |i| points[i]}
        # hull_verts << hull_verts[0] # close the loop
        # p *hull_verts
        # grp.entities.add_edges(*hull_verts)
      # end
      
      #####
      #
      # def add_surface(pbar, ents, points, triangles)
        # start = 0
        # count = 2000
        # total = triangles.size/3
        # pbar.label = "Total Progress"
        # pbar.set_value(66.0)
        # refresh_pbar(pbar, "Adding Faces, Remaining faces: #{total}", 0.0)
        # while start < total
          # start = add_triangles(pbar, ents, points, triangles, start, count)
          # start = total if start > total
          # refresh_pbar(pbar, "Adding Faces, Remaining faces: #{total - start}", start * 100.0/total)
        # end
      # end
      
      # Add 'count' triangles to the model
      #
      # def add_triangles(pbar, ents, points, triangles, start, count)
        # mesh = Geom::PolygonMesh.new(points.size, count)
        # points.each{ |pt| mesh.add_point(Geom::Point3d.new(pt[0..2])) }
        # (start..(start + count - 1)).each { |i|
          # k = i * 3
          # break if k + 3 > triangles.size
          # mesh.add_polygon(triangles[k+2] + 1, triangles[k+1] + 1, triangles[k] + 1)
        # }
        # ents.add_faces_from_mesh(mesh)
        # # ents.fill_from_mesh(mesh, true, Geom::PolygonMesh::AUTO_SOFTEN)
        # return start + count
      # end
       
      # experimental: make point sets smaller 
      #
      def add_surface_large(pbar, ents, points, triangles)
        # log 'adding faces'
        total = triangles.size/3
        start = 0
        ###count = total/10
        ##count  = count > 2000 ? count + 1 : 2000
        count  = total

        pbar.label = "Total Progress"
        pbar.set_value(66.0)
        ###refresh_pbar(pbar, "Adding Faces, Remaining faces: #{total}", 0.0)
        refresh_pbar(pbar, "Adding Faces, This may take a few seconds", 0)
        add_triangles_large(ents, points, triangles, count) 

        # while start < total
          # pts, tris = remap_for_large(points, triangles, start, count)
          # add_triangles_large(ents, pts, tris, count)
          # start += count
          # start = total if start > total
          # refresh_pbar(pbar, "Adding Faces, Remaining faces: #{total - start}", start * 100.0/total)
        # end
      end
       
      # remap points and triangles to a smaller subset
      #
      # def remap_for_large(points, triangles, start, count)
        # n = 0
        # h = {}
        # pts=[]
        # tris= []
        # (start*3...(start*3 + count*3)).each { |i|
          # break if i + 3 > triangles.size
          # v = triangles[i]
          # if h.include?(v)
            # tris << h[v]  # point mapping already there    
          # else
            # pts << points[v]
            # h[v] = n
            # tris << n
            # n += 1
          # end
        # }
        # [pts, tris]
      # end
     
      # Add 'count' triangles to the model
      #
      def add_triangles_large(ents, points, triangles, count)
        mesh = Geom::PolygonMesh.new(points.size, count)
        points.each{ |pt| mesh.add_point(Geom::Point3d.new(pt[0..2])) }
        count.times { |i|
          k = i * 3
          break if k + 3 > triangles.size
          mesh.add_polygon(triangles[k+2] + 1, triangles[k+1] + 1, triangles[k] + 1)
        }
        
        # 0: Geom::PolygonMesh::NO_SMOOTH_OR_HIDE
        # 1: Geom::PolygonMesh::HIDE_BASED_ON_INDEX (Negative point index will hide the edge.)
        # 2: Geom::PolygonMesh::SOFTEN_BASED_ON_INDEX (Negative point index will soften the edge.)
        # 4: Geom::PolygonMesh::AUTO_SOFTEN (Interior edges are softened.)
        # 8: Geom::PolygonMesh::SMOOTH_SOFT_EDGES (All soft edges will also be smooth.)
        ents.fill_from_mesh(mesh, false, 0x0c, nil, nil)
        #ents.add_faces_from_mesh(mesh)
      end

      # add points to model as contours
      #
      # def add_via_contours(pbar, ents, points)
        # size = points.size
        # pbar.label = "Total Progress"
        # pbar.set_value(50.0)
        # refresh_pbar(pbar, "Adding Points, Remaining points: #{size}", 0.0)
        # points.each_with_index{ |pt, i|
          # ents.add_edges([pt[0],pt[1],pt[2]], [pt[0],pt[1],-1000])
          # if i.modulo(5000) == 0
            # refresh_pbar(pbar, "Adding Points, Remaining points: #{size - i}", \
            # i * 100.0/size)
          # end
        # }
        # pbar.label = "Total Progress"
        # pbar.set_value(75.0)
        # refresh_pbar(pbar, "Adding Surface, Please Wait", 0.0)
        # model = Sketchup.active_model
        # model.selection.clear
        # model.selection.add(ents.to_a)
        # tool = Sketchup::SandboxTools::FromContoursTool.new
        # Sketchup.active_model.tools.push_tool(tool)
        # ents.clear!
      # end
  
      def get_options(num_point_records)
        prompts = ["Import Type", "Thin to"]
        defaults = ["Surface", "Full Size"]
        #list = ["Surface|Surface Large|CPoints|SU Sandbox Contours", "Full Size|50%|20%|10%|5%|2%|1%|0.1%"]
        list = ["Surface|CPoints", "Full Size|50%|20%|10%|5%|2%|1%|0.1%"]
        input = UI.inputbox(prompts, defaults, list, "Found #{num_point_records} points")
        return :cancel unless input
        case input[0]
        # when 'Surface'
        #  type = :surface
        when 'Surface'
          type = :surface2
        # when 'SU Sandbox Contours'
        #  type = :SUContours
        else 
          type = :cpoints
        end
        
        case input[1]
        when '0.1%'
          thin = 0.001
        when '1%'
          thin = 0.01
        when '2%'
          thin = 0.02
        when '5%'
          thin = 0.05
        when '10%'
          thin = 0.1
        when '20%'
          thin = 0.2
        when '50%'
          thin = 0.5
        else
          thin = nil
        end
        [type, thin]
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
