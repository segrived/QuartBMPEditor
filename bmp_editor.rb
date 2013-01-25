# encoding: UTF-8

require './bmp_reader'
require './global'


class BMPEditor

    attr :file_name, true

    def initialize(file_name = nil)
        @file_name = file_name
        @reader = BMPReader.new file_name, true
    end

    # Преобразовывает изображение в оттенки серого
    def to_greyscale
        @reader.pixels.each_with_index { |l, i|
            l.each_with_index { |p, j|
                gr = colour_median p
                @reader.pixels[i][j] = PixelRGB.new(gr, gr, gr)
            }
        }
    end

    # Преобразовывает изображение в сепию или типа того
    # depth - уровень сепии, обычно значения 20 хватает.
    def to_sepia(depth = 20)
        @reader.pixels.each_with_index { |l, i|
            l.each_with_index { |p, j|
                gr = colour_median p
                r, g, b = norm_colour(gr + (depth * 2)),
                    norm_colour(gr + depth),
                    norm_colour(gr)
                @reader.pixels[i][j] = PixelRGB.new(r, g, b)
            }
        }
    end

    # Преобразовывает изображение из RGB в BGR форму
    def to_bgr
        @reader.pixels.each_with_index { |l, i|
            l.each_with_index { |p, j|
                r, g, b = p.red, p.green, p.blue
                @reader.pixels[i][j] = PixelRGB.new(b, g, r)
            }
        }    
    end

    # Инвертирует изображение
    def invert
        @reader.pixels.each_with_index { |l, i|
            l.each_with_index { |p, j|
                r, g, b = p.red, p.green, p.blue
                @reader.pixels[i][j] = PixelRGB.new(255 - r, 255 - g, 255 - b)
            }
        }
    end

    # Поворачивает изображение на 180 градусов
    def flip_vertical
        @reader.pixels.reverse!
    end

    def flip_horizontal
        rotate_180
        flip_vertical
    end

    # Поворачивает изображение на 180 градусов
    def rotate_180
        2.times { rotate_clockwise }
    end

    # Поворачивает изображение против часовой стрелки
    def rotate_counterclockwise
        new_pixels = [[]]
        (0 ... width).each { |y|
            new_pixels[y] = Array.new()
            (0 ... @reader.height).each { |x|
                new_pixels[y][x] = @reader.pixels[x][y]
            }
        }
        # Заменяем существующий массив с набором пикселов
        @reader.pixels = new_pixels.reverse
        # После поворота изображения нужно также поменять местами высоту и ширину 
        @reader.map_header[:width] = @reader.height
        @reader.map_header[:height] = @reader.width
        @reader.width, @reader.height = @reader.height, @reader.width
    end

    # Поворачивает изображение по часовой стрелке
    def rotate_clockwise
        new_pixels = [[]]
        (0 ... width).each { |y|
            new_pixels[y] = Array.new()
            (0 ... @reader.height).each { |x|
                new_pixels[y][x] = @reader.pixels[@reader.height - 1 - x][y]
            }
        }
        # Заменяем существующий массив с набором пикселов
        @reader.pixels = new_pixels
        # После поворота изображения нужно также поменять местами высоту и ширину 
        @reader.map_header[:width] = @height
        @reader.map_header[:height] = @width
        @reader.width, @reader.height = @reader.height, @reader.width
    end

    def save
        @reader.write @file_name
    end

    def save_to(file)
        @reader.write file
    end

    private

    # Нормализует указанную компоненту цвета
    def norm_colour(c)
        colour = c
        if(c < 0) then colour = 0 end
        if(c > 255) then colour = 255 end
        colour
    end

    def colour_median(pixel)
        return pixel.to_a.inject(:+) / 3
    end

end