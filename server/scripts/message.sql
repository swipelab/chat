create table public.message
(
    message_id     integer generated always as identity,
    payload        bytea             not null,
    room_id        integer default 0 not null,
    sender_auth_id integer default 0 not null,
    constraint message_room_room_id_fk
        foreign key (room_id) references public.room,
    constraint message_auth_auth_id_fk
        foreign key (sender_auth_id) references public.auth (auth_id)
);

alter table public.message
    owner to chatter;

