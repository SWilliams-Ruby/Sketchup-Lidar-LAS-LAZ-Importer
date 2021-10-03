module SW
  module LASimporter
    module BackGrounder
    
      def self.load_las_points(las_file)
        start_update_thread(las_file.method(:load_points))
        #start_update_thread(method(:count))
      end
      
      def self.count()
        10000000.times { |i|
          if i % 1000000 == 0        
            Sigint_Trap_for_LASimporter.add_message(i) if SW::LASimporter.const_defined?(:Sigint_Trap_for_LASimporter)
            Sigint_Trap_for_LASimporter.add_message(Time.now) if SW::LASimporter.const_defined?(:Sigint_Trap_for_LASimporter)
          end
        }
        return 'finished'
      end
      
      def self.start_update_thread(block)
        @update_thread = Thread.new() {execute_block(block)}
        @update_thread.priority = 1
      end
      #private :start_update_thread
      
      def self.stop_update_thread()
        @update_thread.exit if @update_thread.respond_to?(:exit)
        @update_thread = nil
      end
      #private :stop_update_thread
      
      def self.execute_block(block)
        begin
          result = block.call
          Sigint_Trap_for_LASimporter.add_message(result) if SW::LASimporter.const_defined?(:Sigint_Trap_for_LASimporter)
        rescue => e
          # puts debug info to the ruby console
          Sigint_Trap_for_LASimporter.add_message("#{e.to_s}, #{e.backtrace.join("\n")}") if SW::LASimporter.const_defined?(:Sigint_Trap_for_LASimporter)
        end
      end
      #private :execute_block
    end # backgrounder
 
    ##########################
    # degugging aids
    ##########################

    unless SW::LASimporter.const_defined?(:Sigint_Trap_for_LASimporter) # Shall we load the signal trap?
      module Sigint_Trap_for_LASimporter
        # Functional Description:
        # Module Sigint_Trap is a SIGINT handler that interrupts and executes code
        # on the main thread. By default it will 'puts' an object to the ruby
        # console or alternatively it will call a user supplied Proc object. This
        # mechanism allows a worker thread to execute code on the main Sketchup
        # thread which has the persmissions needed to interact with the Sketchup
        # API. See the warning below.
        #
        # init()                Sets up the SIGINT handler
        # add_message(message)  Add a message to the queue and throw the SIGINT interrupt
        #
        # WARNING - Do not blithely add a SIGINT handler to your ruby code, it is
        # not safe. This code is for debug purposes only!!! This is because signal
        # handlers are reentrant, that is, a signal handler can be interrupted by
        # another signal (or sometimes the same signal) which can cause mysterious
        # errors.
        #
        # further reading http://kirshatrov.com/2017/04/17/ruby-signal-trap/
        # also see self pipe https://gist.github.com/mvidner/bf12a0b3c662ca6a5784
        # and https://bugs.ruby-lang.org/issues/14222
        #
        
        @pending_messages = []

        def self.init()
          @old_signal_handler = Signal.trap("INT") do
            if @pending_messages.size != 0
              current_job = @pending_messages.shift
              if current_job.is_a?(Proc)
                  current_job.call
              else
                puts current_job
              end
            else
              # Call the daisy chained signal handler if there is nothing in our
              # pending_messages queue. We should never get here in normal debugging 
              p 'old signal handler called'
              @old_signal_handler.call if @old_signal_handler.respond_to?(:call)
            end
          end #end of Signal.trap do
          
          puts "#{self} chained to the old SIGINT Handler: #{@old_signal_handler.to_s}" 
        end
        
        # Add a message to the queue and trigger the SIGINT on the main thread
        def self.add_message(message)
          @pending_messages << message
          Process.kill("INT", Process.pid)
        end
        
        Sigint_Trap_for_LASimporter.init()
        
      end # end module Sigint_Trap_for_ProgressBar
    end # if true/false
  
  end 
  
end
