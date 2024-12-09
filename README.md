## "Extra mouse cursor" removal patches for Unreal Engine-based games

While playing some old (and recent) games while using a KVM device, it came to my attention that after switching to another PC and back an "extra" cursor often appears in-game. (It is really a standard OS mouse cursor which is normally hidden, and a custom in-game cursor is shown instead). It then remains on-screen until you restart the game, and is quite distracting. Sometimes you can also see the same effect after Alt-Tabbing or changing the monitor(s) configuration.
This family of patches mitigates the problem in a quick-and-dirty way (which is my favorite way). The patch for each game is implemented as a single DLL file (usually called "ddraw.dll"), which must be placed in the game directory (usually "System"). They do the following:
1) get loaded inside the game process;
2) find the main game loop code in memory;
3) patch it so that once every 60 game loop cycles the OS cursor status is checked, and the cursor is hidden if it is visible.

### Supported games:
Devastation
Pariah
Shadow Ops: Red Mercury
Tribes: Vengeance

When I find this bug in other games I play, I will (hopefully) add support for them too.
_Note:_ In case of Devastation, Pariah and Tribes: Vengeance, this patch is intended to be a part of larger patches, which will fix more bugs in the corresponding games.

### Technical details:
Each (early versions of) Unreal Engine-based game contains a main game loop, which calls an **FStats::Clear()** function at some point. This function is used only there, making it an excellent candidate for patching.
The patch DLL's DllMain function, called during loading of the game executable, finds the place where the call to FStats::Clear() function is located, and adds a call to a custom cursor fixing function to it. There, a counter is incremented, and if it reaches 60, it checks visibility status of the OS cursor with a call to GetCursorInfo function, and if it is visible, it hides it with a call to ShowCursor function. The counter is used so that cursor visibility checking function doesn't use much CPU time; calling it once per second (instead of once per frame) should be enough. Game executable memory is unprotected, modified and then re-protected again with the calls to VirtualProtect function.
Thus, the game executable isn't modified on-disk, only in-memory.
Classic method of hooking functions via proxy DLL isn't used here, because I'm too lazy.
The patch is written in Delphi, because it seemed to be the simplest option at the moment. No fancy OOP is used, but the code turned out to be quite extendable, while avoiding being complicated.
Also, it can easily be adapted to working with other games, because every game has a main event loop somewhere ;-)
All in all, it has been a good practice in system programming and code analysis.

## Todo list:
- [ ] Implement support for some non-UE based games:
	- [ ] Area-51?
	- [ ] RAGE?
- [ ] implement another patching methods, i.e. JMP injection instead of CALL redirection, IAT patching etc.
- [ ] maybe find other way of detecting the bug, maybe something like tracking a Direct3D device reinitialization or receiving a WM_ACTIVATE notification?

Games based on more recent idTech engine versions also exhibit this bug, but Alt-Tabbing from the game and back seems to fix it easily.

## Патчи для удаления "лишнего" курсора мыши в играх на основе Unreal Engine

Играя в старые (и не очень) игры и при этом используя KVM-переключатель, я заметил что после переключения на другой компьютер и обратно, в игре часто появляется второй, "лишний", курсор мыши. (На самом деле это стандартный курсор  ОС, обычно в игре он спрятан и показан другой, графический.) После этого два курсора остаются на экране и движутся по нему до момента выхода из игры. Это сильно отвлекает и мешает играть. Ещё такой эффект иногда возникает после переключения в другое приложение и обратно с помощью Alt-Tab, или при смене конфигурации монитора(-ов).
Данное семейство патчей устраняет эту проблему с помощью написанных "на коленке" "костылей" (как и в других моих проектах ))) )
Патч для каждой игры представляет собой один DLL-файл (обычно ddraw.dll), который нужно просто переписать в папку с исполняемым файлом игры (обычно System). Принцип действия патчей следующий:
1) при запуске игры DLL-файл загружается внутрь её процесса;
2) при получении управления патч ищет в памяти игры основной игровой цикл;
3) он модифицируется таким образом: каждые 60 циклов производится проверка на видимость курсора мыши ОС, и если он является видимым - он прячется.

### Поддерживаемые игры:
Devastation
Pariah
Shadow Ops: Red Mercury
Tribes: Vengeance

Если я найду этот баг в других играх, в которые буду играть, наверное буду добавлять их поддержку тоже, постепенно.
_Примечание:_ Для Devastation, Pariah и Tribes: Vengeance этот патч скороее всего будет включён в более крупные патчи, которые будут фиксить и многие другие баги в этих играх.

### Technical details:
В коде каждой игры, основанной на движке Unreal Engine (по крайней мере, старых версий), есть основной игровой цикл, в каждой итерации которого в определённый момент вызывается функция **FStats::Clear()**. Эта функция используется только в этом месте, поэтому её легко пропатчить, хукнуть или вообще заменить.
Главная функция DLL-файла (DllMain) вызывается при старте игры и загрузке библиотеки. Она просматривает память игры, производя поиск места вызова функции FStats::Clear() внутри главного игрового цикла, и добавляет туда вызов собственной специальной функции, которая увеличивает при каждом вызове специальный счётчик. Когда он достигает значения 60, он сбрасывается в 0, и происходит запрос состояния курсора мыши ОС (видимый/невидимый) с помощью функции GetCursorInfo. Если оказывается, что он видимый, он прячется с помощью вызова функции ShowCursor. Счётчик нужен, чтобы не сильно нагружать процессор: проверку состояния курсора вполне достаточно выполнять раз в секунду, а не в каждой итерации. С нужного места адресного пространства кода игры сначала снимается защита, затем производится модификация кода в памяти, затем защита восстанавливается повторным вызовом функции VirtualProtect.
Все модификации производятся в оперативной памяти, поэтому оригинальные файлы игры остаются нетронутыми (если это кому-нибудь вообще важно )).
Классические хуки через прокси-DLL не применяются, так как это слишком муторно.
Патч написан на Delphi, потому что это оказалось быстрее и проще всего. ООП и прочие фишечки не применяются, но при этом оставлен достаточный простор для некоторой кастомизации процесса патчинга (в разумных пределах).
Думается, что его можно легко адаптировать для игр на основе других движков, так как принцип везде одинаковый - в любой игре есть основной игровой цикл, в который можно влезть ;-)
В целом, задача дала неплохой повод попрактиковаться в системном программировании и анализе кода.

## Todo:
- [ ] добавить поддержку для игр на других движках:
	- [ ] Area-51?
	- [ ] RAGE?
- [ ] добавить поддержку других методов изменения кода, вроде вставки переходов JMP вместо перенаправления вызовов CALL, изменения IAT и др.
- [ ] возможно найти другие методы обнаружения появления "лишнего" курсора: возможно что-то типа детектирования реинициализации устройства Direct3D, или перехвата получения WM_ACTIVATE сообщений, или чего-то такого?

В играх на основе более свежих версий движка idTech баг тоже присутствует, но там обычно помогает переключиться куда-то с помощью Alt-Tab и обратно.
