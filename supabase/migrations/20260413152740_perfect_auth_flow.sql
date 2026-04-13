-- Função para criar o perfil automaticamente ao cadastrar
-- O SECURITY DEFINER permite que a função execute com privilégios de superusuário,
-- ignorando políticas de RLS durante a criação inicial do perfil.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, first_name, last_name, cpf, phone, email, city, neighborhood, state, status)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'first_name',
    new.raw_user_meta_data->>'last_name',
    new.raw_user_meta_data->>'cpf',
    new.raw_user_meta_data->>'phone',
    new.email,
    new.raw_user_meta_data->>'city',
    new.raw_user_meta_data->>'neighborhood',
    new.raw_user_meta_data->>'state',
    'pending_vehicle'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para executar a função após o insert em auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Ajuste de RLS para garantir que a inserção automática via Trigger funcione 
-- e que usuários autenticados (mesmo não confirmados) possam ler seus dados básicos.
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Garantir que a política de leitura seja robusta para sessões ativas
DROP POLICY IF EXISTS "Permitir leitura do próprio perfil" ON public.profiles;
CREATE POLICY "Permitir leitura do próprio perfil" 
ON public.profiles FOR SELECT 
USING (auth.uid() = id);

-- Garantir que a política de atualização seja robusta
DROP POLICY IF EXISTS "Permitir atualização do próprio perfil" ON public.profiles;
CREATE POLICY "Permitir atualização do próprio perfil" 
ON public.profiles FOR UPDATE 
USING (auth.uid() = id);

-- NOTA: A política de INSERT agora pode ser restrita ou desativada para o cliente,
-- pois o Trigger (SECURITY DEFINER) cuida da criação do perfil com segurança total.
DROP POLICY IF EXISTS "Permitir inserção do próprio perfil" ON public.profiles;
