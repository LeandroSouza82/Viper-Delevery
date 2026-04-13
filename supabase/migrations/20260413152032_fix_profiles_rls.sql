-- Habilita RLS e permite que usuários autenticados insiram seus próprios dados
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Remover políticas antigas se existirem (para garantir limpeza)
DROP POLICY IF EXISTS "Usuários podem inserir seu próprio perfil" ON public.profiles;
DROP POLICY IF EXISTS "Usuários podem ver seu próprio perfil" ON public.profiles;
DROP POLICY IF EXISTS "Usuários podem atualizar seu próprio perfil" ON public.profiles;

-- Criar novas políticas conforme solicitado
CREATE POLICY "Permitir inserção do próprio perfil" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Permitir leitura do próprio perfil" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Permitir atualização do próprio perfil" ON public.profiles FOR UPDATE USING (auth.uid() = id);
