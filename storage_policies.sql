-- EXECUTAR NO SQL EDITOR DO SUPABASE (PROJETO: VIPER DELIVERY)
-- OBJETIVO: Liberar o bucket DRIVER_DOCUMENTS para uploads de motoristas autenticados.

-- 1. Permite INSERT para usuários autenticados em sua própria pasta (drivers/{uid}/...)
CREATE POLICY "Allow authenticated insert" 
ON storage.objects FOR INSERT 
TO authenticated 
WITH CHECK (
    bucket_id = 'DRIVER_DOCUMENTS' 
    AND (storage.foldername(name))[1] = 'drivers' 
    AND (storage.foldername(name))[2] = auth.uid()::text
);

-- 2. Permite UPDATE para sobrescrever a própria foto (upsert)
CREATE POLICY "Allow authenticated update" 
ON storage.objects FOR UPDATE 
TO authenticated 
USING (
    bucket_id = 'DRIVER_DOCUMENTS' 
    AND (storage.foldername(name))[1] = 'drivers' 
    AND (storage.foldername(name))[2] = auth.uid()::text
);

-- 3. Permite leitura pública/autenticada para exibir no App
CREATE POLICY "Allow authenticated select" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'DRIVER_DOCUMENTS');
