drop extension if exists "pg_net";


  create table "public"."anexos" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "parent_type" text not null,
    "parent_id" uuid not null,
    "tipo" text not null,
    "storage_path" text not null,
    "nota" text,
    "criado_em" timestamp with time zone not null default now()
      );


alter table "public"."anexos" enable row level security;


  create table "public"."clientes" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "nome" text not null,
    "telefone" text,
    "endereco" text,
    "data_cadastro" timestamp with time zone not null default now(),
    "observacoes" text,
    "tipo" text not null default 'particular'::text,
    "nome_seguradora" text,
    "cnpj" text,
    "contato" text,
    "ativo" boolean not null default true,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."clientes" enable row level security;


  create table "public"."convites" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "codigo" text not null,
    "criado_em" timestamp with time zone not null default now(),
    "expira_em" timestamp with time zone not null,
    "usado_em" timestamp with time zone,
    "usado_por" uuid
      );


alter table "public"."convites" enable row level security;


  create table "public"."empresa" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "nome" text,
    "telefone" text,
    "endereco" text,
    "cnpj" text,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."empresa" enable row level security;


  create table "public"."fipe_marcas_cache" (
    "codigo" text not null,
    "nome" text not null,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."fipe_marcas_cache" enable row level security;


  create table "public"."fipe_modelos_cache" (
    "id" text not null,
    "marca_codigo" text not null,
    "codigo" text not null,
    "nome" text not null,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."fipe_modelos_cache" enable row level security;


  create table "public"."marcas_modelos_custom" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "marca" text not null,
    "modelo" text,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."marcas_modelos_custom" enable row level security;


  create table "public"."notas" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "orcamento_id" uuid,
    "cliente_id" uuid,
    "cliente_nome" text,
    "veiculo_id" uuid,
    "veiculo_descricao" text,
    "itens" jsonb not null default '[]'::jsonb,
    "valor_total" numeric(12,2) not null default 0,
    "data_emissao" timestamp with time zone not null default now(),
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."notas" enable row level security;


  create table "public"."oficinas" (
    "id" uuid not null default gen_random_uuid(),
    "nome" text not null,
    "criado_em" timestamp with time zone not null default now()
      );


alter table "public"."oficinas" enable row level security;


  create table "public"."orcamentos" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "cliente_id" uuid,
    "cliente_nome" text,
    "veiculo_id" uuid,
    "veiculo_descricao" text,
    "itens" jsonb not null default '[]'::jsonb,
    "valor_total" numeric(12,2) not null default 0,
    "status" text not null default 'pendente'::text,
    "data_criacao" timestamp with time zone not null default now(),
    "data_aprovacao" timestamp with time zone,
    "data_conclusao" timestamp with time zone,
    "data_pagamento" timestamp with time zone,
    "pago" boolean not null default false,
    "observacoes" text,
    "observacoes_cliente" text,
    "observacoes_internas" text,
    "data_prevista_entrega" timestamp with time zone,
    "tipo_atendimento" text,
    "motivo_cancelamento" text,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."orcamentos" enable row level security;


  create table "public"."pecas_custom" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "peca" text not null,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."pecas_custom" enable row level security;


  create table "public"."perfis" (
    "id" uuid not null,
    "oficina_id" uuid not null,
    "nome" text not null,
    "criado_em" timestamp with time zone not null default now(),
    "role" text not null default 'admin'::text
      );


alter table "public"."perfis" enable row level security;


  create table "public"."servicos_custom" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "servico" text not null,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."servicos_custom" enable row level security;


  create table "public"."transacoes" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "tipo" text not null,
    "descricao" text,
    "valor" numeric(12,2) not null,
    "categoria" text,
    "data" timestamp with time zone not null default now(),
    "orcamento_id" uuid,
    "observacoes" text,
    "atualizado_em" timestamp with time zone not null default now(),
    "valor_original" numeric,
    "editado_em" timestamp with time zone
      );


alter table "public"."transacoes" enable row level security;


  create table "public"."veiculos" (
    "id" uuid not null default gen_random_uuid(),
    "oficina_id" uuid not null,
    "cliente_id" uuid,
    "marca" text,
    "modelo" text,
    "cor" text,
    "placa" text,
    "ano" integer,
    "observacoes" text,
    "ativo" boolean not null default true,
    "atualizado_em" timestamp with time zone not null default now()
      );


alter table "public"."veiculos" enable row level security;

CREATE UNIQUE INDEX anexos_pkey ON public.anexos USING btree (id);

CREATE UNIQUE INDEX clientes_pkey ON public.clientes USING btree (id);

CREATE UNIQUE INDEX convites_codigo_key ON public.convites USING btree (codigo);

CREATE UNIQUE INDEX convites_pkey ON public.convites USING btree (id);

CREATE UNIQUE INDEX empresa_oficina_id_key ON public.empresa USING btree (oficina_id);

CREATE UNIQUE INDEX empresa_pkey ON public.empresa USING btree (id);

CREATE UNIQUE INDEX fipe_marcas_cache_pkey ON public.fipe_marcas_cache USING btree (codigo);

CREATE UNIQUE INDEX fipe_modelos_cache_pkey ON public.fipe_modelos_cache USING btree (id);

CREATE INDEX idx_anexos_oficina ON public.anexos USING btree (oficina_id);

CREATE INDEX idx_anexos_parent ON public.anexos USING btree (parent_type, parent_id);

CREATE INDEX idx_clientes_oficina ON public.clientes USING btree (oficina_id);

CREATE INDEX idx_clientes_oficina_ativo ON public.clientes USING btree (oficina_id) WHERE ativo;

CREATE INDEX idx_fipe_modelos_marca ON public.fipe_modelos_cache USING btree (marca_codigo);

CREATE INDEX idx_notas_oficina ON public.notas USING btree (oficina_id);

CREATE INDEX idx_orcamentos_cliente ON public.orcamentos USING btree (cliente_id);

CREATE INDEX idx_orcamentos_oficina ON public.orcamentos USING btree (oficina_id);

CREATE INDEX idx_orcamentos_veiculo ON public.orcamentos USING btree (veiculo_id);

CREATE INDEX idx_perfis_oficina ON public.perfis USING btree (oficina_id);

CREATE INDEX idx_transacoes_oficina ON public.transacoes USING btree (oficina_id);

CREATE UNIQUE INDEX idx_transacoes_orcamento_unico ON public.transacoes USING btree (oficina_id, orcamento_id) WHERE (orcamento_id IS NOT NULL);

CREATE INDEX idx_veiculos_cliente ON public.veiculos USING btree (cliente_id);

CREATE INDEX idx_veiculos_oficina ON public.veiculos USING btree (oficina_id);

CREATE INDEX idx_veiculos_oficina_ativo ON public.veiculos USING btree (oficina_id) WHERE ativo;

CREATE UNIQUE INDEX idx_veiculos_placa_ativa_unica ON public.veiculos USING btree (oficina_id, upper(placa)) WHERE ativo;

CREATE UNIQUE INDEX marcas_modelos_custom_oficina_id_marca_modelo_key ON public.marcas_modelos_custom USING btree (oficina_id, marca, modelo);

CREATE UNIQUE INDEX marcas_modelos_custom_pkey ON public.marcas_modelos_custom USING btree (id);

CREATE UNIQUE INDEX notas_pkey ON public.notas USING btree (id);

CREATE UNIQUE INDEX oficinas_pkey ON public.oficinas USING btree (id);

CREATE UNIQUE INDEX orcamentos_pkey ON public.orcamentos USING btree (id);

CREATE UNIQUE INDEX pecas_custom_oficina_id_peca_key ON public.pecas_custom USING btree (oficina_id, peca);

CREATE UNIQUE INDEX pecas_custom_pkey ON public.pecas_custom USING btree (id);

CREATE UNIQUE INDEX perfis_pkey ON public.perfis USING btree (id);

CREATE UNIQUE INDEX servicos_custom_oficina_id_servico_key ON public.servicos_custom USING btree (oficina_id, servico);

CREATE UNIQUE INDEX servicos_custom_pkey ON public.servicos_custom USING btree (id);

CREATE UNIQUE INDEX transacoes_pkey ON public.transacoes USING btree (id);

CREATE UNIQUE INDEX veiculos_pkey ON public.veiculos USING btree (id);

alter table "public"."anexos" add constraint "anexos_pkey" PRIMARY KEY using index "anexos_pkey";

alter table "public"."clientes" add constraint "clientes_pkey" PRIMARY KEY using index "clientes_pkey";

alter table "public"."convites" add constraint "convites_pkey" PRIMARY KEY using index "convites_pkey";

alter table "public"."empresa" add constraint "empresa_pkey" PRIMARY KEY using index "empresa_pkey";

alter table "public"."fipe_marcas_cache" add constraint "fipe_marcas_cache_pkey" PRIMARY KEY using index "fipe_marcas_cache_pkey";

alter table "public"."fipe_modelos_cache" add constraint "fipe_modelos_cache_pkey" PRIMARY KEY using index "fipe_modelos_cache_pkey";

alter table "public"."marcas_modelos_custom" add constraint "marcas_modelos_custom_pkey" PRIMARY KEY using index "marcas_modelos_custom_pkey";

alter table "public"."notas" add constraint "notas_pkey" PRIMARY KEY using index "notas_pkey";

alter table "public"."oficinas" add constraint "oficinas_pkey" PRIMARY KEY using index "oficinas_pkey";

alter table "public"."orcamentos" add constraint "orcamentos_pkey" PRIMARY KEY using index "orcamentos_pkey";

alter table "public"."pecas_custom" add constraint "pecas_custom_pkey" PRIMARY KEY using index "pecas_custom_pkey";

alter table "public"."perfis" add constraint "perfis_pkey" PRIMARY KEY using index "perfis_pkey";

alter table "public"."servicos_custom" add constraint "servicos_custom_pkey" PRIMARY KEY using index "servicos_custom_pkey";

alter table "public"."transacoes" add constraint "transacoes_pkey" PRIMARY KEY using index "transacoes_pkey";

alter table "public"."veiculos" add constraint "veiculos_pkey" PRIMARY KEY using index "veiculos_pkey";

alter table "public"."anexos" add constraint "anexos_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."anexos" validate constraint "anexos_oficina_id_fkey";

alter table "public"."clientes" add constraint "clientes_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."clientes" validate constraint "clientes_oficina_id_fkey";

alter table "public"."clientes" add constraint "clientes_tipo_check" CHECK ((tipo = ANY (ARRAY['particular'::text, 'seguradora'::text, 'oficina_parceira'::text, 'frota'::text]))) not valid;

alter table "public"."clientes" validate constraint "clientes_tipo_check";

alter table "public"."convites" add constraint "convites_codigo_key" UNIQUE using index "convites_codigo_key";

alter table "public"."convites" add constraint "convites_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) not valid;

alter table "public"."convites" validate constraint "convites_oficina_id_fkey";

alter table "public"."convites" add constraint "convites_usado_por_fkey" FOREIGN KEY (usado_por) REFERENCES public.perfis(id) not valid;

alter table "public"."convites" validate constraint "convites_usado_por_fkey";

alter table "public"."empresa" add constraint "empresa_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."empresa" validate constraint "empresa_oficina_id_fkey";

alter table "public"."empresa" add constraint "empresa_oficina_id_key" UNIQUE using index "empresa_oficina_id_key";

alter table "public"."fipe_modelos_cache" add constraint "fipe_modelos_cache_marca_codigo_fkey" FOREIGN KEY (marca_codigo) REFERENCES public.fipe_marcas_cache(codigo) ON DELETE CASCADE not valid;

alter table "public"."fipe_modelos_cache" validate constraint "fipe_modelos_cache_marca_codigo_fkey";

alter table "public"."marcas_modelos_custom" add constraint "marcas_modelos_custom_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."marcas_modelos_custom" validate constraint "marcas_modelos_custom_oficina_id_fkey";

alter table "public"."marcas_modelos_custom" add constraint "marcas_modelos_custom_oficina_id_marca_modelo_key" UNIQUE using index "marcas_modelos_custom_oficina_id_marca_modelo_key";

alter table "public"."notas" add constraint "notas_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE SET NULL not valid;

alter table "public"."notas" validate constraint "notas_cliente_id_fkey";

alter table "public"."notas" add constraint "notas_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."notas" validate constraint "notas_oficina_id_fkey";

alter table "public"."notas" add constraint "notas_orcamento_id_fkey" FOREIGN KEY (orcamento_id) REFERENCES public.orcamentos(id) ON DELETE SET NULL not valid;

alter table "public"."notas" validate constraint "notas_orcamento_id_fkey";

alter table "public"."notas" add constraint "notas_veiculo_id_fkey" FOREIGN KEY (veiculo_id) REFERENCES public.veiculos(id) ON DELETE SET NULL not valid;

alter table "public"."notas" validate constraint "notas_veiculo_id_fkey";

alter table "public"."orcamentos" add constraint "orcamentos_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE SET NULL not valid;

alter table "public"."orcamentos" validate constraint "orcamentos_cliente_id_fkey";

alter table "public"."orcamentos" add constraint "orcamentos_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."orcamentos" validate constraint "orcamentos_oficina_id_fkey";

alter table "public"."orcamentos" add constraint "orcamentos_status_check" CHECK ((status = ANY (ARRAY['pendente'::text, 'aprovado'::text, 'em_andamento'::text, 'concluido'::text, 'cancelado'::text]))) not valid;

alter table "public"."orcamentos" validate constraint "orcamentos_status_check";

alter table "public"."orcamentos" add constraint "orcamentos_tipo_atendimento_check" CHECK ((tipo_atendimento = ANY (ARRAY['particular'::text, 'seguro'::text]))) not valid;

alter table "public"."orcamentos" validate constraint "orcamentos_tipo_atendimento_check";

alter table "public"."orcamentos" add constraint "orcamentos_veiculo_id_fkey" FOREIGN KEY (veiculo_id) REFERENCES public.veiculos(id) ON DELETE SET NULL not valid;

alter table "public"."orcamentos" validate constraint "orcamentos_veiculo_id_fkey";

alter table "public"."pecas_custom" add constraint "pecas_custom_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."pecas_custom" validate constraint "pecas_custom_oficina_id_fkey";

alter table "public"."pecas_custom" add constraint "pecas_custom_oficina_id_peca_key" UNIQUE using index "pecas_custom_oficina_id_peca_key";

alter table "public"."perfis" add constraint "perfis_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."perfis" validate constraint "perfis_id_fkey";

alter table "public"."perfis" add constraint "perfis_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."perfis" validate constraint "perfis_oficina_id_fkey";

alter table "public"."perfis" add constraint "perfis_role_check" CHECK ((role = ANY (ARRAY['admin'::text, 'colaborador'::text]))) not valid;

alter table "public"."perfis" validate constraint "perfis_role_check";

alter table "public"."servicos_custom" add constraint "servicos_custom_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."servicos_custom" validate constraint "servicos_custom_oficina_id_fkey";

alter table "public"."servicos_custom" add constraint "servicos_custom_oficina_id_servico_key" UNIQUE using index "servicos_custom_oficina_id_servico_key";

alter table "public"."transacoes" add constraint "transacoes_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."transacoes" validate constraint "transacoes_oficina_id_fkey";

alter table "public"."transacoes" add constraint "transacoes_orcamento_id_fkey" FOREIGN KEY (orcamento_id) REFERENCES public.orcamentos(id) ON DELETE SET NULL not valid;

alter table "public"."transacoes" validate constraint "transacoes_orcamento_id_fkey";

alter table "public"."transacoes" add constraint "transacoes_tipo_check" CHECK ((tipo = ANY (ARRAY['entrada'::text, 'saida'::text]))) not valid;

alter table "public"."transacoes" validate constraint "transacoes_tipo_check";

alter table "public"."veiculos" add constraint "veiculos_cliente_id_fkey" FOREIGN KEY (cliente_id) REFERENCES public.clientes(id) ON DELETE SET NULL not valid;

alter table "public"."veiculos" validate constraint "veiculos_cliente_id_fkey";

alter table "public"."veiculos" add constraint "veiculos_oficina_id_fkey" FOREIGN KEY (oficina_id) REFERENCES public.oficinas(id) ON DELETE CASCADE not valid;

alter table "public"."veiculos" validate constraint "veiculos_oficina_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.aceitar_convite(p_codigo text, p_nome text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_convite convites%ROWTYPE;
BEGIN
  SELECT * INTO v_convite FROM convites
  WHERE codigo = p_codigo AND usado_em IS NULL AND expira_em > now()
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Código de convite inválido ou expirado';
  END IF;

  IF EXISTS (SELECT 1 FROM perfis WHERE id = auth.uid()) THEN
    RAISE EXCEPTION 'Usuário já possui perfil';
  END IF;

  INSERT INTO perfis (id, oficina_id, nome, role)
  VALUES (auth.uid(), v_convite.oficina_id, p_nome, 'colaborador');

  UPDATE convites SET usado_em = now(), usado_por = auth.uid()
  WHERE id = v_convite.id;

  RETURN v_convite.oficina_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.is_admin_atual()
 RETURNS boolean
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE((SELECT role = 'admin' FROM perfis WHERE id = auth.uid()), false);
$function$
;

CREATE OR REPLACE FUNCTION public.oficina_do_usuario_atual()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  select oficina_id from perfis where id = auth.uid();
$function$
;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_atualizado_em()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.atualizado_em = now();
  return new;
end;
$function$
;

grant references on table "public"."anexos" to "anon";

grant trigger on table "public"."anexos" to "anon";

grant truncate on table "public"."anexos" to "anon";

grant delete on table "public"."anexos" to "authenticated";

grant insert on table "public"."anexos" to "authenticated";

grant references on table "public"."anexos" to "authenticated";

grant select on table "public"."anexos" to "authenticated";

grant trigger on table "public"."anexos" to "authenticated";

grant truncate on table "public"."anexos" to "authenticated";

grant update on table "public"."anexos" to "authenticated";

grant references on table "public"."anexos" to "service_role";

grant trigger on table "public"."anexos" to "service_role";

grant truncate on table "public"."anexos" to "service_role";

grant references on table "public"."clientes" to "anon";

grant trigger on table "public"."clientes" to "anon";

grant truncate on table "public"."clientes" to "anon";

grant delete on table "public"."clientes" to "authenticated";

grant insert on table "public"."clientes" to "authenticated";

grant references on table "public"."clientes" to "authenticated";

grant select on table "public"."clientes" to "authenticated";

grant trigger on table "public"."clientes" to "authenticated";

grant truncate on table "public"."clientes" to "authenticated";

grant update on table "public"."clientes" to "authenticated";

grant references on table "public"."clientes" to "service_role";

grant trigger on table "public"."clientes" to "service_role";

grant truncate on table "public"."clientes" to "service_role";

grant references on table "public"."convites" to "anon";

grant trigger on table "public"."convites" to "anon";

grant truncate on table "public"."convites" to "anon";

grant delete on table "public"."convites" to "authenticated";

grant insert on table "public"."convites" to "authenticated";

grant references on table "public"."convites" to "authenticated";

grant select on table "public"."convites" to "authenticated";

grant trigger on table "public"."convites" to "authenticated";

grant truncate on table "public"."convites" to "authenticated";

grant update on table "public"."convites" to "authenticated";

grant references on table "public"."convites" to "service_role";

grant trigger on table "public"."convites" to "service_role";

grant truncate on table "public"."convites" to "service_role";

grant references on table "public"."empresa" to "anon";

grant trigger on table "public"."empresa" to "anon";

grant truncate on table "public"."empresa" to "anon";

grant delete on table "public"."empresa" to "authenticated";

grant insert on table "public"."empresa" to "authenticated";

grant references on table "public"."empresa" to "authenticated";

grant select on table "public"."empresa" to "authenticated";

grant trigger on table "public"."empresa" to "authenticated";

grant truncate on table "public"."empresa" to "authenticated";

grant update on table "public"."empresa" to "authenticated";

grant references on table "public"."empresa" to "service_role";

grant trigger on table "public"."empresa" to "service_role";

grant truncate on table "public"."empresa" to "service_role";

grant references on table "public"."fipe_marcas_cache" to "anon";

grant trigger on table "public"."fipe_marcas_cache" to "anon";

grant truncate on table "public"."fipe_marcas_cache" to "anon";

grant references on table "public"."fipe_marcas_cache" to "authenticated";

grant select on table "public"."fipe_marcas_cache" to "authenticated";

grant trigger on table "public"."fipe_marcas_cache" to "authenticated";

grant truncate on table "public"."fipe_marcas_cache" to "authenticated";

grant references on table "public"."fipe_marcas_cache" to "service_role";

grant trigger on table "public"."fipe_marcas_cache" to "service_role";

grant truncate on table "public"."fipe_marcas_cache" to "service_role";

grant references on table "public"."fipe_modelos_cache" to "anon";

grant trigger on table "public"."fipe_modelos_cache" to "anon";

grant truncate on table "public"."fipe_modelos_cache" to "anon";

grant references on table "public"."fipe_modelos_cache" to "authenticated";

grant select on table "public"."fipe_modelos_cache" to "authenticated";

grant trigger on table "public"."fipe_modelos_cache" to "authenticated";

grant truncate on table "public"."fipe_modelos_cache" to "authenticated";

grant references on table "public"."fipe_modelos_cache" to "service_role";

grant trigger on table "public"."fipe_modelos_cache" to "service_role";

grant truncate on table "public"."fipe_modelos_cache" to "service_role";

grant references on table "public"."marcas_modelos_custom" to "anon";

grant trigger on table "public"."marcas_modelos_custom" to "anon";

grant truncate on table "public"."marcas_modelos_custom" to "anon";

grant delete on table "public"."marcas_modelos_custom" to "authenticated";

grant insert on table "public"."marcas_modelos_custom" to "authenticated";

grant references on table "public"."marcas_modelos_custom" to "authenticated";

grant select on table "public"."marcas_modelos_custom" to "authenticated";

grant trigger on table "public"."marcas_modelos_custom" to "authenticated";

grant truncate on table "public"."marcas_modelos_custom" to "authenticated";

grant update on table "public"."marcas_modelos_custom" to "authenticated";

grant references on table "public"."marcas_modelos_custom" to "service_role";

grant trigger on table "public"."marcas_modelos_custom" to "service_role";

grant truncate on table "public"."marcas_modelos_custom" to "service_role";

grant references on table "public"."notas" to "anon";

grant trigger on table "public"."notas" to "anon";

grant truncate on table "public"."notas" to "anon";

grant delete on table "public"."notas" to "authenticated";

grant insert on table "public"."notas" to "authenticated";

grant references on table "public"."notas" to "authenticated";

grant select on table "public"."notas" to "authenticated";

grant trigger on table "public"."notas" to "authenticated";

grant truncate on table "public"."notas" to "authenticated";

grant update on table "public"."notas" to "authenticated";

grant references on table "public"."notas" to "service_role";

grant trigger on table "public"."notas" to "service_role";

grant truncate on table "public"."notas" to "service_role";

grant references on table "public"."oficinas" to "anon";

grant trigger on table "public"."oficinas" to "anon";

grant truncate on table "public"."oficinas" to "anon";

grant delete on table "public"."oficinas" to "authenticated";

grant insert on table "public"."oficinas" to "authenticated";

grant references on table "public"."oficinas" to "authenticated";

grant select on table "public"."oficinas" to "authenticated";

grant trigger on table "public"."oficinas" to "authenticated";

grant truncate on table "public"."oficinas" to "authenticated";

grant update on table "public"."oficinas" to "authenticated";

grant references on table "public"."oficinas" to "service_role";

grant trigger on table "public"."oficinas" to "service_role";

grant truncate on table "public"."oficinas" to "service_role";

grant references on table "public"."orcamentos" to "anon";

grant trigger on table "public"."orcamentos" to "anon";

grant truncate on table "public"."orcamentos" to "anon";

grant delete on table "public"."orcamentos" to "authenticated";

grant insert on table "public"."orcamentos" to "authenticated";

grant references on table "public"."orcamentos" to "authenticated";

grant select on table "public"."orcamentos" to "authenticated";

grant trigger on table "public"."orcamentos" to "authenticated";

grant truncate on table "public"."orcamentos" to "authenticated";

grant update on table "public"."orcamentos" to "authenticated";

grant references on table "public"."orcamentos" to "service_role";

grant trigger on table "public"."orcamentos" to "service_role";

grant truncate on table "public"."orcamentos" to "service_role";

grant references on table "public"."pecas_custom" to "anon";

grant trigger on table "public"."pecas_custom" to "anon";

grant truncate on table "public"."pecas_custom" to "anon";

grant delete on table "public"."pecas_custom" to "authenticated";

grant insert on table "public"."pecas_custom" to "authenticated";

grant references on table "public"."pecas_custom" to "authenticated";

grant select on table "public"."pecas_custom" to "authenticated";

grant trigger on table "public"."pecas_custom" to "authenticated";

grant truncate on table "public"."pecas_custom" to "authenticated";

grant update on table "public"."pecas_custom" to "authenticated";

grant references on table "public"."pecas_custom" to "service_role";

grant trigger on table "public"."pecas_custom" to "service_role";

grant truncate on table "public"."pecas_custom" to "service_role";

grant references on table "public"."perfis" to "anon";

grant trigger on table "public"."perfis" to "anon";

grant truncate on table "public"."perfis" to "anon";

grant delete on table "public"."perfis" to "authenticated";

grant insert on table "public"."perfis" to "authenticated";

grant references on table "public"."perfis" to "authenticated";

grant select on table "public"."perfis" to "authenticated";

grant trigger on table "public"."perfis" to "authenticated";

grant truncate on table "public"."perfis" to "authenticated";

grant update on table "public"."perfis" to "authenticated";

grant references on table "public"."perfis" to "service_role";

grant trigger on table "public"."perfis" to "service_role";

grant truncate on table "public"."perfis" to "service_role";

grant references on table "public"."servicos_custom" to "anon";

grant trigger on table "public"."servicos_custom" to "anon";

grant truncate on table "public"."servicos_custom" to "anon";

grant delete on table "public"."servicos_custom" to "authenticated";

grant insert on table "public"."servicos_custom" to "authenticated";

grant references on table "public"."servicos_custom" to "authenticated";

grant select on table "public"."servicos_custom" to "authenticated";

grant trigger on table "public"."servicos_custom" to "authenticated";

grant truncate on table "public"."servicos_custom" to "authenticated";

grant update on table "public"."servicos_custom" to "authenticated";

grant references on table "public"."servicos_custom" to "service_role";

grant trigger on table "public"."servicos_custom" to "service_role";

grant truncate on table "public"."servicos_custom" to "service_role";

grant references on table "public"."transacoes" to "anon";

grant trigger on table "public"."transacoes" to "anon";

grant truncate on table "public"."transacoes" to "anon";

grant delete on table "public"."transacoes" to "authenticated";

grant insert on table "public"."transacoes" to "authenticated";

grant references on table "public"."transacoes" to "authenticated";

grant select on table "public"."transacoes" to "authenticated";

grant trigger on table "public"."transacoes" to "authenticated";

grant truncate on table "public"."transacoes" to "authenticated";

grant update on table "public"."transacoes" to "authenticated";

grant references on table "public"."transacoes" to "service_role";

grant trigger on table "public"."transacoes" to "service_role";

grant truncate on table "public"."transacoes" to "service_role";

grant references on table "public"."veiculos" to "anon";

grant trigger on table "public"."veiculos" to "anon";

grant truncate on table "public"."veiculos" to "anon";

grant delete on table "public"."veiculos" to "authenticated";

grant insert on table "public"."veiculos" to "authenticated";

grant references on table "public"."veiculos" to "authenticated";

grant select on table "public"."veiculos" to "authenticated";

grant trigger on table "public"."veiculos" to "authenticated";

grant truncate on table "public"."veiculos" to "authenticated";

grant update on table "public"."veiculos" to "authenticated";

grant references on table "public"."veiculos" to "service_role";

grant trigger on table "public"."veiculos" to "service_role";

grant truncate on table "public"."veiculos" to "service_role";


  create policy "isolamento por oficina"
  on "public"."anexos"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "isolamento por oficina"
  on "public"."clientes"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "admin cria convite para sua oficina"
  on "public"."convites"
  as permissive
  for insert
  to authenticated
with check (((oficina_id = public.oficina_do_usuario_atual()) AND public.is_admin_atual()));



  create policy "admin ve convites da sua oficina"
  on "public"."convites"
  as permissive
  for select
  to authenticated
using (((oficina_id = public.oficina_do_usuario_atual()) AND public.is_admin_atual()));



  create policy "isolamento por oficina"
  on "public"."empresa"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "leitura publica fipe marcas"
  on "public"."fipe_marcas_cache"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "leitura publica fipe modelos"
  on "public"."fipe_modelos_cache"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "isolamento por oficina"
  on "public"."marcas_modelos_custom"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "isolamento por oficina"
  on "public"."notas"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "usuario atualiza sua propria oficina"
  on "public"."oficinas"
  as permissive
  for update
  to authenticated
using ((id = public.oficina_do_usuario_atual()))
with check ((id = public.oficina_do_usuario_atual()));



  create policy "usuario autenticado cria oficina"
  on "public"."oficinas"
  as permissive
  for insert
  to authenticated
with check (true);



  create policy "usuario ve sua propria oficina"
  on "public"."oficinas"
  as permissive
  for select
  to public
using ((id = public.oficina_do_usuario_atual()));



  create policy "isolamento por oficina"
  on "public"."orcamentos"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "isolamento por oficina"
  on "public"."pecas_custom"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "usuario cria seu proprio perfil"
  on "public"."perfis"
  as permissive
  for insert
  to authenticated
with check ((id = auth.uid()));



  create policy "usuario ve seu proprio perfil e colegas da oficina"
  on "public"."perfis"
  as permissive
  for select
  to public
using ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "isolamento por oficina"
  on "public"."servicos_custom"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "isolamento por oficina"
  on "public"."transacoes"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));



  create policy "isolamento por oficina"
  on "public"."veiculos"
  as permissive
  for all
  to public
using ((oficina_id = public.oficina_do_usuario_atual()))
with check ((oficina_id = public.oficina_do_usuario_atual()));


CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.clientes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.empresa FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.marcas_modelos_custom FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.notas FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.orcamentos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.pecas_custom FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.servicos_custom FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.transacoes FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();

CREATE TRIGGER trg_set_atualizado_em BEFORE UPDATE ON public.veiculos FOR EACH ROW EXECUTE FUNCTION public.set_atualizado_em();


