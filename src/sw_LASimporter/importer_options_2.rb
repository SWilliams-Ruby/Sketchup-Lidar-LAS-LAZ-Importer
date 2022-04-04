module SW
  module LASimporter
    module ImporterOptions2
      # A reference to the current dialog
      @lasdialog = nil
      
      def get_import_options_2(importer)
        # with HTMLdialog we must open a new dialog each time
        # if the user has closed the dialog
        @lasdialog.close if @lasdialog
        @lasdialog = LasImporterDialog.new(importer).open
      end
      
      class LasImporterDialog

        def initialize(importer)
          @importer = importer
          @dialog = create_dialog()
          @import_type = :surface2
          @thin_to = nil
          @dump_details = false
          @selected_regions = nil
        end
        
        def open
          @dialog.show_modal
          return self
        end

        def close
          # and then SU8 does something different, What? 
          @dialog.close if Sketchup.version.to_i > 8 
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
          
          dialog.set_on_closed { p 'import dialog closed'}

          dialog.add_action_callback("import_clicked") { |action_context|
            #p 'import clicked'
            #close()
            @importer.import_file(@import_type, @thin_to, @selected_regions, @dump_details)
          }
          
          dialog.add_action_callback("cancel_clicked") { |action_context, state|
            #p 'import cancel clicked'
            #close()
          }
          
          dialog.add_action_callback("region_clicked") { |action_context, id, state|
            #puts "JavaScript said #{id} and #{state}"
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

      
      # def get_options(num_point_records)
        # prompts = ["Import Type", "Thin to"]
        # defaults = ["Surface", "Full Size"]
        # #list = ["Surface|Surface Large|CPoints|SU Sandbox Contours", "Full Size|50%|20%|10%|5%|2%|1%|0.1%"]
        # list = ["Surface|CPoints", "Full Size|50%|20%|10%|5%|2%|1%|0.1%"]
        # input = UI.inputbox(prompts, defaults, list, "Found #{num_point_records} points")
        # return :cancel unless input
        # case input[0]
        # # when 'Surface'
        # #  type = :surface
        # when 'Surface'
          # type = :surface2
        # # when 'SU Sandbox Contours'
        # #  type = :SUContours
        # else 
          # type = :cpoints
        # end
        
        # case input[1]
        # when '0.1%'
          # thin = 0.001
        # when '1%'
          # thin = 0.01
        # when '2%'
          # thin = 0.02
        # when '5%'
          # thin = 0.05
        # when '10%'
          # thin = 0.1
        # when '20%'
          # thin = 0.2
        # when '50%'
          # thin = 0.5
        # else
          # thin = nil
        # end
        # [type, thin]
      # end
    
    
    end
  end
end
