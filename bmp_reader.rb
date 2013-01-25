# encoding: UTF-8

# Заголовок файла
BmpFileHeader = Struct.new(
	:header,    # [00] Заголовок
	:file_size, # [02] Размер всего файла
	:reserved1, # [06] Зарезервированные байты (1)
	:reserved2, # [08] Зарезервированные байты (2)
	:off_bits   # [10] Оффсет начала изображения
)

# Заголовок изображения
BmpMapHeader = Struct.new(
	:size,         # [00 (14)] Размер структуры в байтах
	:width,        # [04 (18)] Ширина изображения
	:height,       # [08 (22)] Высота изображения
	:planes,       # [12 (26)] Количество плоскостей
	:bpp,          # [14 (28)] Бит / пиксел
	:compression,  # [16 (30)] Сжатие
	:image_size,   # [20 (34)] Размер самого изображения
	:xppm,         # [24 (38)] Пиксел / метр по ширине
	:yppm,         # [28 (42)] Пиксел / метр по длине
	:clr_used,     # [32 (46)] Количество использованных цветов
	:clr_important # [36 (50)] Количество важных цветов
)

# Набор RGB-компонент
PixelRGB = Struct.new(
	:red,   # Красная компонента
	:green, # Зелёная компонента
	:blue   # Синяя компонента
)


class BMPEditor

	attr :file_name, true
	attr :pixels, true
	attr :file_header
	attr :map_header
	attr :width
	attr :height
	attr :bpp

    def initialize(file_name = nil, autoread = false)
		@file_name = file_name
		if autoread then read end
    end

    def read
    	io = File.open(file_name)

    	# File header
		header, file_size, reverved1, reserved2, off_bits =
			io.read(14).unpack('A2LSSL')
		@file_header = BmpFileHeader.new(header, file_size, reverved1, reserved2, off_bits)

		# Map header
		size, width, height, planes, bpp, compression,
		image_size, xppm, yppm, clr_used, clr_important =
			io.read(40).unpack('LLLSSLLLLLL')
		@map_header = BmpMapHeader.new(size, width, height, planes, bpp, compression,
			image_size, xppm, yppm, clr_used, clr_important)
		@width, @height, @bpp = width, height, bpp

		io.seek(file_header[:off_bits], IO::SEEK_SET)
		@pixels, line = [[]], 0
		# Количество байт для выравнивания
		alignment = width * 3 % 4
		# Теоретически должно помочь обрабатывать данные с bpp=32
		bytes_per_pixel = bpp / 8
		bytes_per_line = bytes_per_pixel * width
		# Чтение изображения по линиям
		while (buffer = io.read(bytes_per_line)) do
			@pixels[line] = Array.new()
			bytes, index = buffer.bytes.to_a, 0
			while index < bytes_per_line do
				# Сделать поддержку записи в 4 переменные (+ альфа-канал)
				b, g, r = bytes[index .. index + bytes_per_pixel]
				pixel = PixelRGB.new(r, g, b)
				@pixels[line].push(pixel)
				index += bytes_per_pixel
			end
			# Считывание лишних байт, добавленных для выравнивания
			if alignment != 0 then io.read(alignment) end
			line += 1
		end
		@pixels.reverse!
    end

    # Преобразовывает изображение в оттенки серого
    def to_greyscale
    	@pixels.each_with_index { |line, i|
    		line.each_with_index { |pixel, j|
    			grayed = (pixel.red + pixel.green + pixel.blue) / 3
    			@pixels[i][j] = PixelRGB.new(grayed, grayed, grayed)
    		}
    	}
    end

    # Преобразовывает изображение в сепию или типа того
    # depth - уровень сепии, обычно значения 20 хватает.
    def to_sepia(depth = 20)
    	@pixels.each_with_index { |line, i|
    		line.each_with_index { |pixel, j|
    			gr = (pixel.red + pixel.green + pixel.blue) / 3
    			r, g, b = gr + (depth * 2), gr + depth, gr
		        if r > 255 then r = 255 end
		        if g > 255 then g = 255 end
		        if b > 255 then b = 255 end
		        @pixels[i][j] = PixelRGB.new(r, g, b)
    		}
    	}
    end

    # Преобразовывает изображение из RGB в BGR форму
    def to_bgr
    	@pixels.each_with_index { |line, i|
    		line.each_with_index { |pixel, j|
    			r, g, b = pixel.red, pixel.green, pixel.blue
    			@pixels[i][j] = PixelRGB.new(b, g, r)
    		}
    	}	
    end

    # Инвертирует изображение
    def invert
    	@pixels.each_with_index { |line, i|
    		line.each_with_index { |pixel, j|
    			r, g, b = pixel.red, pixel.green, pixel.blue
    			@pixels[i][j] = PixelRGB.new(255 - r, 255 - g, 255 - b)
    		}
    	}
    end

    # Поворачивает изображение на 180 градусов
    def flip_vertical
    	@pixels.reverse!
    end

    def flip_horizontal
    	rotate_180
    	flip_vertical
    end

    # Поворачивает изображение на 180 градусов
    def rotate_180
    	2.times { rotate_clockwise }
    end

    # Поворачивает изображение влево
    def rotate_counterclockwise
    	new_pixels = [[]]
    	(0 ... width).each { |y|
    		new_pixels[y] = Array.new()
    		(0 ... @height).each { |x|
	    		new_pixels[y][x] = @pixels[x][y]
    		}
	    }
	    # Заменяем существующий массив с набором пикселов
	    @pixels = new_pixels.reverse
	    # После поворота изображения нужно также поменять местами высоту и ширину 
	    @map_header[:width] = @height
	    @map_header[:height] = @width
	    @width, @height = @height, @width
    end

    # Поворачивает изображение вправо
    #def rotate_right
    #	# TODO: высплюсь и исправлю. Наверное.
    #	3.times { rotate_left }
    #end

    # Поворачивает изображение влево
    def rotate_clockwise
    	new_pixels = [[]]
    	(0 ... width).each { |y|
    		new_pixels[y] = Array.new()
    		(0 ... @height).each { |x|
	    		new_pixels[y][x] = @pixels[@height - 1 - x][y]
    		}
	    }
	    # Заменяем существующий массив с набором пикселов
	    @pixels = new_pixels
	    # После поворота изображения нужно также поменять местами высоту и ширину 
	    @map_header[:width] = @height
	    @map_header[:height] = @width
	    @width, @height = @height, @width
    end

    # Записывает изображение обратно в файл
    def write(output_file)
    	# Открытие файла для записи
    	# Алсо, запись крешится при записи байта с кодом 10,
    	# если не установлен флаг b
    	io = File.open(output_file, 'wb')
    	fh, mh = @file_header, @map_header

    	# Заголовок файла
    	io.write [fh.header, fh.file_size, fh.reserved1,
    		fh.reserved2, fh.off_bits].pack('A2LSSL')

    	# Заголовок изображения
    	io.write [mh.size, mh.width, mh.height, mh.planes, 
    		mh.bpp, mh.compression, mh.image_size, mh.xppm,
    		mh.yppm,mh.clr_used, mh.clr_important].pack('LLLSSLLLLLL')

		# Количество байт для выравнивания
		alignment = width * 3 % 4

		# Перед сохранением файла, порядок линий нужно инвертировать
    	@pixels.reverse.each { |l|
    		# Запись пиксела в файл
    		l.each do |p| io.write [p.blue, p.green, p.red].pack('C3') end
    		# Выравнивание до числа байт, кратному 4
			io.write('0' * alignment)
    	}
    end
end