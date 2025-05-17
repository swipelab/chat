create table public.auth
(
    auth_id       serial,
    alias         varchar(100) not null,
    password_hash bytea,
    password_salt bytea
);

alter table public.auth
    owner to chatter;

create unique index auth_auth_id_uindex
    on public.auth (auth_id);

create unique index auth_alias_uindex
    on public.auth (alias);

