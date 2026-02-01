// Условный экспорт миксина для экспорта результатов калькуляторов
// На нативных платформах - полная версия с Isar
// На вебе - упрощённая версия без Isar

export 'exportable_consumer_mixin_native.dart'
    if (dart.library.html) 'exportable_consumer_mixin_web.dart';
