module SW
  module LASimporter
   
    # A structure for Public Header for LAS 1.0 - 1.4 formats. this provides getters and setters for all(?) fields
    # see: http://www.asprs.org/wp-content/uploads/2019/03/LAS_1_4_r14.pdf for definitions

    PublicHeader = Struct.new(
      :file_signature,    # File Signature (“LASF”) char[4] 4 bytes
      :file_source,       # File Source ID unsigned short 2 bytes
      :global_encoding,   # Global Encoding unsigned short 2 bytes
      :project_ID1,       # Project ID - GUID Data 1 unsigned long 4 bytes
      :project_ID2,       # Project ID - GUID Data 2 unsigned short 2 bytes
      :project_ID3,       # Project ID - GUID Data 3 unsigned short 2 bytes
      :project_ID4,       # Project ID - GUID Data 4 unsigned char[8] 8 bytes
      :major_version,     # Version Major unsigned char 1 byte
      :minor_version,     # Version Minor unsigned char 1 byte
      :sys_ID,            # System Identifier char[32] 32 bytes
      :generator,         # Generating Software char[32] 32 bytes
      :created_day,       # Fiile Creation Day of Year unsigned short 2 bytes
      :created_year,      # File Creation Year unsigned short 2 bytes
      :header_size,       # Header Size unsigned short 2 bytes
      :offset_to_point_data_records, # Offset to Point Data unsigned long 4 bytes
      :num_VLRecs,        # Number of Variable Length Records unsigned long 4 bytes
      :point_data_record_format,  # Point Data Record Format unsigned char 1 byte
      :point_data_record_length,  # Point Data Record Length unsigned short 2 bytes
      :num_point_records,   # Legacy Number of Point Records unsigned long 4 bytes (1.4)
      :num_points_by_return, # Legacy Number of Point by Return unsigned long[5] 20 bytes
      :scaleX,            # X Scale Factor double 8 bytes
      :scaleY,            # Y Scale Factor double 8 bytes
      :scaleZ,            # Z Scale Factor double 8 bytes
      :offsetX,           # X Offset double 8 bytes
      :offsetY,           # Y Offset double 8 bytes
      :offsetZ,           # Z Offset double 8 bytes
      :maxX,              # Max X double 8 bytes
      :minX,              # Min X double 8 bytes
      :maxY,              # Max Y double 8 bytes
      :minY,              # Min Y double 8 bytes
      :maxZ,              # Max Z double 8 bytes
      :minZ,              # Min Z double 8 bytes
      :start_Wave,        # Start of Waveform Data Packet Record unsigned long long 8 bytes
      :start_EVL,         # Start of First Extended Variable Length Record unsigned long long 8 bytes
      :num_EVL            # Number of Extended Variable Length Records unsigned long 4 bytes
                          # Number of Point Records unsigned long long 8 bytes
                          # Number of Points by Return unsigned long long[15] 120 bytes
    )
    
    # Read the public header
    module PublicHeaderMixin
      def initialize(file)

        file.seek(0, IO::SEEK_SET)
        
        self.file_signature = file.read(4)                    # File Signature (“LASF”) char[4] 4 bytes
        self.file_source = file.read(2).unpack('S')[0]        # File Source ID unsigned short 2 bytes
        self.global_encoding = file.read(2).unpack('S')[0]   # Global Encoding unsigned short 2 bytes
        self.project_ID1 = file.read(4).unpack('L')[0]       # Project ID - GUID Data 1 unsigned long 4 bytes
        self.project_ID2 = file.read(4).unpack('L')[0]       # Project ID - GUID Data 2 unsigned long 4 bytes
        self.project_ID3 = file.read(4).unpack('L')[0]       # Project ID - GUID Data 3 unsigned long 4 bytes
        self.project_ID4 = file.read(4).unpack('L')[0]       # Project ID - GUID Data 4 unsigned long 4 bytes
        self.major_version = file.read(1).unpack('C')[0]     # Version Major unsigned char 1 byte
        self.minor_version = file.read(1).unpack('C')[0]     # Version Minor unsigned char 1 byte
        self.sys_ID = file.read(32)                           # System Identifier char[32] 32 bytes
        self.generator = file.read(32)                        # Generating Software char[32] 32 bytes
        self.created_day = file.read(2).unpack('S')[0]       # Fiile Creation Day of Year unsigned short 2 bytes
        self.created_year = file.read(2).unpack('S')[0]      # File Creation Year unsigned short 2 bytes
        self.header_size = file.read(2).unpack('S')[0]       # Header Size unsigned short 2 bytes
        self.offset_to_point_data_records = file.read(4).unpack('L')[0] # Offset to Point Data unsigned long 4 bytes
        self.num_VLRecs = file.read(4).unpack('L')[0]        # Number of Variable Length Records unsigned long 4 bytes
        self.point_data_record_format = file.read(1).unpack('C')[0]      # Point Data Record Format unsigned char 1 byte
        self.point_data_record_length = file.read(2).unpack('S')[0]  # Point Data Record Length unsigned short 2 bytes
        self.num_point_records = file.read(4).unpack('L')[0] # Legacy Number of Point Records unsigned long 4 bytes (1.4)
        self.num_points_by_return = file.read(20).unpack('LLLLL')  # Legacy Number of Point by Return unsigned long[5] 20 bytes
        self.scaleX = file.read(8).unpack('E')[0]            # X Scale Factor double 8 bytes
        self.scaleY = file.read(8).unpack('E')[0]            # Y Scale Factor double 8 bytes
        self.scaleZ = file.read(8).unpack('E')[0]            # Z Scale Factor double 8 bytes
        self.offsetX  = file.read(8).unpack('E')[0]          # X Offset double 8 bytes
        self.offsetY = file.read(8).unpack('E')[0]           # Y Offset double 8 bytes
        self.offsetZ = file.read(8).unpack('E')[0]           # Z Offset double 8 bytes

        self.maxX = file.read(8).unpack('E')[0]              # Max X double 8 bytes
        self.minX = file.read(8).unpack('E')[0]              # Min X double 8 bytes
        self.maxY = file.read(8).unpack('E')[0]              # Max Y double 8 bytes
        self.minY = file.read(8).unpack('E')[0]              # Min Y double 8 bytes
        self.maxZ = file.read(8).unpack('E')[0]              # Max Z double 8 bytes
        self.minZ = file.read(8).unpack('E')[0]              # Min Z double 8 bytes

        if self.minor_version >= 4
          self.start_Wave = file.read(8).unpack('Q')[0]      # Start of Waveform Data Packet Record unsigned long long 8 bytes
          self.start_EVL = file.read(8).unpack('Q')[0]       # Start of First Extended Variable Length Record unsigned long long 8 bytes
          self.num_EVL = file.read(4).unpack('L')[0]         # Number of Extended Variable Length Records unsigned long 4 bytes
          self.num_point_records = file.read(8).unpack('Q')[0] # Number of Point Records unsigned long long 8 bytes
          self.num_points_by_return = file.read(20).unpack('QQQQQQQQQQQQQQQQQQQQQQQQQ') # Number of Points by Return unsigned long long[15] 120 bytes
        end
        
      end
    end
    
   
  end
end


nil




