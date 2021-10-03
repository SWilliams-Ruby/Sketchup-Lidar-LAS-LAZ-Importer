module SW
  module LASimporter
    module ImportChoices

      def open_choices_dialog()
      properties = {
          :dialog_title    => 'LAS Import Options',
          :preferences_key => 'SW::LASimport',
          :resizable       => true,
          :width           => 250,
          :height          => 500,
          :left            => 200,
          :top             => 200
         }
        
        # if defined?(UI::HtmlDialog)
          dialog = UI::HtmlDialog.new(properties) 
        # else
          # dialog = UI::WebDialog.new("LAS Import", false, "SW::TimberTools", 250, 500, 200, 200, true)
        # end
        dialog.set_file(File.join(PLUGIN_DIR, 'html', 'import_choices.htm'))
        dialog.show
 
        dialog.add_action_callback("say") { |action_context, param1, param2|
            puts "JavaScript said #{param1} and #{param2}"
            
        }
                dialog.show
      end
    end
  end
end

