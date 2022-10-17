module SW
  module Las2Las
    # A reference to the current dialog
    @mergedialog = nil
    
    def self.show_merge_dialog(filepaths)
      # with HTMLdialog we must open a new dialog each time
      # if the user has closed the dialog
      @mergedialog.close if @mergedialog
      @mergedialog = MergeDialog.new(filepaths)
      @mergedialog.open
    end
    
    class MergeDialog
      def initialize(filepaths)
        @filepaths = filepaths
        @dialog = create_dialog()
        @thin_to = "10"
      end
      
      def open
        @dialog.show_modal
      end
      
      def close
        # and then SU8 does something different, What? 
        @dialog.close if Sketchup.version.to_i > 8 
      end
      
      def update_element(element, text)
        js_command = "document.getElementById('#{element}').innerHTML='#{text}';"
        @dialog.execute_script(js_command)
      end

      def create_dialog()
         properties = {
          :dialog_title    => 'LAS Importer',
          :preferences_key => 'SW::LASImporter',
          :resizable       => true,
          :width           => 500,
          :height          => 500,
          :left            => 200,
          :top             => 200
         }
        
        if defined?(UI::HtmlDialog)
          dialog = UI::HtmlDialog.new(properties) 
        else
          dialog = UI::WebDialog.new("LAS Importre", false, "SW::LASImporter", 250, 500, 200, 200, true)
        end
        
        dialog.set_file(File.join(SW::LASimporter::PLUGIN_DIR, 'las2las', 'html', 'merge_dialog.html'))
        
        dialog.set_on_closed { puts 'merge dialog closed'}

        dialog.add_action_callback("close_clicked") { |action_context|
          puts 'close clicked'
          SW::Las2Las.cancel_merge( self )
        }
        
        dialog.add_action_callback("merge_clicked") { |action_context|
          puts 'merge clicked'
          SW::Las2Las.merge_files( self, @filepaths, @thin_to )
        }
        
        dialog.add_action_callback("cancel_clicked") { |action_context, state|
          puts 'cancel clicked'
          SW::Las2Las.cancel_merge( self )
        }

        dialog.add_action_callback("thin_clicked") { |action_context, state|
          @thin_to = state
          # puts @thin_to
        }
        
        return dialog
      end # end create_dialog
    end # end class ToolsDialog
    
  end
end
