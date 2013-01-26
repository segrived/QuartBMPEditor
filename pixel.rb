# Представляет RGB пиксел в виде класса
class PixelRGB
    attr_accessor :red
    attr_accessor :green
    attr_accessor :blue

    # Короткие алиасы для цветов
    alias_method :r, :red
    alias_method :g, :red
    alias_method :b, :red

    def initialize(r, g, b)
        @red, @green, @blue = r, g, b 
    end

    def median!
        norm = (@red + @green + @blue) / 3
        @red = @green = @blue = norm
    end

    def median
        norm = (@red + @green + @blue) / 3
        PixelRGB.new(norm, norm, norm)
    end

    def normalize!
        @red = norm_component @red
        @green = norm_component @green
        @blue = norm_component @blue
    end

    def normalize
        PixelRGB.new(
            norm_component(@red),
            norm_component(@green),
            norm_component(@blue)
        )
    end

    def invert!
        @red, @green, @blue = 255 - @red, 255 - @green, 255 - @blue
    end

    def invert
        PixelRGB.new(255 - @red, 255 - @green, 255 - @blue)
    end

    private

    def norm_component(c)
        color = c
        if(c < 0) then color = 0 end
        if(c > 255) then color = 255 end
        color
    end
end