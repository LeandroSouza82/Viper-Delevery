-- Migration: 07_make_bucket_public
-- Goal: Permitir acesso de leitura pública ao bucket driver_documents para fotos de perfil

UPDATE storage.buckets 
SET public = true 
WHERE id = 'driver_documents';

-- Garantir política de leitura pública para objetos no bucket
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE policyname = 'Public Access to documents' 
        AND tablename = 'objects' 
        AND schemaname = 'storage'
    ) THEN
        CREATE POLICY "Public Access to documents"
        ON storage.objects FOR SELECT
        USING ( bucket_id = 'driver_documents' );
    END IF;
END
$$;
