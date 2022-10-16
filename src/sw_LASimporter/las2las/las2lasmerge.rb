module SW
  module Las2Las

    def self.entry()
      @filepaths = show_file_open_dialog()
      show_merge_dialog( @filepaths ) if @filepaths
    end
    
    def self.cancel_merge( dialog )
      @merge_cancelled = true
      dialog.update_element('status', 'Merge Cancelled')
      begin 
        Process.kill("KILL", @popen_processID ) if @popen_processID  
      rescue
      end
      #@thr.exit if @thr
    end

    def self.merge_files( dialog, filepaths, thin_to_grid )
      @merge_cancelled = false
      @popen_processID  = nil
      dialog.update_element('status', 'Processing')
      UI.start_timer(0) { defered_run_and_wait( dialog, filepaths, thin_to_grid ) }
    end

    # defer processing to allow javascript to run
    #
    def self.defered_run_and_wait( dialog, filepaths, thin_to_grid )
      @merge_thread_results = ""
      run_merge_thread( filepaths, thin_to_grid )
      UI.start_timer(1) { check_for_thread_death( dialog, 'Processing ', Time.now) }
    end
    
    def self.check_for_thread_death( dialog, status, start_time )
      if !@merge_cancelled and @thr.alive? and (Time.now - start_time) < 20
        status << '>'
        dialog.update_element('status', status)
        UI.start_timer(1) { check_for_thread_death( dialog, status, start_time ) }
      else
        unless @merge_cancelled
          puts 'Merge Completed'
          puts @merge_thread_results
          dialog.update_element('status', 'Merge Completed')
        end
      end
    end
    
    
    # Open the file picker application
    # 
    #
    def self.show_file_open_dialog()
      filepaths = []
      env = {}
      prog = File.join( SW::LASimporter::PLUGIN_DIR, 'las2las/bin/MultiFileOpenDialog.exe' )
      cmd  = [env, prog, :err=>[:child, :out] ]

      IO.popen(cmd, mode = 'a+') { |stream|
        until stream.eof? do
          filepath = stream.readline
          filepaths << filepath
        end
      }
      #puts filepaths.size
      #puts filepaths
      filepaths
    end
    
    
    def self.run_merge_thread( filepaths, thin_to_grid )
      @thr = Thread.new {
        env = {}
        prog = File.join( SW::LASimporter::PLUGIN_DIR, 'las2las/bin/las2lasw.exe' )
        filepaths.each { |path| path.strip!}
        
        # construct arguements to las2lasw.exe
        # las2lasw.exe is an exe with the SYSTEM/WINDOWS value set in the Process Environment (PE) Header 
        args = [
          "-very_verbose",
          "-i",
          *filepaths,
          "-merged",
          "-o",
          File.dirname(filepaths[0]) + "\\merged.las"
        ]

        # add thinning requirement
        unless thin_to_grid == "FullSize"  
          args << "-thin_with_grid"
          args << thin_to_grid
        end
        
        cmd  = [env, prog, *args, :err=>[:child, :out] ]
        IO.popen(cmd, mode = 'a+') { |stream|
          @popen_processID = stream.pid
          until stream.eof? do
            @merge_thread_results << stream.readline
            #puts stream.readline
          end
        }
        @popen_processID = nil
      }
    end

  end
end
