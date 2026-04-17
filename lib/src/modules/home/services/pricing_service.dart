import 'package:viper_delivery/src/modules/home/models/viper_order.dart';

class ViperPricingService {
  static const double bonusPerSuccess = 2.50;
  static const double feePerFailure = 1.50;

  static ViperExecutionSummary calculateExecutionSummary({
    required ViperOffer offer,
    required List<ViperOrder> processedOrders,
    required bool isClt,
  }) {
    if (isClt) {
      return ViperExecutionSummary(
        baseValue: 0.0,
        successBonus: 0.0,
        attemptFee: 0.0,
        totalValue: 0.0,
        countSuccess: 0,
        countFailed: 0,
      );
    }

    final int countSuccess = processedOrders.where((o) => o.status == ViperOrderStatus.completed).length;
    final int countFailed = processedOrders.where((o) => o.status == ViperOrderStatus.returned).length;

    // NOVO CÁLCULO: Franquia de KM (ViperMath v2)
    const double taxaBase = 6.50; // Mínimo garantido
    const double kmFranquia = 6.0;
    
    final double totalKm = offer.distanciaTotal;
    final double kmExcedente = totalKm > kmFranquia ? totalKm - kmFranquia : 0.0;
    final double valorPorKm = offer.isSuper ? 0.95 : 1.32;

    final double baseValue = taxaBase + (kmExcedente * valorPorKm);
    
    final double successBonus = countSuccess * bonusPerSuccess;
    final double attemptFee = countFailed * feePerFailure;
    final double totalValue = baseValue + successBonus + attemptFee;

    return ViperExecutionSummary(
      baseValue: baseValue,
      successBonus: successBonus,
      attemptFee: attemptFee,
      totalValue: totalValue,
      countSuccess: countSuccess,
      countFailed: countFailed,
      paymentStatus: offer.paymentStatus,
    );
  }
}
