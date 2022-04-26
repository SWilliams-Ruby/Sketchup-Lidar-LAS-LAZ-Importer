###################################
# sw_peekaboo.rb a set of non-blocking methods to read windows
# keyboard input with embedded Ruby scripts
#
# In which are defined: 
#   SW::Util.raise_exception_on_escape()
#   SW::Util.test_for_escape()
#   SW::Util.getkeys_nonblocking()
#   and the module SW::User32   (User32.dll)
#
# Also a new threaded timer class: 
#   SW::Timers::SingleShotTimer
#
# And a smattering of memory dump routines
#   SW::Util.memory_dump_ruby_object()
#   SW::Util.memory_dump_address()
#   SW::Util.memory_dump_fiddle_ptr()
#   SW::Util.dump_string_as_hex()
#
# S. Williams, January 14, 2022
#

require 'fiddle'
require 'fiddle/import'
require 'fiddle/types'

module SW
  unless @peekaboo_loaded
    module Util
         
      OS_WIN64 = (Sketchup.platform == :platform_win) && \
        Sketchup.respond_to?(:is_64bit?) && Sketchup.is_64bit?

      class UserEscapeException < RuntimeError; end
      
      ##############################################
      # Raise UserEscapeException on escape key pressed
      #
      # Example:
      #   begin
      #     loop # a loop of some sort
      #       ...
      #       SW::Util.raise_exception_on_escape
      #     end # end of loop
      #   rescue => e
      #     if e.is_a?(SW::Util::UserEscapeException)
      #       puts 'Operation Cancelled by User Escape'
      #     else
      #       raise e
      #     end
      #   end
      #
      def self.raise_exception_on_escape()
        return unless OS_WIN64
        raise UserEscapeException, 'User Escape' if test_for_escape() 
      end
      
      ##############################################
      # Test for escape key press
      # Returns true or false
      #
      def self.test_for_escape()
        return unless OS_WIN64
        getkeys_nonblocking().any? {|c| c == 0x1b} # VK_ESCAPE
      end

      ##############################################
      # Peek at the message queue to inform windows that we 
      # are alive. Return any pending keystrokes.
      #
      # Returns an empty array, or an array of key values
      # Returns false if not implemented in this OS
      #
      # See: https://docs.microsoft.com/en-us/windows/win32/inputdev/using-keyboard-input
      #
      def self.getkeys_nonblocking()
        return unless OS_WIN64
        begin
          msg_pointer = Fiddle::Pointer.malloc(48)
          
          # Indicate to Windows that we are alive. This seems to be necessary.
          message_available = User32.PeekMessageW(msg_pointer, 0, 0, 0, User32::PM_NOREMOVE)
          # p 'first'
          # p message_available
          # if message_available != 0
            # wm_message_num = msg_pointer[0x08, 2].unpack('S')[0] 
            # p wm_message_num.to_s(16)
          # end
          
          # Accumulate any KEYDOWN events
          pressed_keys = []
          loop do
            message_available = User32.PeekMessageW(msg_pointer, 0, User32::WM_KEYFIRST, User32::WM_KEYLAST, User32::PM_REMOVE)
            break if message_available == 0
            pressed_key = check_for_keydown(msg_pointer)
            pressed_keys << pressed_key if pressed_key
          end # loop
          
        ensure
          Fiddle.free msg_pointer
        end
        pressed_keys
      end
      
      ##############################################
      # Notes to self:
      #
      # MSG structure (winuser.h)
      # https://docs.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-msg
      #
      # typedef struct tagMSG {
      #   HWND   hwnd;
      #   UINT   message;
      #   WPARAM wParam;
      #   LPARAM lParam;
      #   DWORD  time;
      #   POINT  pt;
      #   DWORD  lPrivate;
      # } 
      #
      # Example messages for the character 'A'
      # - keydown
      # 1f9d0990720 c4 10 25 00 00 00 00 00 00 01 00 00 00 00 00 00    %             
      # 1f9d0990730 41 00 00 00 00 00 00 00 01 00 1e 00 00 00 00 00   A               
      # 1f9d0990740 3d 35 0b 0f d6 05 00 00 b0 02 00 00 00 00 00 00   = 5            
      # 
      # - keyup
      # 1f9d09909a0 c4 10 25 00 00 00 00 00 01 01 00 00 00 00 00 00    %             
      # 1f9d09909b0 41 00 00 00 00 00 00 00 01 00 1e c0 00 00 00 00   A              
      # 1f9d09909c0 ab 35 0b 0f d6 05 00 00 b0 02 00 00 00 00 00 00   5  
      #
      
      ##############################################
      # Check msg for a keydown event
      # returns the pressed key value or nil
      #
      # Note: Directly reading the bytes from memory is probably faster than
      # instantiating a Fiddle structure for the MSG structure
      #
      def self.check_for_keydown(msg_pointer)
        # memory_dump_fiddle_ptr(msg_pointer, 3)
        wm_message_num = msg_pointer[0x08, 2].unpack('S')[0]
        # puts wm_message_num.to_s(16)
        if wm_message_num == User32::WM_KEYDOWN
          pressed_key = msg_pointer[0x10] # read an ASCII Char
          return pressed_key
        else
          return nil
        end
      end
    
      if OS_WIN64
        module User32
          extend Fiddle::Importer
          dlload 'user32'
          include Fiddle::Win32Types

          PM_NOREMOVE = 0x0000 # Messages are not removed from the queue after processing by PeekMessage.
          PM_REMOVE =   0x0001 # Messages are removed from the queue after processing by PeekMessage.
          PM_NOYIELD =  0x0002 # Prevents the system from releasing any thread that is waiting for
                               # the caller to go idle (see WaitForInputIdle). Combine this value with
                               # either PM_NOREMOVE or PM_REMOVE.
                               
          # From https://www.autohotkey.com/docs/misc/SendMessageList.htm
          WM_KEYFIRST = 0x0100
          WM_KEYDOWN	= 0x0100	
          WM_KEYUP	= 0x0101	
          WM_CHAR	= 0x0102	    # https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-char
          WM_DEADCHAR	= 0x0103	# https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-deadchar
          WM_SYSKEYDOWN	= 0x0104	
          WM_SYSKEYUP	= 0x0105	
          WM_SYSCHAR	= 0x0106	# https://docs.microsoft.com/en-us/windows/win32/menurc/wm-syschar
          WM_SYSDEADCHAR	= 0x0107	# https://docs.microsoft.com/en-us/windows/win32/inputdev/wm-sysdeadchar
          WM_KEYLAST	= 0x0108
          # WM_UNICHAR	= 0x0109	
          # WM_KEYLAST	= 0x0109
          WM_TIMER = 0x0113  # https://docs.microsoft.com/en-us/windows/win32/winmsg/wm-timer
          WM_SYSTIMER = 0x0118 # undocumented, appears to be used for caret blinks.
          WM_MOUSEFIRST = 0x0200

          # https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-peekmessagew
          # BOOL PeekMessageW(
          # [out]          LPMSG lpMsg,
          # [in, optional] HWND  hWnd,
          # [in]           UINT  wMsgFilterMin,
          # [in]           UINT  wMsgFilterMax,
          # [in]           UINT  wRemoveMsg
          # );
         
          extern 'BOOL PeekMessageW(ULONG *, HWND, UINT, UINT, UINT)' 
          
          # TODO?: Implement DefWindowProcA()
          # https://stackoverflow.com/questions/14500614/to-use-defwindowproc-or-not-to-use-defwindowproc
          # My concern is about calling DefWindowProc. It may seem, that its simply "do the default behavior for me",
          # but sometimes it actually does some critical stuff. For instance, disabling WM_LBTNDOWN by not calling DefWindowProc 
          # will result in inability to close window by clicking the [X] button.
          #
          # https://stackoverflow.com/questions/18041622/how-do-i-stop-windows-from-blocking-the-program-during-a-window-drag-or-menu-but
          #
          # https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-defwindowproca
          # LRESULT LRESULT DefWindowProcA(
          # [in] HWND   hWnd,
          # [in] UINT   Msg,
          # [in] WPARAM wParam,
          # [in] LPARAM lParam
          # );
          
        end
      end # if @os_win 
      
      ################################
      # generic memory dump routines
      ################################ 
      
      # Dump ruby object. Count is the number of 16 byte lines
      #
      def self.memory_dump_object(object, count = 8)
        version = RUBY_VERSION.split('.')
        if (version[0].to_i == 2) &&  version[1].to_i < 7 
          address = object.object_id << 1
        else
          address_string = object.inspect.match(/0x([0-9a-f]+)/)[1]
          address = address_string.to_i(16)
        end
        memory_dump_address(address, count)  if address > 0x100000000
      end


      # Dump a memory address
      #
      def self.memory_dump_address(address, count = 8)
        ptr = Fiddle::Pointer.new(address)
        memory_dump_fiddle_ptr(ptr, count)
      end

      ############################################
      # Dump 'count' rows (16 bytes) of memory at address [Fiddle::Pointer] ptr.
      #
      def self.memory_dump_fiddle_ptr(ptr, count = 8)
        offset  = 0
        count.times {
          print (ptr.to_int + offset).to_s(16) # physical address
          data = ptr[offset, 16]
          data.each_byte { |b| print (b < 16 ? ' 0' + b.to_s(16) : ' ' + b.to_s(16)) }
          print '  '
          data.each_char { |b|
            if b.ord > 0x20
              print ' ' + b.to_s
            else
              print ' '
            end
          }
          offset += 16
          puts
        }
        puts
      end
      
      # Dump a string as hexadecimal bytes
      #   ie. with leading zeros
      def self.dump_string_as_hex(str)
        p str.each_byte.map { |b| (b < 16 ? ' 0' + b.to_s(16) : ' ' + b.to_s(16)) }.join
      end
     
    end # Util


    module Timers
      # A Single Shot timer has three states
      #   :idle
      #   :running
      #   :timed_out
      #
      # The state will progress to :running only if it is not :running
      # The state will progress to :timed_out only if it is :running
      # i.e. the timer must :idle or :timed_out to start another cycle. 
      #
      # Methods:
      #   new => new instance
      #   run(Numeric) => self  # The duration is in seconds. 
      #   reset => self
      #   state => Symbol (the state)
      #   timed_out? => Boolean # true if state is :timed_out
      #
      class SingleShotTimer
        class SingleShotTimerError < RuntimeError; end
        @state = :idle
        @thr = nil

        def run(duration = nil)
          if @state == :running
            raise SingleShotTimerError, 'Cannot Start Timer, State is Running' 
          elsif !duration.is_a?(Numeric)
            raise SingleShotTimerError, 'Cannot Start Timer, Duration must be a Numeric Type' 
          else
            run_thread(duration)
          end
          self 
        end
        
        def reset()
          @thr.exit if @thr
          @state = :idle
          self
        end
        
        def run_thread(duration)
          @state = :running
          @thr = Thread.new { 
            sleep(duration)
            @state = :timed_out
          }
          # @thr.priority = 2
        end
        
        # return the timer state
        def state()
          @state
        end
        
        def timed_out?
          @state == :timed_out
        end

      end # SingleShot
    end # Timers
  end
  @peekaboo_loaded = true
end
nil




