-- @operation: export
-- @entity: batch
-- @name: Anime priority teams
-- @description: Give hand-picked anime teams (Punisher694) a bonus large enough to always rank first.

-- Team tiers are only worth 1000-4000 points, while source and language
-- formats move scores by 30000-890000. A compact 1080p BluRay x265 AAC
-- encode from a trusted team can therefore lose to a bigger WEB-DL/MULTi
-- release from anyone else. This CF adds +200000 in both anime profiles,
-- which outweighs every source/language gap between accepted releases
-- (the largest is VOSTFR -30000 / VF -70000 vs MULTi) without overriding
-- the -999999 hard bans (VFQ, French Missing, LQ, wrong language in the
-- VOSTFR-only profile).

INSERT INTO custom_formats (name, description)
SELECT 'FR Anime Priority Team',
       'Hand-picked anime teams that must rank above every other accepted release.'
WHERE NOT EXISTS (SELECT 1 FROM custom_formats WHERE name = 'FR Anime Priority Team');

INSERT OR IGNORE INTO custom_format_tags (custom_format_name, tag_name)
SELECT 'FR Anime Priority Team', t.name
FROM tags t
WHERE t.name IN ('Anime', 'French', 'Release Group');

WITH team(name) AS (VALUES ('Punisher694'))
INSERT OR IGNORE INTO custom_format_conditions (
  custom_format_name, name, type, arr_type, negate, required
)
SELECT 'FR Anime Priority Team', team.name, 'release_group', 'all', 0, 0
FROM team
WHERE EXISTS (SELECT 1 FROM regular_expressions re WHERE re.name = team.name);

WITH team(name) AS (VALUES ('Punisher694'))
INSERT OR IGNORE INTO condition_patterns (
  custom_format_name, condition_name, regular_expression_name
)
SELECT 'FR Anime Priority Team', team.name, team.name
FROM team
WHERE EXISTS (SELECT 1 FROM regular_expressions re WHERE re.name = team.name);

WITH profile(name) AS (
  VALUES ('Anime 1080p FR'), ('Anime 1080p VOSTFR FR')
)
INSERT INTO quality_profile_custom_formats (
  quality_profile_name, custom_format_name, arr_type, score
)
SELECT profile.name, 'FR Anime Priority Team', 'all', 200000
FROM profile
WHERE EXISTS (SELECT 1 FROM quality_profiles qp WHERE qp.name = profile.name)
ON CONFLICT(quality_profile_name, custom_format_name, arr_type)
DO UPDATE SET score = excluded.score;
