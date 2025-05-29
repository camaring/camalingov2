import 'dart:math';

/// Service providing financial saving tips.
///
/// This class manages a collection of predefined saving tips and
/// exposes a method to retrieve one at random.
class TipsService {
  /// Predefined list of saving tips in Spanish.
  /// 
  /// Each entry is a suggestion to help users manage and reduce expenses.
  static final List<String> _savingTips = [
    'Aplica la regla 50/30/20: 50% para necesidades, 30% para deseos y 20% para ahorro',
    'Cocina en casa en lugar de comer fuera',
    'Usa transporte público o comparte coche siempre que puedas',
    'Cancela suscripciones que no utilices',
    'Programa transferencias automáticas a tu cuenta de ahorro',
    'Compara precios antes de compras grandes',
    'Usa tarjetas con devolución de efectivo de forma responsable',
    'Lleva un registro detallado de todos tus gastos',
    'Planifica tu lista de compras para evitar desperdicios',
    'Espera 24 horas antes de compras no esenciales para evitar impulsos',
    'Elige electrodomésticos y bombillas de bajo consumo',
    'Compra marcas genéricas cuando la calidad lo permita',
    'Utiliza una botella de agua reutilizable',
    'Aprovecha ofertas y cupones de descuento',
    'Inicia un pequeño proyecto o ingreso extra',
    'Revisa y negocia tus tarifas de servicios como internet o móvil',
    'Compra al por mayor los productos no perecederos',
    'Utiliza aplicaciones y cupones para ahorrar en cada compra',
    'Evita cargos por sobregiro manteniendo un mínimo en tu cuenta',
    'Establece un presupuesto semanal y síguelo al pie de la letra',
    'Guarda el cambio diario en un frasco para ahorro a final de mes',
    'Cultiva tus propias hierbas o vegetales si tienes espacio',
    'Seca la ropa al aire libre en lugar de usar secadora',
    'Lleva tu propio termo de café en lugar de comprar en cafeterías',
    'Revisa tu póliza de seguros cada año para ajustar coberturas',
    'Evita las compras impulsivas desconectando las notificaciones de tiendas',
    'Ahorra al comprar productos de temporada y locales',
    'Utiliza la regla de un mes: si puedes esperar un mes sin usar algo, no lo compres',
    'Participa en grupos de intercambio o trueque de artículos',
  ];

  /// Returns a random saving tip from the predefined list.
  ///
  /// Uses Dart's [Random] class to pick an index within the list bounds.
  static String getRandomTip() {
    // Instantiate the random number generator.
    final random = Random();
    // Generate a random index based on the list length.
    final index = random.nextInt(_savingTips.length);
    // Return the tip corresponding to the random index.
    return _savingTips[index];
  }
}
