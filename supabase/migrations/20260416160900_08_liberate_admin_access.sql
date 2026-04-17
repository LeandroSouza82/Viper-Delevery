-- Migration: 08_liberate_admin_access
-- Goal: Garantir que o usuário lsouza557@gmail.com tenha acesso total (Aprovação + Burlar RLS)

-- 1. Forçar status de aprovado
UPDATE public.profiles
SET status = 'approved'
WHERE id IN (
    SELECT id FROM auth.users 
    WHERE email = 'lsouza557@gmail.com'
);

-- 2. Criar política de super-acesso (Admin) para este e-mail em profiles
-- (Permite deletar ou editar qualquer perfil para testes)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'Admin Full Access' 
        AND tablename = 'profiles'
    ) THEN
        CREATE POLICY "Admin Full Access"
        ON public.profiles FOR ALL
        USING ( (SELECT email FROM auth.users WHERE id = auth.uid()) = 'lsouza557@gmail.com' );
    END IF;
END
$$;
