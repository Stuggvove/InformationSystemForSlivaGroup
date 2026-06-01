
#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)		
	
	Если РольДоступна("РуководительПроектов") Тогда 
		
		ОтборОтдел = ПараметрыСеанса.ТекущийСотрудник.Отдел;
		
	Иначе 
		
		ОтборПоСотрудникам = ПараметрыСеанса.ТекущийСотрудник;
		ОтборОтдел		   = ПараметрыСеанса.ТекущийСотрудник.Отдел;
		
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	ОбновитьДоску();
	ПодключитьОбработчикОжидания("ОбновитьДоскуНаКлиенте", 0.00001,  Истина);
	ПодключитьОбработчикОжидания("ПроверитьКоманду", 1);
	
КонецПроцедуры

&НаКлиенте
Процедура ПриПовторномОткрытии()
	ПодключитьОбработчикОжидания("ОбновитьДоскуНаКлиенте", 1, Ложь);
КонецПроцедуры 

&НаКлиенте
Процедура ОтборПоСотрудникамПриИзменении(Элемент)
	ОбновитьДоску();
КонецПроцедуры

&НаКлиенте
Процедура ОтборОтделПриИзменении(Элемент)
	ОбновитьДоску();
КонецПроцедуры

#КонецОбласти

#Область КомандыФормы

&НаКлиенте
Процедура ОбновитьДоску(Команда = Неопределено)
	
	HTMLДокумент = ПолучитьHTMLДляКлиента();
	Элементы.КанбанHTML.Документ.open();
	Элементы.КанбанHTML.Документ.write(HTMLДокумент);
	Элементы.КанбанHTML.Документ.close();
	
КонецПроцедуры

#КонецОбласти

#Область РаботаСДанными

&НаСервере
Функция ПолучитьHTMLДляКлиента()
	
	ДанныеJSON = ПолучитьДанныеЗадачJSON();
	Возврат ПолучитьHTMLДоски(ДанныеJSON);
	
КонецФункции

&НаСервере
Функция ПолучитьДанныеЗадачJSON()
	
	Запрос = Новый Запрос;
	
	Запрос.Текст =
	"ВЫБРАТЬ
	|    Задачи.Ссылка                  КАК Ссылка,
	|    Задачи.Наименование            КАК Наименование,
	|    Задачи.СостояниеЗадачи         КАК Состояние,
	|    Задачи.Исполнитель             КАК Исполнитель,
	|    ВЫРАЗИТЬ(Задачи.СрокИсполнения КАК ДАТА) КАК Срок
	|ИЗ
	|    Задача.Задача КАК Задачи
	|ГДЕ
	|    Задачи.Выполнена = ЛОЖЬ
	|    И (&СотрудникЗаполнен = ЛОЖЬ ИЛИ Задачи.Исполнитель = &Сотрудник)
	|    И (&ОтделЗаполнен = ЛОЖЬ ИЛИ Задачи.Исполнитель.Отдел = &Отдел)
	|УПОРЯДОЧИТЬ ПО
	|    Задачи.Наименование";
	
	Запрос.УстановитьПараметр("Сотрудник",         ОтборПоСотрудникам);
	Запрос.УстановитьПараметр("СотрудникЗаполнен", ЗначениеЗаполнено(ОтборПоСотрудникам));
	Запрос.УстановитьПараметр("Отдел",             ОтборОтдел);
	Запрос.УстановитьПараметр("ОтделЗаполнен",     ЗначениеЗаполнено(ОтборОтдел));
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	МассивЗадач = Новый Массив;
	
	Пока Выборка.Следующий() Цикл
		
		Задача = Новый Структура;
		Задача.Вставить("id",         Строка(Выборка.Ссылка.УникальныйИдентификатор()));
		Задача.Вставить("name",       Выборка.Наименование);
		Задача.Вставить("status",     Строка(Выборка.Состояние));
		Задача.Вставить("assignee",   Строка(Выборка.Исполнитель));
		Задача.Вставить("deadline",   ?(ЗначениеЗаполнено(Выборка.Срок), Формат(Выборка.Срок, "ДФ=дд.ММ.гггг"), ""));
		
		МассивЗадач.Добавить(Задача);
		
	КонецЦикла;
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, МассивЗадач);
	
	Возврат ЗаписьJSON.Закрыть();
	
КонецФункции

// Вызывается из JavaScript при перетаскивании карточки
&НаКлиенте
Процедура СохранитьСостояние(ИдЗадачи, НовоеСостояние) Экспорт
	СохранитьСостояниеНаСервере(ИдЗадачи, НовоеСостояние);
КонецПроцедуры

&НаСервере
Процедура СохранитьСостояниеНаСервере(ИдЗадачи, НовоеСостояние)
	
	ГУИД = Новый УникальныйИдентификатор(ИдЗадачи);
	СсылкаНаЗадачу = Задачи.Задача.ПолучитьСсылку(ГУИД);
	
	Если СсылкаНаЗадачу = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	ОбъектЗадача = СсылкаНаЗадачу.ПолучитьОбъект();
	ТипСостояния = ТипЗнч(ОбъектЗадача.СостояниеЗадачи);
	
	Если НовоеСостояние = "todo" Тогда
		ОбъектЗадача.СостояниеЗадачи = XMLЗначение(ТипСостояния, "КВыполнению");
	ИначеЕсли НовоеСостояние = "wip" Тогда
		ОбъектЗадача.СостояниеЗадачи = XMLЗначение(ТипСостояния, "ВРаботе");
	ИначеЕсли НовоеСостояние = "review" Тогда
		ОбъектЗадача.СостояниеЗадачи = XMLЗначение(ТипСостояния, "НаПроверке");
	ИначеЕсли НовоеСостояние = "done" Тогда
		ОбъектЗадача.СостояниеЗадачи = XMLЗначение(ТипСостояния, "Готово");
	КонецЕсли;    
	ОбъектЗадача.Записать();
	
КонецПроцедуры

// Открытие задачи по клику — вызывается из JS
&НаКлиенте
Процедура ОткрытьЗадачу(ИдЗадачи) Экспорт
	
	ГУИД = Новый УникальныйИдентификатор(ИдЗадачи);
	СсылкаНаЗадачу = ОткрытьЗадачуНаСервере(ГУИД);
	
	Если Не СсылкаНаЗадачу.Пустая() Тогда		
		ОткрытьФорму("Задача.Задача.ФормаОбъекта", Новый Структура("Ключ", СсылкаНаЗадачу), ЭтаФорма);		
	КонецЕсли;
	
КонецПроцедуры

&НаСервере
Функция ОткрытьЗадачуНаСервере(ГУИД)
	Возврат Задачи.Задача.ПолучитьСсылку(Новый УникальныйИдентификатор(ГУИД));
КонецФункции

&НаКлиенте
Процедура ПроверитьКоманду()
	
	Заголовок = Элементы.КанбанHTML.Документ.title;
	
	Если СтрНачинаетсяС(Заголовок, "kanban|") Тогда
		Части = СтрРазделить(Заголовок, "|");
		Элементы.КанбанHTML.Документ.title = ""; // сбрасываем сразу
		
		Если Части[1] = "open" Тогда
			ОткрытьЗадачу(Части[2]);
		Иначе
			// drag & drop — старая логика
			СохранитьСостояниеНаСервере(Части[1], Части[2]);
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ОбновитьДоскуНаКлиенте()	
	ОбновитьДоску();	
КонецПроцедуры

#КонецОбласти

#Область ГенерацияHTML

&НаСервере
Функция ПолучитьHTMLДоски(ДанныеJSON)
	
	HTMLДоска = "<!DOCTYPE html>
	|<html>
	|<head>
	|<meta charset=""UTF-8"">
	|<script src=""https://cdn.jsdelivr.net/npm/sortablejs@1.15.0/Sortable.min.js""></script>
	|<style>
	|  * { box-sizing: border-box; margin: 0; padding: 0; font-family: Arial, sans-serif; }
	|  body { background: #f0f2f5; padding: 12px; height: 100vh; overflow: hidden; }
	|  .board { display: flex; gap: 12px; height: 100%; }
	|  .column {
	|    flex: 1; background: #ebecf0; border-radius: 8px;
	|    padding: 10px; display: flex; flex-direction: column; min-width: 0;
	|  }
	|  .column-header {
	|    font-size: 13px; font-weight: 600; color: #44546f;
	|    margin-bottom: 10px; padding: 4px 6px;
	|    display: flex; justify-content: space-between; align-items: center;
	|  }
	|  .column-header .count {
	|    background: #c1c7d0; color: #44546f;
	|    border-radius: 10px; font-size: 11px;
	|    padding: 1px 7px; font-weight: 500;
	|  }
	|  .cards-list {
	|    flex: 1; overflow-y: auto; display: flex;
	|    flex-direction: column; gap: 8px; min-height: 40px;
	|  }
	|  .card {
	|    background: #fff; border-radius: 6px; padding: 10px 12px;
	|    box-shadow: 0 1px 2px rgba(0,0,0,.12);
	|    cursor: grab; font-size: 13px; color: #172b4d;
	|    transition: box-shadow .15s;
	|  }
	|  .card:hover { box-shadow: 0 3px 8px rgba(0,0,0,.18); }
	|  .card:active { cursor: grabbing; }
	|  .card-title { font-weight: 500; margin-bottom: 4px; line-height: 1.4; }
	|  .card-title:hover { color: #0052cc; cursor: pointer; text-decoration: underline; }
	|  .card-meta { font-size: 11px; color: #6b778c; }
	|  .card-meta span { margin-right: 8px; }
	|  .sortable-ghost { opacity: 0.35; }
	|  .sortable-drag  { box-shadow: 0 8px 24px rgba(0,0,0,.22) !important; }
	|  /* Цвета заголовков колонок */
	|  .col-todo    .column-header { border-bottom: 3px solid #6b778c; }
	|  .col-wip     .column-header { border-bottom: 3px solid #0052cc; }
	|  .col-review  .column-header { border-bottom: 3px solid #ff991f; }
	|  .col-done    .column-header { border-bottom: 3px solid #00875a; }
	|</style>
	|</head>
	|<body>
	|<div class=""board"">
	|  <div class=""column col-todo"">
	|    <div class=""column-header"">К выполнению <span class=""count"" id=""cnt-todo"">0</span></div>
	|    <div class=""cards-list"" id=""col-todo"" data-status=""К выполнению""></div>
	|  </div>
	|  <div class=""column col-wip"">
	|    <div class=""column-header"">В работе <span class=""count"" id=""cnt-wip"">0</span></div>
	|    <div class=""cards-list"" id=""col-wip"" data-status=""В работе""></div>
	|  </div>
	|  <div class=""column col-review"">
	|    <div class=""column-header"">На проверке <span class=""count"" id=""cnt-review"">0</span></div>
	|    <div class=""cards-list"" id=""col-review"" data-status=""На проверке""></div>
	|  </div>
	|  <div class=""column col-done"">
	|    <div class=""column-header"">Готово <span class=""count"" id=""cnt-done"">0</span></div>
	|    <div class=""cards-list"" id=""col-done"" data-status=""Готово""></div>
	|  </div>
	|</div>
	|
	|<script>
	|// ---- Данные из 1С ----
	|var tasks = " + ДанныеJSON + ";
	|
	|// Маппинг значений перечисления 1С → id колонки
	|// ВАЖНО: строки должны совпадать со строковым представлением вашего перечисления
	|var statusMap = {
	|  'К выполнению' : 'col-todo',
	|  'ВыполнениеЗапланировано' : 'col-todo', // системное значение
	|  'В работе'    : 'col-wip',
	|  'ВРаботе'     : 'col-wip',
	|  'На проверке' : 'col-review',
	|  'НаПроверке'  : 'col-review',
	|  'Готово'      : 'col-done',
	|  'Выполнено'   : 'col-done'
	|};
	|
	|// Счётчики карточек
	|var counts = {'col-todo':0,'col-wip':0,'col-review':0,'col-done':0};
	|
	|// Отрисовка карточек
	|tasks.forEach(function(t) {
	|  var colId = statusMap[t.status] || 'col-todo';
	|  var col = document.getElementById(colId);
	|  if (!col) return;
	|  
	|  var meta = '';
	|  if (t.assignee) meta += '<span> ' + t.assignee + '</span>';
	|  if (t.deadline) meta += '<span> ' + t.deadline + '</span>';
	|  
	|  var card = document.createElement('div');
	|  card.className = 'card';
	|  card.dataset.id = t.id;
	|  card.innerHTML =
	|    '<div class=""card-title"" onclick=""openTask(\''+t.id+'\')"">'+t.name+'</div>' +
	|    (meta ? '<div class=""card-meta"">'+meta+'</div>' : '');
	|  col.appendChild(card);
	|  counts[colId]++;
	|});
	|
	|// Обновить счётчики
	|document.getElementById('cnt-todo').textContent   = counts['col-todo'];
	|document.getElementById('cnt-wip').textContent    = counts['col-wip'];
	|document.getElementById('cnt-review').textContent = counts['col-review'];
	|document.getElementById('cnt-done').textContent   = counts['col-done'];
	|
	|// Drag & drop через Sortable.js
	|['col-todo','col-wip','col-review','col-done'].forEach(function(colId) {
	|  Sortable.create(document.getElementById(colId), {
	|    group: 'kanban',          // все колонки в одной группе — карточки перетаскиваются между ними
	|    animation: 150,
	|    ghostClass: 'sortable-ghost',
	|    dragClass: 'sortable-drag',
	|    onEnd: function(evt) {
	|	 var taskId = evt.item.dataset.id;
	|    var newStatus = evt.to.dataset.status;
	|    var statusCode = {
	|    	'К выполнению': 'todo',
	|    	'В работе': 'wip',
	|    	'На проверке': 'review',
	|    	'Готово': 'done'
	|    };
	|
	|	   document.title = 'kanban|' + taskId + '|' + statusCode[newStatus];	
	|      
	|      // Обновить счётчики
	|      updateCounts();
	|    }
	|  });
	|});
	|
	|function updateCounts() {
	|  var map = {'col-todo':'cnt-todo','col-wip':'cnt-wip','col-review':'cnt-review','col-done':'cnt-done'};
	|  Object.keys(map).forEach(function(colId) {
	|    document.getElementById(map[colId]).textContent =
	|      document.getElementById(colId).children.length;
	|  });
	|}
	|
	|function openTask(id) {
	|  //try { window.external.ОткрытьЗадачу(id); } catch(e) {}
	|  document.title = 'kanban|open|' + id;
	|}
	|</script>
	|</body>
	|</html>";
	
	Возврат HTMLДоска;
	
КонецФункции

#КонецОбласти