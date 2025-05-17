create table public.fcm
(
    auth_id serial,
    token   text not null,
    constraint fcm_auth_auth_id_fk
        foreign key (auth_id) references public.auth (auth_id)
            on delete cascade
);

alter table public.fcm
    owner to chatter;

create unique index fcm_auth_id_uindex
    on public.fcm (auth_id);

