# Only LAS 1.1 and later has a predefined classification system in place. 
# Unfortunately, the LAS 1.0 specification does not have a predefined 
# classification scheme, nor do the files summarize what, if any, 
# class codes are used by the points. You need to obtain this 
# information from the data provider.

# Table 17: ASPRS Standard Point Classes (Point Data Record
# Formats 6-10)
# Value (Bits 0:4) Meaning Notes
# 0 Created, Never Classified See note4
# 1 Unclassified
# 2 Ground
# 3 Low Vegetation
# 4 Medium Vegetation
# 5 High Vegetation
# 6 Building
# 7 Low Point (Noise)
# 8 Reserved - Was Key Points
# 9 Water
# 10 Rail
# 11 Road Surface
# 12 Reserved
# 13 Wire – Guard (Shield)
# 14 Wire – Conductor (Phase)
# 15 Transmission Tower
# 16 Wire-Structure Connector e.g., insulators
# 17 Bridge Deck
# 18 High Noise
# 19 Overhead Structure e.g., conveyors, mining equipment, traffic
# lights
# 20 Ignored Ground e.g., breakline proximity
# 21 Snow
# 22 Temporal Exclusion Features excluded due to changes over
# time between data sources – e.g., water
# levels, landslides, permafrost
# 23-63 Reserved
# 64-255 User Definable

#########################
# 
# importer_settings() => FIXNUM 
#

module SW
  module LASimporter
    module Options

      def initialize
        @import_options_classes = 0b000000000100
        @import_options_classes_text = "Ground"
        @import_options_horizontal_units = "Feet"
        @import_options_vertical_units = "Feet"
      end
      
      def set_import_options()        defaults = [@import_options_classes_text, @import_options_horizontal_units, @import_options_vertical_units]
        prompts = ["Select Layers", "Select Horizontal Units", "Select Vertical Units"]
        list = ["Ground|Ground & Water|All", "Feet|Meters", "Feet|Meters"]
        input = UI.inputbox(prompts, defaults, list, "LAS importer options")
        if input
          @import_options_classes_text = input[0]
          @import_options_horizontal_units = input[1]
          @import_options_vertical_units = input[2]
          case input[0]
          when 'Ground'
            @import_options_classes = 0b000000000100 # layers Ground(2) & Key Points(8)
          when 'Ground & Water'
             @import_options_classes = 0b001000000100 # add Water(9)
          else
            @import_options_classes = 0x00ffffff # everything up to ptclass 23
          end
        end  
      end
      
      def get_import_options_classes()
        @import_options_classes
      end

      def import_options_horizontal_units()
        @import_options_horizontal_units
      end
      
      def import_options_vertical_units()
        @import_options_vertical_units
      end
    end  
  end
end
nil


