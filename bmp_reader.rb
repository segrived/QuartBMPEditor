require './global'

class BMPReader

    FILE_HEADER = 'A2LSSL'
    MAP_HEADER  = 'LLLSSLLLLLL'
    FILE_HEADER_LENGTH = 14
    MAP_HEADER_LENGTH  = 40

    attr :file_name, true
    attr :pixels, true
    attr :width
    attr :height
    attr :bpp

    def initialize(file_name = nil, autoread = false)
        @file_name = file_name
        if autoread then read_file end
    end

    # Читает заголовки файлов и массив пикселов
    def read_file
        # Заголовок файла и изображения
        @file_header, @map_header = read_file_header, read_map_header
        # Присваивание значений переменным класса
        @width, @height, @bpp = @map_header[:width], @map_header[:height], @map_header[:bpp]

        f = File.open(file_name, 'r')
        # Переходим к началу изобраажения
        f.seek(@file_header[:off_bits], IO::SEEK_SET)
        @pixels, line = [[]], 0
        # Количество байт для выравнивания
        alignment = @width * 3 % 4
        # Теоретически должно помочь обрабатывать данные с bpp=32
        bytes_per_pixel = bpp / 8
        bytes_per_line = bytes_per_pixel * width
        # Чтение изображения по линиям
        while (buffer = f.read(bytes_per_line)) do
            @pixels[line] = Array.new
            bytes, index = buffer.bytes.to_a, 0
            while index < bytes_per_line do
                # Сделать поддержку записи в 4 переменные (+ альфа-канал)
                b, g, r = bytes[index .. index + bytes_per_pixel]
                pixel = PixelRGB.new(r, g, b)
                @pixels[line].push(pixel)
                index += bytes_per_pixel
            end
            # Считывание лишних байт, добавленных для выравнивания
            if alignment != 0 then f.read(alignment) end # > /dev/null
            line += 1
        end
        @pixels.reverse!
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
            fh.reserved2, fh.off_bits].pack(FILE_HEADER)

        # Заголовок изображения
        io.write [mh.size, mh.width, mh.height, mh.planes, 
            mh.bpp, mh.compression, mh.image_size, mh.xppm,
            mh.yppm,mh.clr_used, mh.clr_important].pack(MAP_HEADER)

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

    # Возвращает структуру с заголовкой файла
    def read_file_header
        f = File.open(file_name, 'r')
        header, file_size, reverved1, reserved2, off_bits =
            f.read(FILE_HEADER_LENGTH).unpack(FILE_HEADER)
        f.close
        BmpFileHeader.new(header, file_size, reverved1, reserved2, off_bits)
    end

    # Возвращает структуру с заголоком изображения
    def read_map_header
        f = File.open(file_name, 'r')
        f.seek(FILE_HEADER_LENGTH)
        size, width, height, planes, bpp, compression,
        image_size, xppm, yppm, clr_used, clr_important =
            f.read(MAP_HEADER_LENGTH).unpack(MAP_HEADER)
        f.close
        BmpMapHeader_BITMAPINFOHEADER.new(size, width, height, planes, bpp, compression,
            image_size, xppm, yppm, clr_used, clr_important)
    end

end