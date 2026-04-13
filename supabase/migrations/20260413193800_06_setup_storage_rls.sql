-- Migration: 06_setup_storage_rls
-- Configures Row Level Security for the storage.objects table to allow authenticated users
-- to manage their documents in the driver_documents bucket.

-- Allow upload
CREATE POLICY "Permitir upload para usuários autenticados" 
ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'driver_documents');

-- Allow selection
CREATE POLICY "Permitir leitura de documentos" 
ON storage.objects FOR SELECT TO authenticated USING (bucket_id = 'driver_documents');

-- Allow update
CREATE POLICY "Permitir atualizacao de documentos" 
ON storage.objects FOR UPDATE TO authenticated USING (bucket_id = 'driver_documents');

-- Allow deletion
CREATE POLICY "Permitir exclusao de documentos" 
ON storage.objects FOR DELETE TO authenticated USING (bucket_id = 'driver_documents');
