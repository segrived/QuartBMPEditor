# encoding: UTF-8

require 'optparse'

class Options

    def self.get_all
        options = {}
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
                options[:effects] = e.split(/,/).uniq
            end

            # Поворот изображения
            opts.on("-r", "--rotate ROTATE", "Поворот изображения") do |r|
                options[:rotate] = r
            end

            # Зеркальное отражение изображения
            opts.on("-f", "--flip FLIP", "Отражение изображения") do |f|
                options[:flip] = f
            end

            # Справка о программе
            opts.on_tail("-h", "--help", "Показать это сообщение") do
                abort(opts.to_s)
            end
        end.parse!

        options
    end

end