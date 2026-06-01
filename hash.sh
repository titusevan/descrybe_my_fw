#!/bin/bash

# --- Настройки ---
# Имя выходного файла
OUTPUT_FILE="garnet.json"
# Жестко заданные значения (скопированы из вашего примера)
MAINTAINER="titusevan"
OEM="Poco"
DEVICE_NAME="Poco X6 5G"
CRDROID_VERSION="12.1"
BUILD_TYPE="Weekly"
BASE_DOWNLOAD_URL="https://saz.mksat.net/firmware/garnet/crdroid/"
GAPPS_URL="https://saz.mksat.net/firmware/garnet/crdroid/NikGaps.zip"

# Сдвиг времени: 6 часов 10 минут= 22200 секунд
OFFSET_SECONDS=22200

# --- Функции ---
usage() {
    echo "Использование: $0 <путь_к_zip_файлу>"
    echo "Пример: $0 out/target/product/garnet/crDroidAndroid-16.0-20251003-garnet-v12.1-rmapps-srv.zip"
    exit 1
}


# --- Основная логика ---
if [ -z "$1" ]; then
    usage
fi


FILE_PATH="$1"


if [ ! -f "$FILE_PATH" ]; then
    echo "Ошибка: Файл '$FILE_PATH' не найден."
    exit 1
fi


if ! command -v stat &> /dev/null || ! command -v md5sum &> /dev/null || ! command -v sha256sum &> /dev/null; then
    echo "Ошибка: Не найдены необходимые утилиты (stat, md5sum, sha256sum). Установите их."
    exit 1
fi


echo "Расчет метаданных для: $FILE_PATH..."


# 1. Динамические вычисления
FILE_SIZE=$(stat -c %s "$FILE_PATH")

# Извлечение версии: ищем шаблон, начинающийся с 'v' и заканчивающийся перед '.zip'
CRDROID_VERSION=$(echo "$FILE_PATH" | grep -oP 'v[0-9]+(\.[0-9]+)+' | head -n1)

if [ -z "$CRDROID_VERSION" ]; then
    echo "Ошибка: Не удалось извлечь версию (например, v12.1) из имени файла: $FILENAME"
    echo "Проверьте, соответствует ли имя файла шаблону: *-vX.X-*.zip"
    exit 1
fi

# УДАЛЯЕМ ПРЕФИКС 'v': используем sed для удаления первого символа
CRDROID_VERSION=$(echo "$CRDROID_VERSION" | sed 's/^v//')

# Получаем фактическую метку времени файла
ACTUAL_TIMESTAMP=$(stat -c %Y "$FILE_PATH")


# Вычисляем метку времени для JSON: Время файла минус 2 часа (7200 сек)
JSON_TIMESTAMP=$((ACTUAL_TIMESTAMP - OFFSET_SECONDS))

# Используем команду date с флагом -d @ (или -r для macOS) и нужным форматом
JSON_DATE=$(date -d @"$JSON_TIMESTAMP" +"%Y-%m-%d %H:%M:%S %Z")

# Продолжаем расчеты
MD5_HASH=$(md5sum "$FILE_PATH" | awk '{print $1}')
SHA256_HASH=$(sha256sum "$FILE_PATH" | awk '{print $1}')
FILENAME=$(basename "$FILE_PATH")
DOWNLOAD_URL="${BASE_DOWNLOAD_URL}${FILENAME}"


# 2. Генерация JSON-содержимого и перенаправление в выходной файл
# В поле "timestamp" теперь используется JSON_TIMESTAMP
cat << EOF > "$OUTPUT_FILE"
{
    "response": [
        {
            "maintainer": "$MAINTAINER",
            "oem": "$OEM",
            "device": "$DEVICE_NAME",
            "filename": "$FILENAME",
            "download": "$DOWNLOAD_URL",
            "timestamp": $JSON_TIMESTAMP,
            "md5": "$MD5_HASH",
            "sha256": "$SHA256_HASH",
            "size": $FILE_SIZE,
            "version": "$CRDROID_VERSION",
            "buildtype": "$BUILD_TYPE",
            "forum": "",
            "gapps": "$GAPPS_URL",
            "firmware": "",
            "modem": "",
            "bootloader": "",
            "recovery": "",
            "paypal": "",
            "telegram": "",
            "dt": "",
            "common-dt": "",
            "kernel": ""
        }
    ]
}

EOF



# 3. Сообщение об успехе
if [ $? -eq 0 ]; then
    echo "Успех! Файл '$OUTPUT_FILE' создан в текущей директории."
    echo "Извлеченная версия (version): $CRDROID_VERSION"
    echo "Временная метка в JSON (timestamp): $JSON_TIMESTAMP ($JSON_DATE)"
    echo "Прямая ссылка (download): $DOWNLOAD_URL"
else
    echo "Ошибка при создании файла '$OUTPUT_FILE'."
fi
