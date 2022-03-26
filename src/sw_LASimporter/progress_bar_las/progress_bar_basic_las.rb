#############################################
#
# Initializer:
#   new() -> progressbar
#   new() { |progressbar| block } -> result of block
#
# If a code block is given the progressbar will be shown, the code block will be
# executed, and the progressbar will then be hidden. The progressbar instance
# will be passed to the code block as an arguement. With no associated block the
# progressbar instance will be returned to the caller. The caller will then be
# responsible for showing and hiding the progressbar.
#
# block example:
# module SW::ProgressBarBasicExample
#   def self.run_demo1()
#     begin
#       model = Sketchup.active_model.start_operation('Progress Bar Example', true)
#       SW::ProgressBarBasic.new {|pbar|
#         100.times {|i|
#           # modify the sketchup model here
#           sleep(0.01)
#           # update the progressbar
#           if pbar.update?
#             pbar.label= "Remaining: #{100 - i}"
#             pbar.set_value(i)
#             pbar.refresh
#           end
#         }
#       }
#       Sketchup.active_model.commit_operation
#     rescue => exception
#       Sketchup.active_model.abort_operation
#       raise exception
#     end
#   end
#   run_demo1()
# end
#
# no block example:
# module SW::ProgressBarBasicExample
#   def self.run_demo2()
#     begin
#       model = Sketchup.active_model.start_operation('Progress Bar Example', true)
#       pbar = SW::ProgressBarBasic.new
#       pbar.show
#       100.times {|i|
#         # modify the sketchup model
#         sleep(0.01)
#         # update the progressbar
#         if pbar.update?
#           pbar.label= "Remaining: #{100 - i}"
#           pbar.set_value(i)
#           pbar.refresh
#         end
#       }
#       Sketchup.active_model.commit_operation
#     rescue => exception
#       Sketchup.active_model.abort_operation
#       raise exception
#     ensure pbar.hide
#     end
#   end
#   run_demo2()
# end
# 
#
############################################33
#
# Instance Methods
#
# show - show the progress bar
# hide - hide the proress bar
# refresh - redraw the progressbar
# update_interval= - sets the update interval
# update? - returns true at approximately update_interval seconds
#
# label - get the label
# label= - set the label
# value - get the current value
# set_value(value) - a value between 0 and 100 inclusive
# advance_value(value) - a value between 0 and 100 inclusive
#
# location   
# location=(loc)
# width
# width=(x)
# height
# height=(y)

# screen_scale  - https://ruby.sketchup.com/UI.html#scale_factor-class_method
# frame_bg_color
# frame_outline_color
# bar_location
# bar_width
# bar_height
# fg_color
# bg_color 
# text_location
# text_options - https://ruby.sketchup.com/Sketchup/View.html#draw_text-instance_method

module SW
  module LASimporter
    class ProgressBarBasicLAS
      attr_reader(:value, :location, :width, :height)
      attr_accessor(:label, :update_interval, :lookaway)
      attr_accessor(:screen_scale, :frame_bg_color, :frame_outline_color, :bar_location, :bar_width) 
      attr_accessor(:bar_height, :fg_color, :bg_color, :text_location, :text_options)

      @@suversion = Sketchup.version.to_i  
      @@active_progressbars = []
      @activated = false
      
      # Exception class for Progress bar user code errors
      class ProgressBarError < RuntimeError; end

      # initialize progress bar size, position, and visual elements
      def initialize(&block)
        @location = [50, 30]
        @height = 60
        @width = 600
        @screen_scale = UI.respond_to?(:scale_factor) ? UI.scale_factor : 1.0
        @frame_bg_color = Sketchup::Color.new(240, 240, 240)
        @frame_outline_color = Sketchup::Color.new(180, 180, 180)
        @bar_location = [@width * 0.05, 35]  # relative to @location
        @bar_width = @width * 0.90
        @bar_height = 10
        @fg_color = Sketchup::Color.new(120, 120, 200)
        @bg_color = Sketchup::Color.new(210, 210, 210)
        @text_location = [@width * 0.05, 8] # relative to @location
        @text_options = {:size => 13, :color => [80, 80, 80]} 

        
        self.invalidate() # causes the frame outline to be calculated
        @lookaway = true
        
        # Call the the user's block if present.
        call_user_block(block) if block
        
      end # initialize
      
      # Call the the user's block. The progressbar instance will be passed as the argument to the block
      def call_user_block(block)
        begin
          show()
          block.call(self)
        ensure
          hide()
        end
      end
    
        
      ###################################
      # Progress bar class methods 
      ###################################

      # Show the progress bar
      def show()
        look_away() if @lookaway # look away from the model to speed up redraws
        Sketchup.active_model.tools.push_tool(self)
      end

      def hide()
        look_back() if @lookaway # look back at the model
        Sketchup.active_model.tools.pop_tool()
        # puts @log.join("\n") if @log # @log is an array
      end
      
      # The update? method returns true approximately every @update_interval.
      # Refreshing the progress bar is very time expensive. To regulate the
      # frequency of refreshes the user code should query the update? flag and
      # refresh when the returned value is true.
      def update?
        temp = @update_flag
        @update_flag = false
        temp
      end
     
      # Redraw the progress bar.
      def refresh()
        SW::Util.raise_exception_on_escape if defined?(SW::Util.raise_exception_on_escape)
        # time_at_start_of_redraw = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        # Sketchup.active_model.active_view.refresh
        # @redraw_delay = Process.clock_gettime(Process::CLOCK_MONOTONIC) - time_at_start_of_redraw 
        time_at_start_of_redraw = Time.now
        Sketchup.active_model.active_view.refresh
        @redraw_delay = Time.now - time_at_start_of_redraw

        # @log ? @log << @redraw_delay : @log = [@redraw_delay]
      end

      # Set the location of the progress bar on the screen
      # loc - an array of form [x,y]
      # x, y - numerical values, number of pseudopixels away from the top left of the screen
      # what is a pseudopixel? high resolution screens may have a scaling factor
      # that we'll compensate for
      def location=(loc)
        @location = loc
        invalidate()
      end
      
      def width=(x)
        @width = x
        # set default text and bar parameters
        @text_location[0] = x * 0.05
        @bar_location[0] = x * 0.05
        @bar_width = x * 0.90
        invalidate()
      end
      
      def height=(y)
        @height = y
        invalidate()
      end
      
      # @invalidated is set to false to indicate that the outline needs to be recalculated
      def invalidate()
        @invalidated = true
      end

      def valid? 
        !@invalidated
      end

      # Place the progress bar at 'value' percent.
      # 'value' between 0 and 100 inclusive
      def set_value(value)
        raise ProgressBarError, "Value must be a Numeric type" \
          unless value.is_a?(Numeric)
        raise ProgressBarError, "Value must be between 0 and 100" \
          if (value < 0.0) || (value > 100.0)
        @value = value/100.0
        @value = 1.0 if @value > 1.0
      end
      
      # Advance the progress bar by 'value' percent.
      # 'value' between 0 and 100 inclusive
      def advance_value(value)
        raise ProgressBarError, "Value must be a Numeric type" \
          unless value.is_a?(Numeric)
        raise ProgressBarError, "Value must be between 0 and 100" \
          if (value < 0.0) || (value > 100.0)
        @value += value/100.0
        @value = 1.0 if @value > 1.0
      end
      
      ###################################
      # Sketchup Tool interface methods
      ###################################
       
      def activate
        # puts 'activate'
        @activated = true
        @@active_progressbars << self
       
        # progress bar label and value
        @label = 'Thinking'
        @value = 0.0 # internally this is a float between 0 and 1

        @update_flag = true
        @update_interval = 0.1
        @redraw_delay = 0.02
        start_update_thread()
      end

      def deactivate(view)
        # puts 'deactivate'
        @activated = false
        @@active_progressbars.delete(self)
        stop_update_thread()
      end
      
      # ok, this is not a tool method 
      def active?
        @activated
      end
        
      ###################################
      #  Draw routines
      ###################################
      
      # redraw all of the active progress bars
      def draw(view)
        @@active_progressbars.each{|e| e.draw_self(view)}
      end 

      def draw_self(view)  
        if @invalidated
          @outline = get_outline() 
          @invalidated = false
        end

        # Frame Background
        view.drawing_color = @frame_bg_color
        view.draw2d(GL_POLYGON, @outline)

        # Frame Outline
        view.line_stipple = '' # Solid line
        view.line_width = 1
        view.drawing_color = @frame_outline_color
        view.draw2d(GL_LINE_LOOP, @outline)

        # Progress Bar Background
        scale = @screen_scale
        x = @location[0] * scale
        y = @location[1] * scale
        xbar = x + @bar_location[0] * scale
        ybar = y + @bar_location[1] * scale
        barwidth = @bar_width * scale
        barheight = @bar_height * scale
        
        points2 = [
          [xbar, ybar, 0],
          [xbar, ybar + barheight, 0],
          [xbar + barwidth, ybar + barheight, 0],
          [xbar + barwidth, ybar, 0]
        ]

        view.drawing_color = @bg_color
        view.draw2d(GL_QUADS, points2)
   
        # Progress Bar Fill
        points2 = [
          [xbar, ybar, 0],
          [xbar, ybar + barheight, 0],
          [xbar + @value * barwidth, ybar + barheight, 0],
          [xbar + @value * barwidth, ybar, 0]
        ]
        view.drawing_color = @fg_color
        view.draw2d(GL_QUADS, points2)
        
        # Label
        if @label
            point = Geom::Point3d.new(x + @text_location[0] * scale,  y + @text_location[1] * scale, 0)
            view.draw_text(point, @label, @text_options) if  @@suversion >= 16
            view.draw_text(point, @label) if  @@suversion < 16
        end
      end
      
      ##############################################
      # Private Methods
      ##############################################
        
      # return a loop of points that define the frame outline in 2d screen coordinates
      def get_outline()
        # a 1x1 rounded edge box
        roundedgebox = [[0.125, 0.0, 0.0], [0.875, 0.0, 0.0], [0.922835, 0.009515, 0.0],\
          [0.963388, 0.036612, 0.0], [0.990485, 0.077165, 0.0], [1.0, 0.125, 0.0],\
          [0.990485, 0.922835, 0.0], [0.963388, 0.963388, 0.0], [0.922835, 0.990485, 0.0],\
          [0.875, 1.0, 0.0], [0.875, 1.0, 0.0], [0.077165, 0.990485, 0.0], [0.036612, 0.963388, 0.0],\
          [0.009515, 0.922835, 0.0], [0.0, 0.875, 0.0], [0.0, 0.875, 0.0], [0.009515, 0.077165, 0.0],\
          [0.036612, 0.036612, 0.0], [0.077165, 0.009515, 0.0], [0.125, 0.0, 0.0]]

        scale_and_translate(roundedgebox, @width, @height, @screen_scale, @location)
      end
      private :get_outline
      
      # Scale the 'outline' uniformly by the height and scootch the right side 
      # points over to the correct width. Translate to the screen  location
      def scale_and_translate(outline, width, height, screen_scale, location)
        tr = Geom::Transformation.scaling(height * screen_scale, height * screen_scale,0)
        outline.collect!{|pt|
          pt.transform!(tr)
          pt[0] = pt[0] + width * screen_scale - height * screen_scale if pt[0] > height * screen_scale/2
          pt
        }
        tr = Geom::Transformation.translation([location[0] * screen_scale, location[1] * screen_scale])
        outline.collect{|pt| pt.transform(tr)}
      end
      private :scale_and_translate
      
      # Look away from the model to save redraw time Moving the camera so that NO
      # part of the model's bounding box falls within the camera frustrum will
      # result in redraw times of less than than 10 milliseconds. As we all know,
      # a very heavy model or a model with shadows turned on can take most of a
      # second (or on occasion seconds) to redraw.
      def look_away()
        model = Sketchup.active_model
        camera = model.active_view.camera
        @eye = camera.eye
        @target = camera.target
        @up = camera.up
        bounds = model.bounds
        unless bounds.empty?
          camera.set(bounds.corner(0), bounds.corner(0) -  bounds.center, @up)
        else 
          camera.set([100000, 0, 0], [200000, 0, 0] , @up) # look into empty space
        end
      end
      private :look_away 
     
      # restore the camera settings
      def look_back()
        Sketchup.active_model.active_view.camera.set(@eye, @target, @up)
      end
      private :look_back

      ###################################
      # Timed update? routines 
      ###################################
      
      def start_update_thread()
        @update_thread = Thread.new() {update_loop()}
        @update_thread.priority = 1
      end
      private :start_update_thread
      
      def stop_update_thread()
        @update_thread.exit if @update_thread.respond_to?(:exit)
        @update_thread = nil
      end
      private :stop_update_thread
      
      # A simple thread which will set the @update_flag approximately 
      # every @update_interval + @redraw_delay. 
      
      # @redraw_delay is added to the @update_interval in the update thread loop
      # to maintain a reasonable interval between redraws. This is not so
      # important if @lookaway is true but if @lookaway is
      # false the time to redraw a view can be longer than the @update_interval in
      # which case the user's code would check the update? flag and call refresh()
      # again at the first opportunity.
      def update_loop()
        while active?
          sleep(@update_interval  + @redraw_delay)
          @update_flag = true
        end 
      end
      private :update_loop
      
    end # progressbar class
  end # module
end
nil

