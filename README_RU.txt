GeoFree для Windows
===================

Назначение
----------
Пакет настраивает классический доступ к нейросетям через системный файл hosts.

Поддерживаемые сервисы:

ChatGPT и OpenAI API
Claude и Anthropic API
Gemini и Google AI Studio
Microsoft Copilot
Grok и xAI
ElevenLabs

Скрипт получает актуальные адреса из списка GeoHideDNS, перебирает кандидаты и оставляет адрес, который успешно проходит четыре HTTPS-проверки.


Запуск
------
1. Распакуйте ZIP-архив в обычную папку.
2. Откройте распакованную папку.
3. Нажмите правой кнопкой мыши на START-GEOFREE-AS-ADMIN.bat.
4. Выберите «Запуск от имени администратора».
5. Подтвердите запрос Windows.
6. Дождитесь сообщения:

   GeoFree AI access is ready

7. Перезапустите браузер и приложения нейросетей.


Проверка
--------
Запустите CHECK-GEOFREE.bat.

Колонки HostsEntry и CurrentResolve покажут одинаковый адрес для каждого сервиса.
Основной запуск также проверяет HTTPS-доступ к ChatGPT, OpenAI API, Claude и Gemini.


Удаление настроек
-----------------
Запустите REMOVE-GEOFREE-AS-ADMIN.bat от имени администратора.

Скрипт удалит управляемый блок GeoFree из hosts и обновит DNS-кэш Windows.


Резервные копии
---------------
Перед каждым изменением создаётся резервная копия:

C:\Windows\System32\drivers\etc\hosts.backup.YYYYMMDD_HHMMSS

Управляемые записи расположены между маркерами:

# --- GEOFREE START ---
# --- GEOFREE END ---
