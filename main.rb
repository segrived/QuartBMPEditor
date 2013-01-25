# encoding: UTF-8

require './bmp_editor'
require './options_parser'

version = "1.00a3"

STDOUT.sync = true

# Массив с опциями программы
options = Options.get_all

# Обработчики ошибок
abort("Не указано имя входного файла") unless options[:input_file]
abort("Не указано имя выходного файла") unless options[:output_file]
abort("Входной файл не найден") unless File.exist? options[:input_file]

puts "Открытие и чтение изображения в файл"
bmp = BMPEditor.new options[:input_file]

# Применяемые эффекты
options[:effects].each { |effect|
    case effect
        when "invert"         then bmp.invert
        when "greyscale"      then bmp.to_greyscale
        when "greyscale_luma" then bmp.to_greyscale_luma
        when "sepia"          then bmp.to_sepia 30
        when "bgr"            then bmp.to_bgr
    end
}

# Настройки разворота изображения
if options[:rotate]
    case options[:rotate]
        when "clockwise"        then bmp.rotate_clockwise
        when "counterclockwise" then bmp.rotate_counterclockwise
        when "180"              then bmp.rotate_180
        when "vertical"         then bmp.flip_vertical
        when "horizontal"       then bmp.flip_horizontal
    end
end

bmp.save_to options[:output_file]