create table public.room
(
    room_id integer generated always as identity,
    alias   varchar(100) not null,
    constraint room_pk
        primary key (room_id)
);

alter table public.room
    owner to chatter;

create unique index room_room_id_uindex
    on public.room (room_id);

