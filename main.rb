# encoding: UTF-8

require 'optparse'
require './bmp_editor'

version = "1.00a3"

STDOUT.sync = true

# Массив с опциями программы
options = {}

# Доступные эффекты и варианты поворота изображения
allowed_effects = %w[invert greyscale grayscale sepia bgr]
allowed_rotate_var = %w[clockwise counterclockwise 180 vertical horizontal]

# Обработка переданных параметров командной строки
OptionParser.new do |opts|
    options[:effects] = Array.new
    opts.banner = "Использование: bmp_reader.rb [опции]"

    # Версия программы
    opts.on("-v", "--version", "Отобразить версию программы") do |v|
        puts "Quart BMP Editor, version %s" % [version]
        exit
    end

    # Имя входного файла
    opts.on("-i", "--input FILENAME", "Имя исходного файла") do |f|
        options[:input_file] = f
    end

    # Имя файла для сохранения
    opts.on("-o", "--output FILENAME", "Имя файла для сохранения") do |o|
        options[:output_file] = o
    end

    # Список эффектов
    opts.on("-e", "--effects EFFECTS", "Список применяемых к изображению эффектов") do |e|
        e.split(/,/).each { |en| options[:effects].push en if allowed_effects.include? en }
        # Удаление повторяющихся эффектов
        options[:effects].uniq!
    end

    # Поворот изображения
    opts.on("-r", "--rotate ROTATE", "Поворот изображения") do |r|
        options[:rotate] = r if allowed_rotate_var.include? r
    end

    # Справка о программе
    opts.on_tail("-h", "--help", "Показать это сообщение") do
        abort(opts.to_s)
    end
end.parse!

abort("Не указано имя входного файла") unless options[:input_file]
abort("Не указано имя выходного файла") unless options[:output_file]
abort("Входной файл не найден") unless File.exist? options[:input_file]

puts "Открытие и чтение изображения в файл"
bmp = BMPEditor.new options[:input_file], true
options[:effects].each { |effect|
    puts "Применение эффекта %s" % [effect]
    case effect
        when "invert"         then bmp.invert
        # Британская и английская версия
        when /^gr[ea]yscale$/ then bmp.to_greyscale
        when "sepia"          then bmp.to_sepia 30
        when "bgr"            then bmp.to_bgr
    end
}

if options[:rotate]
    puts "Поворот изображения, использую функцию %s" % [options[:rotate]]
    case options[:rotate]
        # Поворот изображения
        when "clockwise"        then bmp.rotate_clockwise
        when "counterclockwise" then bmp.rotate_counterclockwise
        when "180"              then bmp.rotate_180
        # Зеркальное отражение
        when "vertical"         then bmp.flip_vertical
        when "horizontal"       then bmp.flip_horizontal
    end
end

puts "Запись результатирующего изображения в файл"
bmp.write options[:output_file]