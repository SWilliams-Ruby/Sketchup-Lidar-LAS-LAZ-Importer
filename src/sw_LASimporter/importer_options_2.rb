module SW
  module LASimporter
    module ImporterOptions2
      # A reference to the current dialog
      @lasdialog = nil
      
      def get_import_options_2()
        # with HTMLdialog we must open a new dialog each time
        # if the user has closed the dialog
        @lasdialog.close if @lasdialog
        @lasdialog = LasImporterDialog.new()
        return @lasdialog.open
      end
      
      class LasImporterDialog
        def initialize()
          @dialog = create_dialog()
          @import_type = :surface2
          @thin_to = nil
          @dump_details = false
          @selected_regions = nil
          @import_clicked = false
        end
        
        def open
          @dialog.show_modal
          if  @import_clicked
            result = [@import_type, @thin_to, @selected_regions, @dump_details]
          else  
            result = false
          end
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
          
          dialog.set_file(File.join(PLUGIN_DIR, 'html', 'importer_options_2.html'))
          
          #dialog.set_on_closed { p 'import dialog closed'}

          dialog.add_action_callback("import_clicked") { |action_context|
            @import_clicked = true
            #p 'import clicked'
          }
          
          dialog.add_action_callback("cancel_clicked") { |action_context, state|
            #p 'import cancel clicked'
          }
          
          dialog.add_action_callback("region_clicked") { |action_context, id, state|
            if state == true
              if @selected_regions == nil
                @selected_regions = [id]
              else
                @selected_regions << id
              end
            else
              @selected_regions.delete(id)
              if @selected_regions.size == 0
                @selected_regions = nil
              end
            end
            #p @selected_regions
          }
          
          dialog.add_action_callback("type_clicked") { |action_context, state|
            if (state == "Surface")
              @import_type = :surface2
            else
              @import_type = :cpoints
            end
            #p @import_type
          }

          dialog.add_action_callback("thin_clicked") { |action_context, state|
            if (state == 'FullSize')
              @thin_to = nil
            else
              @thin_to = state.to_f / 100
            end
            #p @thin_to
          }
          
          dialog.add_action_callback("details_clicked") { |action_context, state|
            @dump_details = state
          }
          
          return dialog
        end # end create_dialog
      end # end class ToolsDialog
    
    end
  end
end
