drop policy "usuario cria seu proprio perfil" on "public"."perfis";

create policy "usuario cria seu proprio perfil"
on "public"."perfis"
as permissive
for insert
to authenticated
with check (
  id = auth.uid()
  and role = 'admin'
  and not exists (
    select 1 from perfis p
    where p.oficina_id = perfis.oficina_id
  )
);
