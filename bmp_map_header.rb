class BmpMapHeader

    attr :fields

    def initialize
        @fields = {}
    end

    def [](field)
        @fields[field]
    end

    def []=(field, value)
        @fields[field] = value
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