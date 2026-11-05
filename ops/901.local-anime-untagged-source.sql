-- @operation: export
-- @entity: batch
-- @name: Anime releases without a source tag get a source score
-- @description: Score 1080p/720p anime releases that carry no WEB/BluRay/HDTV word so they reach the profile minimum.

-- Fansub-style anime titles such as
--   [Judas] Show - S02E05 [1080p][HEVC x265 10bit][Dual-Audio][Multi-Subs]
-- name no source. Sonarr then parses them as HDTV, but "1080p HDTV" also
-- requires the word HDTV in the title, so no source CF matches and the
-- release stays far below the 20000 minimum score.
-- These CFs catch exactly that case: HDTV parsed, but no HDTV in the title.
-- They are scored only in the anime profiles, just below a real WEBRip of
-- the same resolution, so a properly tagged WEB/BluRay release still wins.

WITH wanted(name, resolution, description) AS (
  VALUES
    ('1080p Untagged Source', '1080p', 'Matches 1080p releases whose title names no source: parsed as HDTV without the word HDTV, typical of fansub anime encodes.'),
    ('720p Untagged Source', '720p', 'Matches 720p releases whose title names no source: parsed as HDTV without the word HDTV, typical of fansub anime encodes.')
)
INSERT INTO custom_formats (name, description)
SELECT name, description FROM wanted
WHERE NOT EXISTS (SELECT 1 FROM custom_formats cf WHERE cf.name = wanted.name);

INSERT OR IGNORE INTO custom_format_tags (custom_format_name, tag_name)
SELECT cf.name, t.name
FROM custom_formats cf, tags t
WHERE cf.name IN ('1080p Untagged Source', '720p Untagged Source')
  AND t.name IN ('Anime', 'Source');

INSERT OR IGNORE INTO custom_format_conditions (
  custom_format_name, name, type, arr_type, negate, required
)
SELECT cf.name, c.name, c.type, 'all', c.negate, 1
FROM custom_formats cf,
     (SELECT 'Resolution' AS name, 'resolution' AS type, 0 AS negate
      UNION ALL SELECT 'HDTV', 'source', 0
      UNION ALL SELECT 'Not HDTV Regex', 'release_title', 1) c
WHERE cf.name IN ('1080p Untagged Source', '720p Untagged Source');

INSERT OR IGNORE INTO condition_resolutions (custom_format_name, condition_name, resolution)
VALUES
  ('1080p Untagged Source', 'Resolution', '1080p'),
  ('720p Untagged Source', 'Resolution', '720p');

INSERT OR IGNORE INTO condition_sources (custom_format_name, condition_name, source)
VALUES
  ('1080p Untagged Source', 'HDTV', 'television'),
  ('720p Untagged Source', 'HDTV', 'television');

INSERT OR IGNORE INTO condition_patterns (custom_format_name, condition_name, regular_expression_name)
VALUES
  ('1080p Untagged Source', 'Not HDTV Regex', 'HDTV'),
  ('720p Untagged Source', 'Not HDTV Regex', 'HDTV');

-- Just below 1080p WEBRip (850000) / 720p WEB-DL (660000) in both anime profiles.
WITH scores(custom_format_name, score) AS (
  VALUES
    ('1080p Untagged Source', 820000),
    ('720p Untagged Source', 620000)
), profile(name) AS (
  VALUES ('Anime 1080p FR'), ('Anime 1080p VOSTFR FR')
)
INSERT INTO quality_profile_custom_formats (
  quality_profile_name, custom_format_name, arr_type, score
)
SELECT profile.name, scores.custom_format_name, 'all', scores.score
FROM profile CROSS JOIN scores
WHERE EXISTS (SELECT 1 FROM quality_profiles qp WHERE qp.name = profile.name)
ON CONFLICT(quality_profile_name, custom_format_name, arr_type)
DO UPDATE SET score = excluded.score;
