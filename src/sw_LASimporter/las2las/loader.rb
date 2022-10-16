require File.join(SW::LASimporter::PLUGIN_DIR, 'las2las\las2lasmerge')
require File.join(SW::LASimporter::PLUGIN_DIR, 'las2las\merge_dialog')

# Menu
module SW
  module Las2Las
    unless @loaded
      menu = UI.menu("Plugins")
      menu.add_item("Merge LAZ/LAS Files") { Las2Las.entry() }
    end
    @loaded = true
  end
end


