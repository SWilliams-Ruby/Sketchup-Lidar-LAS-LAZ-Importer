module SW
  module LASimporter
    class LASimporter < Sketchup::Importer
      include SW::LASimporter::Options
      
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
    
      def load_file(file_name, status)
        return if file_name.nil?
       
        begin
          model = Sketchup.active_model
          ents = model.active_entities
          model.start_operation('LAS import', true)
          grp = ents.add_group
          grp.name = 'LAS_import'      
          ents = grp.entities
          import_las_file(file_name, ents)
          model.commit_operation
          unless grp.deleted? || ents.size == 0
            Sketchup.active_model.active_view.zoom(grp)
          else
            p 'No points imported'
          end
          
          return Sketchup::Importer::ImportSuccess

        rescue => exception
          model.abort_operation
          # User error message here
          raise exception
        end
      end    
   
      # Import LAS file point records as cpoints into the entities collection
      def import_las_file(file_name, ents)
        puts "Importing #{file_name}"
        las_file = LASfile.new(file_name)
        puts "\Found #{las_file.num_point_records} point data records"
        puts "\nPublic Header Dump"
        las_file.dump_public_header # debug info

        # Wrap the importation with an on screen progressbar  
        ProgressBarBasicLAS.new {|pbar|
          import_point_records(las_file, ents, pbar)
        }
      end
      
      # Import the point records that match the user's import options i.e.
      # the user's choice of which classifications to load (Ground, Water, etc.)
      # Each point will be added to the 'ents' collection as a construction point.
      #
      def import_point_records(las_file, ents, pbar)
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
          ents.add_cpoint([pt[0] * ipu_horiz, pt[1] * ipu_horiz, pt[2] * ipu_vert])
          class_counts[pt[3]] += 1
        end
        if pbar.update?
          pbar.label= "Importing #{@import_options_string}    Remaining points: #{num_point_records - i}"
          pbar.set_value(i * 100.0/num_point_records)
          pbar.refresh
        end
        }
        puts "\nPoints by Classification"
        class_counts.each_with_index{|count, i| puts "#{i}: #{count}"}
        puts "Total points added #{class_counts.inject(0){|sum,x| sum + x }}"
      end
      
    end
    Sketchup.register_importer(LASimporter.new)
  end
end
nil


