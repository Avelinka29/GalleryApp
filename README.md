# GalleryApp

Учебное приложение на Swift и UIKit, iOS 17+. Сейчас выполнена подготовка проекта (этап 1).

## Запуск

1. Откройте `GalleryApp.xcodeproj` в Xcode с установленным iOS Simulator.
2. Выберите схему `GalleryApp` и симулятор iPhone.
3. Нажмите **⌘R**. Сейчас ожидается пустой экран с заголовком «Галерея».

Существующие AppDelegate, SceneDelegate и Main.storyboard сохранены.
Storyboard создаёт начальный интерфейс; переход к интерфейсу кодом запланирован на этап 2.

## Проверка стиля

Установите [SwiftLint](https://github.com/realm/SwiftLint#installation):

```sh
brew install swiftlint
```

Из корня репозитория выполните:

```sh
sh Scripts/lint.sh
```

SwiftLint проверяет приложение и оба тестовых target. Команда завершается ошибкой
при новых замечаниях. Проверка запускается отдельно от сборки Xcode.
Проверено со SwiftLint 0.65.1. Если утилита не находит SourceKit из-за выбора другой
версии Xcode, укажите путь явно: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer sh Scripts/lint.sh`.
`.swiftlint-baseline.json` фиксирует только замечания исходного шаблона, чтобы
сохранить существующий код. Не обновляйте baseline для сокрытия новых нарушений;
по мере замены шаблонных файлов старые замечания следует устранить.

## API-ключ

На этапе 1 ключ не нужен: сетевых запросов ещё нет. Безопасное подключение Unsplash
будет добавлено на этапе 3. `.env`, `Secrets.xcconfig` и `Secrets.plist`
исключены из Git. Не вставляйте реальные ключи в Swift-файлы, README или настройки проекта.

## План

Следующий этап — локальная UICollectionView-галерея с Auto Layout и разделением View/ViewModel.
Далее: Unsplash, навигация через Coordinator, избранное на Core Data, тесты и скриншоты.
Итоговая архитектура — MVVM + Coordinator; сейчас сохранена исходная UIKit-основа.

Каждый этап выполняется в отдельной feature-ветке с PR в main. Следующая ветка
создаётся от обновлённого main после объединения предыдущего PR пользователем.
