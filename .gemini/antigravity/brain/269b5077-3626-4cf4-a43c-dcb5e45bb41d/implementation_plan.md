# Refatoração da Máquina de Estados de Rota (Ride State Machine)

O objetivo é substituir as múltiplas camadas de UI e cards desconexos (como o antigo `ViperOfferOverlay` e fases customizadas no Bottom Sheet) por um fluxo estrito, reativo e DRY, baseado em um único controlador e um único tipo de Card como requisitado.

## User Review Required

> [!WARNING]
> O card gigante que cobre a tela toda (`ViperOfferOverlay`) usado para aceitar corridas será completamente **DELETADO**. A ação de "Aceitar Rota" passará a residir no próprio painel inferior usando o novo `ServiceCardWidget`, integrando o fluxo perfeitamente sem pular etapas visuais. Isso garante a uniformidade desejada!

## Proposed Changes

### 1. Novo Controlador: `RideController` (GetX)
Será criado o `RideController` contendo uma variável reativa `Rx<RideState> rideState`, cobrindo precisamente os 4 estados:
- `RideState.awaitingAcceptance`: [ Aceitar Rota ] -> Transita para `goingToPickup`.
- `RideState.goingToPickup`: [ Ir ao local de coleta ] -> Chama o mapa e transita para `arrivedAtPickup`.
- `RideState.arrivedAtPickup`: [ Cheguei ao local ] -> Notifica Supabase e transita para `delivering`.
- `RideState.delivering`: [ Seguir rota de entrega ] -> Expande lista e traça rotas finais.

---

### 2. Deleção e Limpeza em `home_view.dart`

#### [DELETE] Referências de Cards Antigos
- Remover `ViperOfferOverlay` completamente. O overlay opaco que cobria o mapa e assustava os usuários com um design antigo vai sumir.
- O Bottom Sheet interceptará essas ofertas com o novo Card.

#### [MODIFY] [home_view.dart](file:///c:/src/viper_delivery/lib/src/modules/home/views/home_view.dart)
- Remover o bloco "O REI DA TELA: Overlay de Oferta".
- Substituir a injeção estática do bottom sheet por lógica dependente do `RideController`.

---

### 3. Padronização Única com `ServiceCardWidget`

#### [RENAME & MODIFY] [viper_order_card.dart](file:///c:/src/viper_delivery/lib/src/modules/home/widgets/viper_order_card.dart) → `service_card_widget.dart`
- Renomeado para `ServiceCardWidget` como definido no design system.
- O card vai aceitar um parâmetro do estado atual via `RideController.to.rideState.value` e alterar dinamicamente seu **botão e o texto da ação**, tornando a UI altamente DRY e reativa. As fases de Coleta e Oferta usarão uma versão do próprio card (usando a logo/ícone da loja e dados do Pickup), enquanto a fase de Entrega usará os dados do cliente final.
- Os botões "FINALIZE" e "FALHA" só aparecerão internamente no estado `delivering`. Os estados anteriores farão renderizar o grande botão de ação dinâmica (Aceitar/Ir/Chegar/Seguir).

#### [MODIFY] [viper_bottom_sheet_panel.dart](file:///c:/src/viper_delivery/lib/src/modules/home/widgets/viper_bottom_sheet_panel.dart)
- Limpeza dos métodos `_buildPickupPhase` redundantes (apaga o código antigo do widget customizado de Ponto de Coleta).
- Quando no estado 1 a 3, exibe apenas **1 `ServiceCardWidget`** representando o resumo de coleta.
- Ao entrar no `delivering` (Estado 4), renderiza a `ReorderableListView` contendo a lista completa de destinos, traçando o mapa.

## Open Questions

> [!NOTE] 
> O card `ServiceCardWidget` exibe o *Destino Único, Nome e Observação*. Durante as Etapas 1 a 3 (Aceitar/Indo à Coleta/No Local), devemos preencher esse card com o Endereço de Coleta (do restaurante/base) e o nome da base? Ou deseja que ele já exiba o Destino Final antecipadamente? (No meu plano, vou usar os dados de Coleta para preencher este card até o estado de Seguindo Rota).

## Verification Plan

### Manual Verification
1. Disparar o modo de teste pelo ícone no topo à esquerda do app.
2. Confirmar que a enorme tela preta desapareceu e a oferta caiu direto como "Aceitar Rota" no card inferior limpo.
3. Clicar sequencialmente e atestar que os estados não "pulam" mais uns por cima dos outros visualmente. O botão deve morfar progressivamente: Aceitar -> Ir -> Cheguei -> Seguir. Apenas depois do último clique, o mapa muda para a exibição de destinos múltiplos e os cards reordenáveis surgem.
