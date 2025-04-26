create table message
(
    message_id     integer generated always as identity,
    payload        text              not null,
    room_id        integer default 0 not null,
    sender_auth_id integer default 0 not null
);

alter table message
    add constraint message_room_room_id_fk
        foreign key (room_id) references room;

alter table message
    add constraint message_auth_auth_id_fk
        foreign key (sender_auth_id) references auth ();

