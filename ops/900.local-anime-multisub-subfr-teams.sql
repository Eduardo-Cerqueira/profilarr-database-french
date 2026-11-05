-- @operation: export
-- @entity: batch
-- @name: Anime MultiSub from trusted SubFr teams counts as VOSTFR
-- @description: Treat "[Team] ... [Multi-Subs]" anime releases from FR Anime SubFr teams as French subtitles, and add Judas to those teams.

-- Anime releases put tags in brackets, e.g.
--   [Judas] Show - S02E05 [1080p][HEVC x265 10bit][Dual-Audio][Multi-Subs] (Weekly)
-- The existing MultiSub and team regexes only accept whitespace, dot or hyphen
-- as boundaries, so "[Multi-Subs]" and "[Judas]" are never seen in the title and
-- these releases fall into French Missing. This op adds a bracket-aware
-- "MultiSub + SubFr team" proof that counts like French VOSTFR.

-- 1. Judas joins the trusted anime SubFr teams (same tags as Erai-raws).
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

-- 2. Title proof: a MultiSub marker AND a FR Anime SubFr team, both allowed
-- inside brackets or parentheses. Team patterns are taken from the
-- FR Anime SubFr members with "[" and "(" added to their left boundary.
INSERT INTO regular_expressions (name, pattern, description)
SELECT 'French MultiSub + Anime SubFr Team Marker',
       '(?!)',
       'Matches release titles that contain both a MultiSub marker and a FR Anime SubFr team, including bracketed anime titles such as "[Judas] ... [Multi-Subs]". Regenerated from FR Anime SubFr members.'
WHERE NOT EXISTS (
  SELECT 1 FROM regular_expressions
  WHERE name = 'French MultiSub + Anime SubFr Team Marker'
);

UPDATE regular_expressions
SET pattern = (
  SELECT '(?i)(?=.*(?<=^|[\s._\[(-])(?:MULTI(?:PLE)?[\s._-]?SUB(?:S|TITLE|TITLES)?)(?=$|[\s._\])-]))'
      || '(?=.*(?:'
      || group_concat('(?:' || replace(team.pattern, '(?<=^|[\s.-])', '(?<=^|[\s.\[(-])') || ')', '|')
      || ')).*'
  FROM condition_patterns cp
  JOIN custom_format_conditions cfc
    ON cfc.custom_format_name = cp.custom_format_name
   AND cfc.name = cp.condition_name
  JOIN regular_expressions team
    ON team.name = cp.regular_expression_name
  WHERE cp.custom_format_name = 'FR Anime SubFr'
    AND cfc.type = 'release_group'
)
WHERE name = 'French MultiSub + Anime SubFr Team Marker';

INSERT OR IGNORE INTO regular_expression_tags (regular_expression_name, tag_name)
SELECT 'French MultiSub + Anime SubFr Team Marker', t.name
FROM tags t
WHERE t.name IN ('French', 'Language');

-- 3. Custom Format. It stands in for French VOSTFR, so it steps aside when
-- another French language marker is already present (one language tag only).
INSERT INTO custom_formats (name, description)
SELECT 'French MultiSub + Anime SubFr Team',
       'Matches anime MultiSub releases from a trusted FR Anime SubFr team. Scored like French VOSTFR.'
WHERE NOT EXISTS (
  SELECT 1 FROM custom_formats
  WHERE name = 'French MultiSub + Anime SubFr Team'
);

INSERT OR IGNORE INTO custom_format_tags (custom_format_name, tag_name)
SELECT 'French MultiSub + Anime SubFr Team', t.name
FROM tags t
WHERE t.name IN ('French', 'Language');

WITH wanted(condition_name, regex_name, negate) AS (
  VALUES
    ('French MultiSub + Anime SubFr Team Marker', 'French MultiSub + Anime SubFr Team Marker', 0),
    ('Not French MULTi', 'French MULTi', 1),
    ('Not French VF', 'French VF', 1),
    ('Not French VOSTFR', 'French VOSTFR', 1),
    ('Not French VFQ', 'French VFQ', 1)
)
INSERT OR IGNORE INTO custom_format_conditions (
  custom_format_name, name, type, arr_type, negate, required
)
SELECT 'French MultiSub + Anime SubFr Team', condition_name, 'release_title', 'all', negate, 1
FROM wanted;

WITH wanted(condition_name, regex_name) AS (
  VALUES
    ('French MultiSub + Anime SubFr Team Marker', 'French MultiSub + Anime SubFr Team Marker'),
    ('Not French MULTi', 'French MULTi'),
    ('Not French VF', 'French VF'),
    ('Not French VOSTFR', 'French VOSTFR'),
    ('Not French VFQ', 'French VFQ')
)
INSERT OR IGNORE INTO condition_patterns (
  custom_format_name, condition_name, regular_expression_name
)
SELECT 'French MultiSub + Anime SubFr Team', condition_name, regex_name
FROM wanted;

-- 4. These releases are no longer "missing French".
INSERT OR IGNORE INTO custom_format_conditions (
  custom_format_name, name, type, arr_type, negate, required
)
SELECT cf.name, 'Not French MultiSub + Anime SubFr Team', 'release_title', 'all', 1, 1
FROM custom_formats cf
WHERE cf.name IN ('French Missing', 'French Missing (INTL)');

INSERT OR IGNORE INTO condition_patterns (
  custom_format_name, condition_name, regular_expression_name
)
SELECT cf.name, 'Not French MultiSub + Anime SubFr Team', 'French MultiSub + Anime SubFr Team Marker'
FROM custom_formats cf
WHERE cf.name IN ('French Missing', 'French Missing (INTL)');

-- 5. Score it exactly like French VOSTFR in every profile that scores VOSTFR,
-- so non-anime profiles keep their MULTi > VF > VOSTFR order.
INSERT INTO quality_profile_custom_formats (
  quality_profile_name, custom_format_name, arr_type, score
)
SELECT quality_profile_name, 'French MultiSub + Anime SubFr Team', arr_type, score
FROM quality_profile_custom_formats
WHERE custom_format_name = 'French VOSTFR'
ON CONFLICT(quality_profile_name, custom_format_name, arr_type)
DO UPDATE SET score = excluded.score;
