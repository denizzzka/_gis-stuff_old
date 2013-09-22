#### Программа для навигации и набор утилит для создания карт для неё

Under construction! / В процессе разработки!
* * *
Please support this project via GitTip:
https://www.gittip.com/denizzzka/
* * *
Use "--recursive" for cloning this repository:
```
git clone --recursive git://github.com/denizzzka/gis-stuff.git
```
For passing options to the compiler use ARGS variable:
```
make -B ARGS="-d -unittest -g -debug -debug=osmpbf"
```
("-B" is for unconditionally make target)
If no options are passed "-release" option will be used.

* * *
![Image](screenshots/malta_lines_3_colored.png)
![Image](screenshots/roads_render.png)
* * *

Roadmap:
--------------

- [x] Data Layers
    - [ ] Data support for: cars, trucks, pedestrians, planes, ships etc
    - [ ] Isohypses
    - [x] Pathfinding
        - [ ] Given the altitude (for mountains)

- [x] Dcene visualisation
    - [x] Software
        - [ ] Software 3D
    - [ ] OpenGL

- [ ] Text search for objects

- [x] Загрубление данных на разных режимах детализации (увеличения)

- [ ] Чтение "польского формата" ("Map Polish", ".mp")

- [ ] Конвертер карт
    - [ ] Упаковка данных с целью уменьшения размера файлов данных

- [ ] Поддержка ввода данных с датчика GPS (NMEA)
    - [ ] Глонасс
    - [ ] Бинарные протоколы
    - [ ] Другие датчики (компас, датчик ускорений, альтиметр)

- [ ] Загрузка с сервера карт текущего местоположения
    - [ ] Загрузка всех карт, через которые проходит заданный маршрут

- [ ] Портирование программы на какую-нибудь мобильную платформу
