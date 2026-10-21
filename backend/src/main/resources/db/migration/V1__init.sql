-- Initial schema, matching the JPA entities (Hibernate only validates it)

create table users (
    id                varchar(255) not null primary key,
    email             varchar(255),
    display_name      varchar(255),
    puzzles_completed integer      not null default 0,
    shadow_banned     boolean      not null default false,
    lifetime_score    integer      not null default 0
);

-- @GeneratedValue(AUTO) ids use <table>_seq with Hibernate's default allocation size of 50
create sequence fraud_flags_seq start with 1 increment by 50;

create table fraud_flags (
    id        bigint       not null primary key,
    user_id   varchar(255),
    reason    varchar(255),
    timestamp timestamp(6),
    reviewed  boolean      not null default false
);

create index idx_fraud_flags_user_id on fraud_flags (user_id);

create sequence leaderboard_audit_log_seq start with 1 increment by 50;

create table leaderboard_audit_log (
    id           bigint       not null primary key,
    user_id      varchar(255),
    action       varchar(32),
    reason       varchar(255),
    triggered_by varchar(255),
    timestamp    timestamp(6)
);

-- serves findByUserIdOrderByTimestampDesc
create index idx_leaderboard_audit_log_user_id_timestamp on leaderboard_audit_log (user_id, timestamp);
