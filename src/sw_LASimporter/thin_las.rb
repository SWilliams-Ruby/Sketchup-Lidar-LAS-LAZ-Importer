module SW
  module LASimporter
    module ThinLas
      def thin(points, pbar, reduce_percent)
        #reduce_percent = 0.15
        pbar.label = "Total Progress"
        pbar.set_value(0.0)
        refresh_pbar(pbar, "Thinning Data Set by #{(1 - reduce_percent) * 100}%", 0.0)
        
        p desired_size = points.size * reduce_percent
        p cell_count = Math.sqrt(desired_size).to_i

        # find the bounds of the points
        xmin, xmax = points.minmax_by { |pt| pt[0] }
        ymin, ymax = points.minmax_by { |pt| pt[1] }
        xmin = xmin[0] - 0.01
        xmax = xmax[0] + 0.01
        ymin = ymin[1] + 0.01
        ymax = ymax[1] + 0.01

        # Create bins, an array of arrays
        # sort points by x and y into an array of arrays, cell_bount by cell_count in size
        # keep the highest point in each cell
        bins = []
        cell_count.times { |i| bins << [] }

        devisorx = (xmax - xmin) / cell_count
        devisory = (ymax - ymin) / cell_count
        bins

        # bin by x value
        points.each { |pt|   bins[(pt[0] - xmin)/devisorx] << pt }

        # for each x bin decimate by y value
        # return point with the highest z
        results = []
        bins.each { |bin|
          bins2 = []
          cell_count.times { |i| bins2 << [] }  
          bin.each { |pt| bins2[(pt[1] - ymin)/devisory] << pt }
          
          bins2.each {|bin| 
            #min, max =  bin.minmax_by { |pt| pt[3] }
            if bin.size > 0
              results << bin[rand(bin.size)]
            end
          }
        }

        puts "results"
        p results.size
        results
      end
    end
  end
end
nil