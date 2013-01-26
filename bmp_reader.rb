# encoding: UTF-8

require './global'

class BMPReader

    attr :file_name, true
    attr :pixels, true
    attr :width
    attr :height
    attr :bpp

    @map_header = nil

    def initialize(file_name = nil, autoread = false)
        @file_name = file_name
        if autoread then read end
    end

    # Читает заголовки файлов и массив пикселов
    def read
        # Заголовок файла и изображения
        @file_header = read_file_header
        @map_header = read_map_header

        # Присваивание значений переменным класса
        @width, @height, @bpp = @map_header[:width], @map_header[:height], @map_header[:bpp]

        f = File.open(file_name, 'r')
        # Переходим к началу изобраажения
        f.seek(@file_header[:off_bits], IO::SEEK_SET)

        @pixels, line = [[]], 0
        # Количество байт на пиксель
        bytes_per_pixel = bpp / 8
        # Количество байт для выравнивания
        alignment = @width * bytes_per_pixel % 4
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
            fh.reserved2, fh.off_bits].pack(FILE_HEADER_FORMAT)

        # Заголовок изображения
        io.write @map_header.generate_header

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
            f.read(FILE_HEADER_LENGTH).unpack(FILE_HEADER_FORMAT)
        f.close
        BmpFileHeader.new(header, file_size, reverved1, reserved2, off_bits)
    end

    def read_map_header
        f = File.open(@file_name, 'r')
        f.seek(FILE_HEADER_LENGTH, IO::SEEK_SET)
        length = f.read(4).unpack('L')[0]
        inst = case length
            when 12 then ::BmpMapHeaderOCH.new
            when 40 then ::BmpMapHeaderBIH.new
            else raise 'Неизвестный формат BMP-файла'
        end
        inst.read_header f
        inst
    end

end


class BmpMapHeader

    attr :fields

    def initialize
        @fields = {}
    end

    def [](field)
        @fields[field]
    end

    def read_header(io)
        raise NotImplementedError
    end

    def generate_header
        raise NotImplementedError
    end

end

class BmpMapHeaderBIH < BmpMapHeader

    LENGTH = 40
    FORMAT = 'LLLSSLLLLLL'

    def read_header(io)
        io.seek(FILE_HEADER_LENGTH, IO::SEEK_SET)
        size, width, height, planes, bpp, compression, image_size,
        xppm, yppm, clr_used, clr_important = io.read(LENGTH).unpack(FORMAT)
        @fields = { :size => size, :width => width, :height => height,
            :planes => planes, :bpp => bpp, :compression => compression,
            :image_size => image_size, :xppm => xppm, :yppm => yppm,
            :clr_used => clr_used, :clr_important => clr_important
        }
    end

    def generate_header
        [@fields[:size], @fields[:width], @fields[:height],
            @fields[:planes], @fields[:bpp], @fields[:compression],
            @fields[:image_size], @fields[:xppm], @fields[:yppm],
            @fields[:clr_used], @fields[:clr_important]
        ].pack(FORMAT)
    end
end

class BmpMapHeaderOCH < BmpMapHeader

    header = {
        :length => 12,
        :format => 'LSSSS'
    }

    def read_header(io)
        io.seek(FILE_HEADER_LENGTH, IO::SEEK_SET)
        size, width, height, planes, bpp = io.read(header[:length]).unpack(header[:format])
        @fields = { :size => size, :width => width, :height => height,
            :planes => planes, :bpp => bpp
        }
    end

    def generate_header
        [@fields[:size], @fields[:width], @fields[:height],
            @fields[:planes], @fields[:bpp]
        ].pack(header[:format])
    end
end