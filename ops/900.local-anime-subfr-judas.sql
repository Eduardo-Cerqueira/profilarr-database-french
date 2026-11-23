-- @operation: export
-- @entity: batch
-- @name: Add Judas to FR Anime SubFr
-- @description: Judas joins the trusted anime SubFr teams (same tags as Erai-raws).

INSERT INTO regular_expressions (name, pattern, description)
SELECT 'Judas',
       '(?<=^|[\s.-])Judas\b',
       'Matches "Judas" when preceded by whitespace, a hyphen or dot'
WHERE NOT EXISTS (SELECT 1 FROM regular_expressions WHERE name = 'Judas');

INSERT OR IGNORE INTO regular_expression_tags (regular_expression_name, tag_name)
SELECT 'Judas', t.name
FROM tags t
WHERE t.name IN ('Anime', 'French', 'Release Group');

INSERT OR IGNORE INTO custom_format_conditions (
  custom_format_name, name, type, arr_type, negate, required
)
SELECT 'FR Anime SubFr', 'Judas', 'release_group', 'all', 0, 0
WHERE EXISTS (SELECT 1 FROM custom_formats WHERE name = 'FR Anime SubFr');

INSERT OR IGNORE INTO condition_patterns (
  custom_format_name, condition_name, regular_expression_name
)
SELECT 'FR Anime SubFr', 'Judas', 'Judas'
WHERE EXISTS (SELECT 1 FROM custom_formats WHERE name = 'FR Anime SubFr');
