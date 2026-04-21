-- ---------------------------------------------------------------------------
-- Joker types
-- ---------------------------------------------------------------------------
insert into jq_joker_type (joker_code, description)
values ('J50', 'Fifty-fifty: keep the correct option and one wrong option.');

-- ---------------------------------------------------------------------------
-- Categories
-- ---------------------------------------------------------------------------
insert into jq_category (category_id, category_name) values (1, 'Datenbanken');
insert into jq_category (category_id, category_name) values (2, 'PLSQL');
insert into jq_category (category_id, category_name) values (3, 'Popkultur');


-- ---------------------------------------------------------------------------
-- Point levels
--   Round 1: 100 – 500
--   Round 2: 200 – 1000
-- ---------------------------------------------------------------------------
insert into jq_point_level (round_no, point_value, level_label) values (1, 100,  'Round 1 - 100');
insert into jq_point_level (round_no, point_value, level_label) values (1, 200,  'Round 1 - 200');
insert into jq_point_level (round_no, point_value, level_label) values (1, 300,  'Round 1 - 300');
insert into jq_point_level (round_no, point_value, level_label) values (1, 400,  'Round 1 - 400');
insert into jq_point_level (round_no, point_value, level_label) values (1, 500,  'Round 1 - 500');
insert into jq_point_level (round_no, point_value, level_label) values (2, 200,  'Round 2 - 200');
insert into jq_point_level (round_no, point_value, level_label) values (2, 400,  'Round 2 - 400');
insert into jq_point_level (round_no, point_value, level_label) values (2, 600,  'Round 2 - 600');
insert into jq_point_level (round_no, point_value, level_label) values (2, 800,  'Round 2 - 800');
insert into jq_point_level (round_no, point_value, level_label) values (2, 1000, 'Round 2 - 1000');

-- ---------------------------------------------------------------------------
-- Questions
-- ---------------------------------------------------------------------------
insert into jq_question (
  question_id, category_id, clue_text,
  option_a, option_b, option_c, option_d,
  correct_option, point_value, round_no
) values (
  1,
  1,
  'Diese Sprache wird in Oracle fuer gespeicherte Prozeduren verwendet.',
  'PL/SQL', 'HTML', 'CSS', 'Bash',
  'A', 100, 1
);

insert into jq_question (
  question_id, category_id, clue_text,
  option_a, option_b, option_c, option_d,
  correct_option, point_value, round_no
) values (
  2,
  1,
  'Dieses Constraint verhindert doppelte Werte in einer Spalte.',
  'Foreign Key', 'Unique', 'Check', 'Not Null',
  'B', 200, 1
);

insert into jq_question (
  question_id, category_id, clue_text,
  option_a, option_b, option_c, option_d,
  correct_option, point_value, round_no
) values (
  3, 
  2,
  'Dieses PL/SQL-Konstrukt reagiert automatisch auf Insert, Update oder Delete.',
  'Cursor', 'View', 'Trigger', 'Synonym',
  'C', 100, 1
);

insert into jq_question (
  question_id, category_id, clue_text,
  option_a, option_b, option_c, option_d,
  correct_option, point_value, round_no
) values (
  4,
  2,
  'Diese Anweisung wirft in PL/SQL einen eigenen Fehler mit Fehlernummer.',
  'raise_application_error', 'dbms_output.put_line', 'commit', 'select into',
  'A', 200, 1
);

insert into jq_question (
  question_id, category_id, clue_text,
  option_a, option_b, option_c, option_d,
  correct_option, point_value, round_no
) values (
  5,
  3,
  'Diese Quizshow verlangt Antworten oft in Form einer Frage.',
  'Wheel of Fortune', 'Jeopardy', 'The Voice', 'Wipeout',
  'B', 100, 1
);
