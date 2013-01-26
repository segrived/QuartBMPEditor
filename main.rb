# encoding: UTF-8

require './bmp_editor'
require './options_parser'

version = "1.00a4"

STDOUT.sync = true

# Массив с опциями программы
options = Options.get_all

# Обработчики ошибок
abort("Не указано имя входного файла") unless options[:input_file]
abort("Не указано имя выходного файла") unless options[:output_file]
abort("Входной файл не найден") unless File.exist? options[:input_file]

bmp = BMPEditor.new options[:input_file]

# Применяемые эффекты
options[:effects].each { |effect|
    method = "effect_" + effect
    if bmp.respond_to?(method)
        bmp.method(method).call
    end
}

if options[:rotate]
    method = 'rotate_' + options[:rotate]
    bmp.method(method).call if bmp.respond_to?(method)
end

if options[:flip]
    method = 'flip_' + options[:flip]
    bmp.method(method).call if bmp.respond_to?(method)
end

bmp.save_to options[:output_file]