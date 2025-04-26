create table room
(
    room_id integer generated always as identity,
    alias   varchar(100) not null
);

create unique index room_room_id_uindex
    on room (room_id);

alter table room
    add constraint room_pk
        primary key (room_id);

