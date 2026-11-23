-- @operation: export
-- @entity: batch
-- @name: Add Judas and Punisher694 to FR Anime SubFr
-- @description: Judas and Punisher694 join the trusted anime SubFr teams.

-- Judas is a new regex (same tags as Erai-raws). Punisher694 already exists
-- from the core patterns and stays in FR Team Tier 1.
INSERT INTO regular_expressions (name, pattern, description)
SELECT 'Judas',
       '(?<=^|[\s.-])Judas\b',
       'Matches "Judas" when preceded by whitespace, a hyphen or dot'
WHERE NOT EXISTS (SELECT 1 FROM regular_expressions WHERE name = 'Judas');

INSERT OR IGNORE INTO regular_expression_tags (regular_expression_name, tag_name)
SELECT 'Judas', t.name
FROM tags t
WHERE t.name IN ('Anime', 'French', 'Release Group');

WITH team(name) AS (VALUES ('Judas'), ('Punisher694'))
INSERT OR IGNORE INTO custom_format_conditions (
  custom_format_name, name, type, arr_type, negate, required
)
SELECT 'FR Anime SubFr', team.name, 'release_group', 'all', 0, 0
FROM team
WHERE EXISTS (SELECT 1 FROM custom_formats WHERE name = 'FR Anime SubFr')
  AND EXISTS (SELECT 1 FROM regular_expressions re WHERE re.name = team.name);

WITH team(name) AS (VALUES ('Judas'), ('Punisher694'))
INSERT OR IGNORE INTO condition_patterns (
  custom_format_name, condition_name, regular_expression_name
)
SELECT 'FR Anime SubFr', team.name, team.name
FROM team
WHERE EXISTS (SELECT 1 FROM custom_formats WHERE name = 'FR Anime SubFr')
  AND EXISTS (SELECT 1 FROM regular_expressions re WHERE re.name = team.name);
