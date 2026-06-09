-- =============================================================================
-- Migration: Adiciona TODAS as colunas que o App Mobile envia para 'rides'
-- e que ainda não existem no schema do Supabase.
--
-- Contexto: O app envia campos como receiver_name, proof_photo_url, etc.
-- durante a finalização da corrida, mas essas colunas não foram criadas
-- na tabela original. Isso causa PGRST204 (column not found in schema cache).
-- =============================================================================

-- Colunas de Timestamps (adicionadas anteriormente, IF NOT EXISTS garante idempotência)
ALTER TABLE rides ADD COLUMN IF NOT EXISTS updated_at      timestamptz NULL;
ALTER TABLE rides ADD COLUMN IF NOT EXISTS completed_at    timestamptz NULL;

-- Colunas de Comprovante de Entrega (Assinatura / Foto)
ALTER TABLE rides ADD COLUMN IF NOT EXISTS proof_photo_url text        NULL;
ALTER TABLE rides ADD COLUMN IF NOT EXISTS signature_url   text        NULL;

-- Colunas de Dados do Recebedor
ALTER TABLE rides ADD COLUMN IF NOT EXISTS receiver_name   text        NULL;
ALTER TABLE rides ADD COLUMN IF NOT EXISTS receiver_cpf    text        NULL;
ALTER TABLE rides ADD COLUMN IF NOT EXISTS receiver_vincule text       NULL;

-- Coluna de Falha / Motivo de Devolução
ALTER TABLE rides ADD COLUMN IF NOT EXISTS failure_reason  text        NULL;

-- Coluna de Rejeição (Array de UUIDs de motoristas que recusaram)
ALTER TABLE rides ADD COLUMN IF NOT EXISTS rejected_by     text[]      NULL;
