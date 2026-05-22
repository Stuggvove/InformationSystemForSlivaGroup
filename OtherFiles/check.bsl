&НаСервере
Процедура ЗарегистрироватьWebhookНаСервере()
	
	// "https://webhook:@xxxx.trycloudflare.com/SGIS/hs/telegram/"
	Результат = МодульTelegram.SetWebhook("https://webhook:@midwest-warrant-request-charges.trycloudflare.com/SGIS/hs/telegram/");
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, Результат);
	Сообщить(ЗаписьJSON.Закрыть());
	
КонецПроцедуры

&НаКлиенте
Процедура ЗарегистрироватьWebhook(Команда)
	ЗарегистрироватьWebhookНаСервере();
КонецПроцедуры

&НаСервере
Процедура ПроверитьWebhookНаСервере()
	
	Результат = МодульTelegram.GetWebhookInfo();
	
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, Результат);
	Сообщить(ЗаписьJSON.Закрыть());
	
КонецПроцедуры

&НаКлиенте
Процедура ПроверитьWebhook(Команда)
	ПроверитьWebhookНаСервере();
КонецПроцедуры