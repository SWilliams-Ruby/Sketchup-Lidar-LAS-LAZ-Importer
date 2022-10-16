# Trim the number of points to approximately
# reduce_percent of the original dataset
#
# @param points [Array] array of [x,y,x] arrays
# pbar progress bar to update
# reduce_percent [Float] 0.0 to 1.0 amount to reduce the dataset
# return points array
# 
module SW
  module LASimporter
    module ThinLas
      def thin(points, pbar, reduce_percent)
        pbar.label = "Total Progress"
        pbar.set_value(0.0)
        refresh_pbar(pbar, "Thinning Data Set by #{((1.0 - reduce_percent) * 100).to_i}%", 0.0)
        
        desired_size = points.size * reduce_percent
        cell_count = Math.sqrt(desired_size).to_i

        # find the bounds of the points
        xmin, xmax = points.minmax_by { |pt| pt[0] }
        ymin, ymax = points.minmax_by { |pt| pt[1] }
        xmin = xmin[0] - 0.01
        xmax = xmax[0] + 0.01
        ymin = ymin[1] + 0.01
        ymax = ymax[1] + 0.01
        devisorx = (xmax - xmin) / cell_count
        devisory = (ymax - ymin) / cell_count

        # Create bins. An array of arrays
        # sort points by x and y into an array of bins that is cell_count by cell_count in size
        # return random point from each cell
        srand 1212 #randomizer seed
        bins = []
        results = []
        cell_count.times { |i| bins << [] }
        points.each { |pt| bins[(pt[0] - xmin)/devisorx] << pt }
        if pbar.update?
            refresh_pbar(pbar, "Thinning Data Set by #{((1.0 - reduce_percent) * 100).to_i}%", 50.0)
          end
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
        results
      end
    end
  end
end
nil