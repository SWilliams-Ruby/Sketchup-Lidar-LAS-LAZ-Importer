module SW
  module Las2Las
    @max_run_time = 100.0
    
    def self.entry()
      @filepaths = show_file_open_dialog()
      show_merge_dialog( @filepaths ) if @filepaths # See: merge_dialog.exe
    end
 
    # Open the file picker application
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
      filepaths
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

    # defer processing to allow javascript to run
    #
    def self.merge_files( dialog, filepaths, grid_size, classifications)
      @merge_cancelled = false
      @popen_processID  = nil
      dialog.update_element('status', 'Processing')
      dialog.update_element('results', '')
      UI.start_timer(0) { deferred_run_and_wait( dialog, filepaths, grid_size, classifications ) }
    end

    def self.deferred_run_and_wait( dialog, filepaths, grid_size, classifications )
      @merge_thread_results = ""
      execute_las2las_thread( filepaths, grid_size, classifications )
      UI.start_timer(1) { check_for_thread_death( dialog, 'Processing ', Time.now) }
    end
    
    def self.check_for_thread_death( dialog, status, start_time )
      if !@merge_cancelled and @thr.alive? and (Time.now - start_time) < @max_run_time
        status << '>'
        dialog.update_element('status', status)
        # dialog.update_element('results', @merge_thread_results) # to debug thread info
        UI.start_timer(1) { check_for_thread_death( dialog, status, start_time ) }
      else
        unless @merge_cancelled
          puts 'Merge Completed'
          p @merge_thread_results
          @merge_thread_results.gsub!(/\n/,"<br>")
          @merge_thread_results.gsub!(/\\/,"&bsol;")
          @merge_thread_results.gsub!(/'/,"&apos;")
          dialog.update_element('status', 'Merge Completed')
          dialog.update_element('results', @merge_thread_results)
        end
      end
    end

    # Popen las2lasw.exe to merge and thin the the selected files
    # las2lasw.exe is las2las.exe marked as a SYSTEM/WINDOWS application in the Process Environment (PE) Header 
    #
    def self.execute_las2las_thread( filepaths, grid_size, classifications )
       p classifications
      @thr = Thread.new {
        begin
          env = {}
          prog = File.join( SW::LASimporter::PLUGIN_DIR, 'las2las/bin/las2lasw.exe' )
          filepaths.each { |path| path.strip!}
          outfilename = "\\merged_Files#{filepaths.size}_Grid#{grid_size}_#{classifications}.las"
   
          # construct arguments to las2lasw.exe
          args = [
            "-v",
            "-i",
            *filepaths,
            "-merged",
            "-o",
            File.dirname(filepaths[0]) + outfilename
          ]

          # add thinning requirement
          unless grid_size == "FullSize"  
            args << "-thin_with_grid"
            args << grid_size
          end
          
          unless classifications == "All"
            args << "-keep_class"
            if classifications == "Ground"
               args << "2" # ground
            else
               args << "2"
               args << "9" # water
            end
          end
          # @merge_thread_results << args.to_s # debug info
          
          cmd  = [env, prog, *args, :err=>[:child, :out] ]
          IO.popen(cmd, mode = 'a+') { |stream|
            @popen_processID = stream.pid
            until stream.eof? do
              @merge_thread_results << stream.readline
              #puts stream.readline
            end
          }
          @popen_processID = nil
        rescue => exception
          @merge_thread_results << exception.message
        end
      }
    end

  end
end
