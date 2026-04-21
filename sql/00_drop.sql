-- drop triggers
drop trigger trg_buzz_guard;
drop trigger trg_question_clean_text;
drop trigger trg_answer_audit;
drop trigger trg_game_status_audit;

-- drop routines
drop procedure jq_log_event;
drop procedure jq_require_running;
drop function  jq_current_question_id;
drop procedure create_game;
drop procedure add_candidate;
drop procedure start_game;
drop procedure select_question;
drop procedure register_buzz;
drop function  fastest_candidate;
drop procedure use_joker;
drop procedure answer_question;
drop procedure finish_game;
drop function  get_score;
drop function  current_question;
drop function  joker_hint;
drop function  leaderboard;

-- drop tables (reverse dependency order)
drop table jq_game_event      cascade constraints;
drop table jq_answer          cascade constraints;
drop table jq_buzz            cascade constraints;
drop table jq_candidate_joker cascade constraints;
drop table jq_joker_type      cascade constraints;
drop table jq_question        cascade constraints;
drop table jq_point_level     cascade constraints;
drop table jq_category        cascade constraints;
drop table jq_game_candidate  cascade constraints;
drop table jq_candidate       cascade constraints;
drop table jq_game            cascade constraints;
