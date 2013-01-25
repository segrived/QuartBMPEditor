# encoding: UTF-8

require 'optparse'

class Options

    # Доступные эффекты и варианты поворота изображения
    ALLOWED_EFFECTS = %w[invert greyscale grayscale sepia bgr]
    ALLOWED_ROTATE_VAR = %w[clockwise counterclockwise 180 vertical horizontal]

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
                e.split(/,/).each { |en| options[:effects].push en if ALLOWED_EFFECTS.include? en }
                # Удаление повторяющихся эффектов
                options[:effects].uniq!
            end

            # Поворот изображения
            opts.on("-r", "--rotate ROTATE", "Поворот изображения") do |r|
                options[:rotate] = r if ALLOWED_ROTATE_VAR.include? r
            end

            # Справка о программе
            opts.on_tail("-h", "--help", "Показать это сообщение") do
                abort(opts.to_s)
            end
        end.parse!

        options
    end

end