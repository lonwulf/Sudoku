-- Leaderboard rebuilds and the "has anyone scored?" check filter on these columns
create index idx_users_shadow_banned_lifetime_score on users (shadow_banned, lifetime_score);
