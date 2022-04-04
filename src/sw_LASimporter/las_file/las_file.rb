# LAS Specifications
# http://www.asprs.org/a/society/committees/standards/asprs_las_format_v10.pdf
# http://www.asprs.org/a/society/committees/standards/asprs_las_format_v11.pdf
# https://www.asprs.org/a/society/committees/standards/asprs_las_format_v12.pdf
# http://www.asprs.org/a/society/committees/standards/asprs_las_spec_v13.pdf
# http://www.asprs.org/wp-content/uploads/2019/03/LAS_1_4_r14.pdf
#
# For our purposes, a LAS file consists of three segments:
# PUBLIC HEADER BLOCK that contians the LAS file version and pointers to the data
# VARIABLE LENGTH RECORDS that hold the Meta data about the point 
# POINT DATA RECORDS that contain the X, Y, and Z information and point classification
#
#
#
#
# Class LAS_FILE 
#
# Methods:
# new(file name w/path) => LAS_File
#
# public_header() => PublicHeader
#
# TODO: variable_length_records() => Array of variable_length_records, nil
#      
# num_point_records() =>  number of point records in the file (i.e. public_header.numPointRecords)
#      
# file_name_with_path => file_name_with_path 
#
# points() => Returns an enumerator of the data points in the file
#      points take the format: [ X, Y, Z, point classification]
#
# Raises LASimporterError < RuntimeError
#

module SW
  module LASimporter
  
    # Exception class for LAS importer Errors
    class LASimporterError < RuntimeError; end

    class LASfile
      attr_accessor(:file_name_with_path)
      @public_header = nil
      @file_name_with_path = nil
      @loaded_points = nil
      @user_selected_classifications = 0
      @selected_regions = nil

      # Read the Public Header and
      # Variable Length Records
      # Raises LASimporterError
      #
      def initialize(file_name_with_path)
        # save the path
        @file_name_with_path = file_name_with_path
        
        # Open in binary mode with no encoding.
        filemode = 'rb'
        if RUBY_VERSION.to_f > 1.8
          filemode << ':ASCII-8BIT'
        end
        
        # check the file version
        File.open(file_name_with_path, filemode) {|file|
          file.seek(24, IO::SEEK_SET)
          @major_version = file.read(1).unpack('C')[0]
          @minor_version = file.read(1).unpack('C')[0]
          
          if @major_version != 1 or @minor_version < 0 or @minor_version > 4 
            raise LASimporterError, "LAS file version #{@major_version}.#{@minor_version} is not supported (yet)."
          end
          
          # read the blocks
          read_public_header(file, @minor_version)
          # read_variable_length_records(file, @minor_version)
          
          # read the data
          file.seek(@public_header.offset_to_point_data_records, IO::SEEK_SET)
          # @las_data = file.read
          #p @las_data.length
        }
      end # initialize
      
      def version()
        "2.0"
      end
      
      def read_public_header(file, minor_version)
        case @minor_version
          when 0
            @public_header = PublicHeader_1_0.new(file)

          when 1
            @public_header = PublicHeader_1_1.new(file)

          when 2
            @public_header = PublicHeader_1_2.new(file)

          when 3
            @public_header = PPublicHeader_1_3.new(file)

          when 4
            @public_header = PublicHeader_1_4.new(file)

          else 
            raise LASimporterError, "LAS file version #{@major_version}.#{@minor_version} is not supported (yet)."
        end
      end

      # TODO: To find the UNITS we need to know
      # Table 4: Global Encoding – Bit Field Encoding
      # bit 4 WKT If set, the Coordinate Reference System (CRS) is WKT. If not set,
      # the CRS is GeoTIFF. It should not be set if the file writer wishes
      # to ensure legacy compatibility (which means the CRS must be
      # GeoTIFF).
      
      # Read the variable length records
      # currently these are just dumped to the console
      def dump_variable_length_records(file)
        case @minor_version
          when 0..3
            file.seek(227, IO::SEEK_SET) # start of variable length records
              @public_header.num_VLRecs.times {|i|
              puts "\nVariable Length Record #{i+1} of #{@public_header.num_VLRecs}"
              p reserved = file.read(2).unpack('S')[0]
              p user_ID = file.read(16)
              p record_ID = file.read(2).unpack('S')[0]
              p record_length_after_header = file.read(2).unpack('S')[0]
              p desc = file.read(32)
              p contents = file.read(record_length_after_header)
            }
             
          when 4
            file.seek(@public_header.start_EVL, IO::SEEK_SET) # start of variable length records
            @public_header.num_EVL.times {|i|
              puts "\nVariable Length Record #{i+1} of #{@public_header.num_EVL}"
              p reserved = file.read(2).unpack('S')[0]
              p user_ID = file.read(16)
              p record_ID = file.read(2).unpack('S')[0]
              p record_length_after_header = file.read(2).unpack('S')[0]
              p desc = file.read(32)
              p contents = file.read(record_length_after_header)
            }

          else 
            raise LASimporterError, "LAS file version #{@major_version}.#{@minor_version} is not supported (yet)."
          end 
      end

      
      # Return the number of points in the LAS_FILE
      def num_point_records()
        @public_header.num_point_records
      end
      
      def public_header()
        @public_header
      end
      
      def set_user_selected_classifications(user_selected_classifications)
       @user_selected_classifications = user_selected_classifications
      end
      
      def set_selected_regions(selected_regions)
        @selected_regions = selected_regions
      end
      
      def classified_points(pbar, ipu_horiz, ipu_vert)
        # parameters from the PUBLIC HEADER
        offset_to_point_data_records = @public_header.offset_to_point_data_records
        point_data_record_format = @public_header.point_data_record_format
        point_data_record_length = @public_header.point_data_record_length
        num_point_records = @public_header.num_point_records
        scaleX = @public_header.scaleX
        scaleY = @public_header.scaleY
        scaleZ = @public_header.scaleZ
        offsetX = @public_header.offsetX
        offsetY = @public_header.offsetY
        offsetZ = @public_header.offsetZ
        minX = @public_header.minX
        minY = @public_header.minY
        minZ = @public_header.minZ
        maxX = @public_header.maxX
        maxY = @public_header.maxY
        
        # maxX is 2355417.99
        # minX is 2354418.0300000003
        # maxY is 290373.0
        # minY is 289373.14
        region_width = (maxX - minX) / 3.99
        region_height = (maxY - minY) / 3.99
        
        
         
        # Open the file in binary mode with no encoding.
        filemode = 'rb'
        if RUBY_VERSION.to_f > 1.8
          filemode << ':ASCII-8BIT'
        end
        
        data = File.open(@file_name_with_path, filemode) {|f|
          f.seek(offset_to_point_data_records, IO::SEEK_SET)
          f.read
        }
        
        class_counts =[0] *32 # holds a running total of number of points added by classification
        pts = []
        count = 0
        index = 0
        loop {
          break if (count += 1) > num_point_records
          record = data[index..(index + point_data_record_length)]
          index += point_data_record_length
          # dump the record as a Hex string
          #p record.each_byte.map { |b| b.to_s(16) }.join
          
          if pbar.update?
            refresh_pbar(pbar, "Reading Point Data, Remaining points: #{num_point_records - count}",count * 100.0 /  num_point_records)
          end
          
          
          case point_data_record_format
          when 0..5
            classification = record[16].unpack('C')[0] & 0x1F              # Classification unsigned char 1 byte 
            ptclass = 0b01 << classification
            next if @user_selected_classifications & ptclass == 0
            
            ptx = record[0..3].unpack('l<')[0] * scaleX
            index_x = ((ptx - minX) / region_width).to_i
            
            pty = record[4..7].unpack('l<')[0] * scaleY
            index_y = ((pty - minY) / region_height).to_i
            
            gg = index_x + 4 * index_y
            puts "oops #{gg}" if gg> 15 or gg < 0
            
            next if @selected_regions && !@selected_regions.include?(index_x + 4 * index_y)

            result = [
            (ptx + offsetX - minX) * ipu_horiz,  # X long 4 bytes 
            (pty + offsetY - minY) * ipu_horiz,  # Y long 4 bytes
              (record[8..11].unpack('l<')[0] * scaleZ + offsetZ - minZ) * ipu_vert, # Z long 4 bytes 
              #record[12..13].unpack('S')[0],                 # Intensity unsigned short 2 bytes
              #record[14].unpack('C')[0],                     # Return Number 3 bits (bits 0, 1, 2) 3 bits
                                                              # Number of Returns (given pulse) 3 bits (bits 3, 4, 5) 3 bits 
                                                              # Scan Direction Flag 1 bit (bit 6) 1 bit
                                                              # Edge of Flight Line 1 bit (bit 7) 1 bit 
              # record[15].unpack('C')[0] & 0x1F,              # Classification unsigned char 1 byte 
              classification
              #record[16].unpack('C')[0],                     # Scan Angle Rank (-90 to +90) – Left side char 1 byte
              #record[17].unpack('C')[0],                     # User Data unsigned char 1 byte
              #record[18..19].unpack('S')[0],                 # Point Source ID unsigned short 2 bytes
              #record[20..27].unpack('E')[0],                 # GPS Time double 8 bytes
              #record[28..29].unpack('S')[0],                 # Red unsigned short 2 bytes
              #record[30..31].unpack('S')[0],                 # Green unsigned short 2 bytes
              #record[32..33].unpack('S')[0]                  # Blue unsigned short 2 bytes 
              ]
              
          when 6..10 # formats 6 through 10
            classification = record[16].unpack('C')[0]       # Classification unsigned char 1 byte 
            ptclass = 0b01 << classification
            next if @user_selected_classifications & ptclass == 0
            
            ptx = record[0..3].unpack('l<')[0] * scaleX
            index_x = ((ptx - minX) / region_width).to_i
            
            pty = record[4..7].unpack('l<')[0] * scaleY
            index_y = ((pty - minY) / region_height).to_i
            
            gg = index_x + 4 * index_y
            puts "oops #{gg}" if gg> 15 or gg < 0
            
            next if @selected_regions && !@selected_regions.include?(index_x + 4 * index_y)

            result = [
            (ptx + offsetX - minX) * ipu_horiz,  # X long 4 bytes 
            (pty + offsetY - minY) * ipu_horiz,  # Y long 4 bytes
            (record[8..11].unpack('l<')[0] * scaleZ + offsetZ - minZ) * ipu_vert, # Z long 4 bytes 
              #record[12..13].unpack('S')[0],                # Intensity unsigned short 2 bytes
              #record[14].unpack('C')[0],                    # 
              #record[15].unpack('C')[0],              
              #record[16].unpack('C')[0] & 0x1F,             # Classification unsigned char 1 byte 
              classification
              #record[17].unpack('C')[0],                    # User Data unsigned char 1 byte
              #record[18..19].unpack('s')[0],                # Scan Angle Rank short 2 bytes
              #record[20..21].unpack('S')[0]                 # Point Source ID unsigned short 2 bytes
              #record[22..29].unpack('E')[0],                # GPS Time double 8 bytes
              ]
          else
            raise LASimporterError, "LAS file - Point Data Record Format #{point_data_record_format} is not supported (yet)."
          end
          #p result
          
          
          
          pts << result
          class_counts[result[3]] += 1
        }
        [pts , class_counts]
      end
   
      def dump_public_header()
        @public_header.each_pair{|n,v|
          puts "#{n} is #{v}"
        }
      end
      
      def refresh_pbar(pbar, label, value)
        pbar.label2= label
        pbar.set_value2(value)
        pbar.refresh
      end
    end
    
  end
end
nil


