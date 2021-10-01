require File.join(SW::LASimporter::PLUGIN_DIR, 'main.rb')
require File.join(SW::LASimporter::PLUGIN_DIR, 'options.rb')
require File.join(SW::LASimporter::PLUGIN_DIR, 'public_header.rb')
require File.join(SW::LASimporter::PLUGIN_DIR, 'public_header_classes.rb')
require File.join(SW::LASimporter::PLUGIN_DIR, 'las_file.rb')
require File.join(SW::LASimporter::PLUGIN_DIR, 'progress_bar_basic_las.rb')


module SW
  module LASimporter
    def self.load_menus()
          
      # Load Menu Items  
      if !@loaded
        toolbar = UI::Toolbar.new "SW LAS Importer"
        cmd = UI::Command.new("LASimporter") {import()}
        cmd.large_icon = cmd.small_icon =  File.join(SW::LASimporter::PLUGIN_DIR, "icons/LAS.png")
        cmd.tooltip = "Open LAS importer"
        cmd.status_bar_text = "Open LASimporter"
        toolbar = toolbar.add_item cmd
        toolbar.show
        
        plugin_menu = UI.menu("Plugins")
        submenu = plugin_menu.add_submenu("LAS importer")
        submenu.add_item("LAS import"){import()}
        submenu.add_item("options"){set_import_options()}
      end  
        @loaded = true
    end
    load_menus()
    
    # TODO:
    # Methods for the Sketchup Importer intereface
    ###################################3
      # IMPORT_SUCCESS                        = ImportSuccess
      # IMPORT_FAILED                         = ImportFail
      # IMPORT_CANCELLED                      = ImportCanceled
      # IMPORT_FILE_NOT_FOUND                 = ImportFileNotFound
      # IMPORT_SKETCHUP_VERSION_NOT_SUPPORTED = 5
    # class Importer < Sketchup::Importer
      # def initialize
      # end

      # def description
        # 'STereo Lithography Files (*.stl)'
      # end

      # def id
        # 'com.sketchup.sketchup-stl'
      # end

      # def file_extension
        # 'stl'
      # end

      # def supports_options?
        # true
      # end

      # def do_options
        # stl_dialog
      # end

      # def load_file(path, status)
        # begin
        # rescue => exception
          # status = IMPORT_FAILED. IMPORT_CANCELLED, 
        # end
        # return status
      # end
    # end
    
    
    
    
    
  end
  
end


