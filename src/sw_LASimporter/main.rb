module SW
  module LASimporter
    def self.import()
      file_name = UI.openpanel("Open Image File", "", "LAS Files|*.las;||")
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
      rescue => exception
        model.abort_operation
        # User error message here
        raise exception
      end
    end    
 
    # Import LAS file point records as cpoints into the entities collection
    def self.import_las_file(file_name, ents)
      puts "Importing #{file_name}"
      las_file = LASfile.new(file_name)
      puts "\Found #{las_file.num_point_records} point data records"
      puts "\nPublic Header Dump"
      las_file.dump_public_header # debug info

      # Wrap the updates with an on screen progressbar  
      ProgressBarBasicLAS.new {|pbar|
        import_point_records(las_file, ents, pbar)
      }
    end
    
    # Import the point records that match the user's import options i.e.
    # the user's choice of which classifications to load (Ground, Water, etc.)
    # Each point will be added to the 'ents' collection as a construction point.
    #
    def self.import_point_records(las_file, ents, pbar)
      class_counts =[0] *32 # holds a running total of number of points added by classification of point
      num_point_records = las_file.num_point_records
      selected_classifications = get_import_options()

      # TODO: read the GEOTiff units from the file
      # and select the appropriate Inches per Unit
      # UNIT["US survey foot",0.3048006096012192] is 30.48 centimeters 
      # 1 Yard (International):: Imperial/US length of 3 feet or 36 inches.
      # In 1959 defined in terms of metric units as exactly 0.9144 meters.
      ipu = 12.0 # feet to sketchup inches
      #ipu = 39.3701 # meters to sketchup inches
      
      las_file.points.each_with_index{|pt, i|
        ptclass = 0b01 << pt[3]
        if (selected_classifications & ptclass) != 0  # bitwise classifications 0 through 23
          ents.add_cpoint([pt[0] * ipu, pt[1] * ipu, pt[2] * ipu])
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
end
nil


