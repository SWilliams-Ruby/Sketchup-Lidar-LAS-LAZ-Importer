module SW
  module Sigint_Trap
    # Module Sigint_Trap is a SIGINT handler that interrupts in the main
    # thread (only when the thread is in the Ruby code). By default it will 'puts' an object
    # to the console or alternatively it will call a user supplied Proc.
    # further reading http://kirshatrov.com/2017/04/17/ruby-signal-trap/
    # also see self pipe https://gist.github.com/mvidner/bf12a0b3c662ca6a5784
    # and https://bugs.ruby-lang.org/issues/14222
    #
    # init()              sets up the SIGINT handler
    # add_message()       throws the SIGINT interrupt
    # 
    
    @pending_messages = []
    
    def self.init(time)
      return if @old_signal_handler
      @tt = time
      @old_signal_handler = Signal.trap("INT") do
        while (current_job = @pending_messages.shift)
          if current_job
            # print "%0.6f " % (Time.now - @tt).to_s
            if current_job.is_a?(Proc)
              current_job.call
            else
              puts current_job
            end
          else
            @old_signal_handler.call if @old_signal_handler.respond_to?(:call)
          end
        end
      end #end of trap
      
      puts 'old SIGINT Handler' + @old_signal_handler.to_s
    end
    
    # queue messasge, interrupt the main thread via SIGINT
    def self.add_message(message)
        @pending_messages << message
        Process.kill("INT", Process.pid)
    end
  end #sigint_trap
  
  ##################################################### 
  # initialize the sigint handler
  t = Time.now
  Sigint_Trap.init(t)
end
nil

