create table auth
(
    auth_id       serial,
    alias         varchar(100) not null,
    password_hash bytea,
    password_salt bytea
);

create unique index auth_auth_id_uindex
    on auth (auth_id);

