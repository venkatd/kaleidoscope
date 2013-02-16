require 'RMagick'

class Color
  def initialize(pixel)
    @pixel = pixel
  end

  def pixel
    @pixel
  end

  def pixel= pixel
    @pixel = pixel
  end

  def hex
    @hex
  end

  def hex= hex
    @hex = hex
  end

  def compare
    lab_to_compare = self.get_lab

    colors = ["#660000", "#990000", "#cc0000", "#cc3333", "#ea4c88",
       "#993399", "#663399", "#333399", "#0066cc", "#0099cc", "#66cccc",
       "#77cc33", "#669900", "#336600", "#666600", "#999900", "#cccc33",
       "#ffff00", "#ffcc33", "#ff9900", "#ff6600", "#cc6633", "#996633",
       "#663300", "#000000", "#999999", "#cccccc", "#ffffff"];

    colors_lab = []

    colors.each do |color|
       pixel = Magick::Pixel.from_color(color)
       lab = lab_from_pixel(pixel)
       array = [color, lab]
       colors_lab << array
    end

    matches = match_color(lab_to_compare, colors_lab)

    sort_matches(matches)

    return matches.first
  end


  def from_rgb_to_xyz(rgb)
    r = ( rgb[:r] / 255.0 )                     # RGB from 0 to 255
    g = ( rgb[:g] / 255.0 )
    b = ( rgb[:b] / 255.0 )

    if ( r > 0.04045 )
       r = ( ( r + 0.055 ) / 1.055 ) ** 2.4
    else
       r = r / 12.92
    end

    if ( g > 0.04045 )
       g = ( ( g + 0.055 ) / 1.055 ) ** 2.4
    else
       g = g / 12.92
    end

    if ( b > 0.04045 )
       b = ( ( b + 0.055 ) / 1.055 ) ** 2.4
    else
       b = b / 12.92
    end

    r = r * 100
    g = g * 100
    b = b * 100

    # Observer. = 2°, Illuminant = D65
    x = r * 0.4124 + g * 0.3576 + b * 0.1805
    y = r * 0.2126 + g * 0.7152 + b * 0.0722
    z = r * 0.0193 + g * 0.1192 + b * 0.9505

    return { :x => x, :y => y, :z => z }
  end

  def from_xyz_to_lab(xyz)
    # Observer= 2°, Illuminant= D65
    x = xyz[:x] / 95.047
    y = xyz[:y] / 100.000
    z = xyz[:z] / 108.883

    if ( x > 0.008856 )
       x = x ** ( 1.0/3.0 )
    else
       x = ( 7.787 * x ) + ( 16.0 / 116.0 )
    end


    if ( y > 0.008856 )
       y = y ** ( 1.0/3.0 )
    else
       y = ( 7.787 * y ) + ( 16.0 / 116.0 )
    end

    if ( z > 0.008856 )
       z = z ** ( 1.0/3.0 )
    else
       z = ( 7.787 * z ) + ( 16.0 / 116.0 )
    end

    l = ( 116 * y ) - 16
    a = 500 * ( x - y )
    b = 200 * ( y - z )

    return { :l => l, :a => a, :b => b }
  end

  def rgb_to_lab(rgb)
    xyz = self.from_rgb_to_xyz(rgb)
    lab = self.from_xyz_to_lab(xyz)
    return lab
  end

  def get_lab
    lab_from_pixel(@pixel)
  end

  def lab_from_pixel(pixel)
    self.rgb_to_lab(self.rgb_from_pixel(pixel))
  end

  def rgb_from_pixel(pixel)
    r = pixel.red / 256
    g = pixel.green / 256
    b = pixel.blue / 256

    return { :r => r, :g => g, :b => b }
  end

  def match_color(lab, colors_lab)
    matches = []

    colors_lab.each do |color|
      a = lab.map { |k, v| v }
      b = color[1].map { |k, v| v }

      # Calculate the Euclidean distance between the colors
      distance = calculate_euclidean(a, b)

      match = { color: color[0], distance: distance }
      matches << match
    end

    return matches
  end

  def sort_matches(matches)
    matches.sort_by! { |k| k[:distance] }.first
  end

  def calculate_euclidean(a, b)
    a.zip(b).map { |x| (x[1] - x[0])**2 }.reduce(:+)
  end
end