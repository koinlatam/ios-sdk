//
//  KoinExceptionCatcher.h
//  KoinFingerprint
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Ponte mínima para capturar `NSException` do Objective-C a partir do Swift.
///
/// O `do/catch` do Swift só intercepta erros que conformam a `Error`. Uma
/// `NSException` lançada por um framework do sistema (ex.: CoreNFC, via proxy XPC
/// do `nfcd`) atravessa o `catch` do Swift e derruba o processo — inaceitável num
/// SDK embarcado, que não pode derrubar o app host. Este utilitário é a rede de
/// segurança que contém essas exceções.
///
/// Uso interno do SDK. Exposto no umbrella header apenas por exigência da ponte
/// Objective-C → Swift dentro de um framework.
@interface KoinExceptionCatcher : NSObject

/// Executa `block`; se ele lançar uma `NSException`, captura-a e a devolve, caso
/// contrário devolve `nil`. Não intercepta traps do Swift (fatalError, force-unwrap
/// de `nil`, índice fora de faixa), que não são `NSException` e permanecem fatais.
+ (nullable NSException *)catchException:(NS_NOESCAPE void (^)(void))block
    NS_SWIFT_NAME(catchException(_:));

@end

NS_ASSUME_NONNULL_END
