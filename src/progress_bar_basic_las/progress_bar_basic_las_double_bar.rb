# Subclass the ProgressBarBasic class
# modify the on screen appearance by defining new methods etc. for a second bar

module SW
  module LASimporter
    class ProgressBarBasicLASDoubleBar < ProgressBarBasicLAS
      attr_reader(:value2, :bar2_location, :bar2_width, :bar2_height)
      attr_accessor(:label2, :text2_location)

      def initialize(&block)
      
        super(&nil) # call super without the block
        # add options for the second bar value, label, and location
        @value2 = 0
        @label2 = ""
        
        @bar2_location = bar_location.clone
        @bar2_location[1] += 40
        @bar2_width = bar_width
        @bar2_height = bar_height
        @text2_location = text_location.clone
        @text2_location[1] += 40
        
        self.height = height + 45
             
        # Call the the user's block if present. The progressbar object will be passed as the argument to the block
        call_user_block(block) if block
        
      end # initialize
      
      def bar2_location(loc)
        @bar2_location = loc
      end
      
      def bar2_width(x)
        @bar2_width = x
      end
        
      def bar2_height(y)
        @bar2_height = y
      end

      def text2_location(loc)
        @text2_location = loc
      end

      
     
      ###################################
      # Add value2 and label2 methods 
      ###################################
     
      # Place the progress bar at 'value' percent.
      # 'value' between 0 and 100 inclusive
      def set_value2(value)
        raise ProgressBarError, "Value must be a Numeric type" \
          unless value.is_a?(Numeric)
        raise ProgressBarError, "Value must be between 0 and 100" \
          if (value < 0.0) || (value > 100.0)
        @value2 = value/100.0
        @value2 = 1.0 if @value2 > 1.0
      end
      
      # Advance the progress bar by 'value' percent.
      # 'value' between 0 and 100 inclusive
      def advance_value2(value)
        raise ProgressBarError, "Value must be a Numeric type" \
          unless value.is_a?(Numeric)
        raise ProgressBarError, "Value must be between 0 and 100" \
          if (value < 0.0) || (value > 100.0)
        @value2 += value/100.0
        @value2 = 1.0 if @value2 > 1.0
      end


      def draw_self(view)
        # draw the original bar via a call to 'super'
        super(view)
        
        # draw the newly added bar 
        scale = screen_scale
        
        # Bar2 Background
        x = location[0] * scale
        y = location[1] * scale
        xbar = x + @bar2_location[0] * scale
        ybar = y + @bar2_location[1] * scale
        barwidth = @bar2_width * scale
        barheight = @bar2_height * scale
        
        points2 = [
          [xbar, ybar, 0],
          [xbar, ybar + barheight, 0],
          [xbar + barwidth, ybar + barheight, 0],
          [xbar + barwidth, ybar, 0]
        ]
        view.drawing_color = bg_color
        view.draw2d(GL_QUADS, points2)
   
        # Progress Bar2 Fill
        points2 = [
          [xbar, ybar, 0],
          [xbar, ybar + barheight, 0],
          [xbar + @value2 * barwidth, ybar + barheight, 0],
          [xbar + @value2 * barwidth, ybar, 0]
        ]
        view.drawing_color = fg_color
        view.draw2d(GL_QUADS, points2)

        if @label2
          point = Geom::Point3d.new(x + @text2_location[0] * scale,  y + @text2_location[1] * scale, 0)
          view.draw_text(point, @label2, text_options) if  @@suversion >= 16
          view.draw_text(point, @label2) if @@suversion < 16
        end
        
      end # draw
    end
  end
end
nil


