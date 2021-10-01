# In your class' constructor ...
  def initialize(*args)
    # Load options into @options hash ...
    @options = options_load()
    # Set the instance variables ...
    @options.each do |key,value|
      self.instance_variable_set("@#{key}", value)
    end
  end
  def options_load
    json = File.read(OPTIONS_PATH, mode: "r", encoding: "UTF-8")
    JSON.parse(json)
  rescue => err
    puts "Error reading options file ..."
    puts err.inspect
  end

  def options_save
    json = @options.to_json
    File.write(OPTIONS_PATH, json, mode: "w", encoding: "UTF-8")
  rescue => err
    puts "Error writing options file ..."
    puts err.inspect
  end

  def options_update
    self.instance_variables.each do |var|
      # var will be a symbol beginning with an @ char:
      key = var.to_s[1..-1]
      @options[key]= self.instance_variable_get(var)
    end
  end
   