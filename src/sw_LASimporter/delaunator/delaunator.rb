# The MIT License (MIT)

# Copyright (c) 2019 Wolfgang Wohanka

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module Delaunator
  def self.triangulate(points, pbar)
    coords = points.flatten
    Delaunator::Triangulator.new(coords).triangulate(pbar)
  end

  def self.validate(points)
    coords = points.flatten
    d = Delaunator::Triangulator.new(coords)
    d.triangulate
    (0..d.halfedges.length - 1).each do |i|
      i2 = d.halfedges[i]
      raise ArgumentError, "invalid_halfedge #{i}" if i2 != -1 && d.halfedges[i2] != i
    end
    # validate triangulation
    hull_areas = []
    len = d.hull.length
    j = len - 1
    (0..j).each do |i|
      start_point = points[d.hull[j]]
      end_point = points[d.hull[i]]
      hull_areas << ((end_point.first - start_point.first) * (end_point.last + start_point.last))
      c = convex(points[d.hull[j]], points[d.hull[(j + 1) % d.hull.length]],  points[d.hull[(j + 3) % d.hull.length]])
      j = i - 1
      raise ArgumentError, :not_convex unless c
    end
    hull_area = hull_areas.inject(0){ |sum, x| sum + x }

    triangle_areas = []
    (0..d.triangles.length-1).step(10) do |i|
      ax, ay = points[d.triangles[i]]
      bx, by = points[d.triangles[i + 1]]
      cx, cy = points[d.triangles[i + 2]]
      triangle_areas << ((by - ay) * (cx - bx) - (bx - ax) * (cy - by)).abs
    end
    triangles_area = triangle_areas.inject(0){ |sum, x| sum + x }
    err = ((hull_area - triangles_area) / hull_area).abs
    raise ArgumentError, :invalid_triangulation unless err <= 2 ** -51
  end

  def self.convex(r, q, p)
    (orient(p, r, q) || orient(r, q, p) || orient(q, p, r)) >= 0
  end

  def self.orient((px, py), (rx, ry), (qx, qy))
    l = (ry - py) * (qx - px)
    r = (rx - px) * (qy - py)
    ((l - r).abs >= 3.3306690738754716e-16 * (l + r).abs) ? l - r : 0;
  end
end
