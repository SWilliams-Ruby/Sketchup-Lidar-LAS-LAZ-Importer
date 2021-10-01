# Public Header classes corresponding to the LAS version specifications
# We may customize each class at some time in the future
# see: http://www.asprs.org/wp-content/uploads/2019/03/LAS_1_4_r14.pdf for examples


module SW
  module LASimporter
   
    class PublicHeader_1_0 < PublicHeader
      include PublicHeaderMixin
      def initialize(fileStream)
        super # initialize PublicHeader
      end
    end 
 
    class PublicHeader_1_1 < PublicHeader
      include PublicHeaderMixin
      def initialize(fileStream)
        super # initialize PublicHeader
      end
    end 
 
   class PublicHeader_1_2 < PublicHeader
      include PublicHeaderMixin
      def initialize(fileStream)
        super # initialize PublicHeader
      end
    end 

    class PublicHeader_1_3 < PublicHeader
      include PublicHeaderMixin
      def initialize(fileStream)
        super # initialize PublicHeader
      end
    end 

    class PublicHeader_1_4 < PublicHeader
      include PublicHeaderMixin
      def initialize(fileStream)
        super # initialize PublicHeader
      end
    end 
        
  end
end


nil




