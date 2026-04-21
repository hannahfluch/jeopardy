
-- drop triggers (03)
drop trigger trg_game_status_audit;
drop trigger trg_answer_audit;
drop trigger trg_question_clean_text;
drop trigger trg_buzz_guard;

-- drop routines (02)
drop procedure jq_log_event;
drop procedure jq_require_running;
drop function jq_current_question_id;
drop procedure create_game;
drop procedure add_candidate;
drop procedure start_game;
drop procedure select_question;
drop procedure register_buzz;
drop function fastest_candidate;
drop procedure use_joker;
drop procedure answer_question;
drop procedure finish_game;
drop function get_score;
drop function current_question;
drop function joker_hint;
drop function leaderboard;

-- clear all data (04, 05, 06)
delete from jq_answer;
delete from jq_buzz;
delete from jq_candidate_joker;
delete from jq_game_event;
delete from jq_game_candidate;
-- break FK from jq_question → jq_game
update jq_question set used_in_game_id = null;
delete from jq_question;
delete from jq_point_level;
delete from jq_category;
delete from jq_candidate;
delete from jq_joker_type;
delete from jq_game;
