# encoding: UTF-8

require 'optparse'
require './bmp_editor'

version = "1.00a2"

STDOUT.sync = true

options = {}
allowed_effects = %w[invert greyscale grayscale sepia bgr]
allowed_rotate_var = %w[clockwise counterclockwise 180 vertical horizontal]
OptionParser.new do |opts|
	options[:effects] = Array.new
	opts.banner = "Использование: bmp_reader.rb [опции]"
	opts.on("-v", "--version", "Отобразить версию программы") do |v|
		puts "Quart BMP Editor, version %s" % [version]
		exit
	end
	opts.on("-i", "--input FILENAME", "Имя исходного файла") do |f|
		options[:input_file] = f
	end
	opts.on("-o", "--output FILENAME", "Имя файла для сохранения") do |o|
		options[:output_file] = o
	end
	opts.on("-e", "--effects EFFECTS", "Список применяемых к изображению эффектов") do |e|
		e.split(/,/).each { |en|
			options[:effects].push en if allowed_effects.include? en
		}
		options[:effects].uniq!
	end
	opts.on("-r", "--rotate ROTATE", "Поворот изображения") do |r|
		options[:rotate] = r if allowed_rotate_var.include? r
	end
	opts.on_tail("-h", "--help", "Показать это сообщение") do
		abort(opts.to_s)
	end
end.parse!

abort("Не указано имя входного файла") unless options[:input_file]
abort("Не указано имя выходного файла") unless options[:output_file]
abort("Входной файл не найден") unless File.exist? options[:input_file]

puts "Открытие и чтение изображения в файл"
bmp = BMPReader.new options[:input_file], true
options[:effects].each { |effect|
	puts "Применение эффекта %s" % [effect]
	case effect
		when "invert"         then bmp.invert
		when /^gr[ea]yscale$/ then bmp.to_greyscale
		when "sepia"          then bmp.to_sepia 30
		when "bgr"            then bmp.to_bgr
	end
}

if options[:rotate]
	puts "Поворот изображения, использую функцию %s" % [options[:rotate]]
	case options[:rotate]
		when "clockwise"        then bmp.rotate_clockwise
		when "counterclockwise" then bmp.rotate_counterclockwise
		when "180"              then bmp.rotate_180
		when "vertical"         then bmp.flip_vertical
		when "horizontal"       then bmp.flip_horizontal
	end
end

puts "Запись результатирующего изображения в файл"
bmp.write options[:output_file]