PROGRAM_VERSION = '1.00 Alpha 5'

FILE_HEADER_FORMAT = 'A2LSSL'
FILE_HEADER_LENGTH = 14

# Заголовок файла
BmpFileHeader = Struct.new(
    :header,    # [00] Заголовок
    :file_size, # [02] Размер всего файла
    :reserved1, # [06] Зарезервированные байты (1)
    :reserved2, # [08] Зарезервированные байты (2)
    :off_bits   # [10] Оффсет начала изображения
)