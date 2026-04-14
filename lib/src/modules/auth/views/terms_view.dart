import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:viper_delivery/src/modules/auth/views/register_view.dart';

class TermsView extends StatefulWidget {
  const TermsView({super.key});

  @override
  State<TermsView> createState() => _TermsViewState();
}

class _TermsViewState extends State<TermsView> {
  bool _acceptedTerms = false;
  bool _acceptedLgpd = false;

  bool get _canProceed => _acceptedTerms && _acceptedLgpd;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Termos de Uso'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'TERMOS E CONDIÇÕES DE USO – PLATAFORMA VIPER DELIVERY',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            Text(
              '1. A NATUREZA DO SERVIÇO\n'
              'A Viper Delivery é uma plataforma de tecnologia que atua exclusivamente como intermediadora entre entregadores/motoristas autônomos e clientes finais. A plataforma NÃO É uma empresa de transportes, não possui frota própria e não é fornecedora de bens ou serviços de logística.\n\n'
              '2. AUSÊNCIA DE VÍNCULO TRABALHISTA (CLÁUSULA DE OURO)\n'
              'O uso do aplicativo não estabelece qualquer relação de emprego, subordinação, dependência ou vínculo trabalhista entre o Usuário Motorista e a Viper Delivery.\n\n'
              '• O motorista é um profissional autônomo e independente.\n'
              '• O motorista tem total liberdade para decidir seus horários, dias de trabalho e se aceita ou recusa qualquer solicitação.\n'
              '• O motorista é o único responsável pelos custos de manutenção do veículo, combustível, seguros e tributos.\n\n'
              '3. REQUISITOS PARA CADASTRO E SEGURANÇA\n'
              'Para utilizar a plataforma, o motorista deve obrigatoriamente fornecer e manter atualizados:\n\n'
              '• Documentação Real: CNH (com EAR), comprovante de residência e certidão de antecedentes criminais.\n'
              '• Vistoria Digital: O envio das 4 fotos do veículo (Frente, Traseira e Laterais) é obrigatório para comprovar o estado de conservação.\n'
              '• Veracidade: Qualquer divergência entre o veículo cadastrado e o utilizado resultará em banimento imediato.\n\n'
              '4. PRIVACIDADE E LGPD (LEI GERAL DE PROTEÇÃO DE DADOS)\n'
              'Ao aceitar estes termos, você autoriza a Viper Delivery a coletar, armazenar e processar seus dados pessoais e de localização para:\n\n'
              '• Verificação de identidade e segurança.\n'
              '• Repasse de entregas próximas à sua localização em tempo real (mesmo com o app em segundo plano).\n'
              '• Compartilhamento de dados necessários com o cliente final para a conclusão da entrega.\n\n'
              'Seus dados serão armazenados de forma segura e não serão vendidos a terceiros.\n\n'
              '5. PAGAMENTOS E FINANCEIRO\n\n'
              '• Chave Pix: Os repasses serão realizados exclusivamente para a Chave Pix informada no cadastro. É responsabilidade do motorista garantir que a chave esteja correta.\n'
              '• Taxas: A plataforma cobrará uma taxa de intermediação por cada serviço concluído, cujo valor será informado de forma transparente antes do aceite da corrida.\n\n'
              '6. CONDUTA E BANIMENTO\n'
              'São motivos para suspensão ou exclusão definitiva da plataforma, sem aviso prévio:\n\n'
              '• Fraudes no sistema de GPS ou uso de simuladores.\n'
              '• Comportamento inadequado ou agressivo com clientes.\n'
              '• Transporte de substâncias ilícitas.\n'
              '• Taxa de cancelamento excessiva após o aceite.\n\n'
              '7. FORO E LEGISLAÇÃO\n'
              'Para dirimir quaisquer controvérsias oriundas deste Termo, as partes elegem o Foro da Comarca de Palhoça/SC, com renúncia expressa a qualquer outro, por mais privilegiado que seja.',
              style: TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (val) => setState(() => _acceptedTerms = val ?? false),
                title: const Text(
                  'Li e aceito os Termos de Uso',
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                value: _acceptedLgpd,
                onChanged: (val) => setState(() => _acceptedLgpd = val ?? false),
                title: const Text(
                  'Concordo com o processamento de dados conforme a LGPD',
                  style: TextStyle(fontSize: 14),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterView()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    'Continuar para Cadastro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
