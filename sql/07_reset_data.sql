-- ---------------------------------------------------------------------------
-- Full reset: purges all data.
-- ---------------------------------------------------------------------------

-- purge data in reverse dependency order (04, 05, 06)
delete from jq_answer;
delete from jq_buzz;
delete from jq_candidate_joker;
delete from jq_game_event;
delete from jq_game_candidate;

-- clear the FK from jq_question back to jq_game before deleting games
update jq_question set used_in_game_id = null;

-- clear the FK from jq_game to the current question before deleting questions
update jq_game set current_question_id = null;

delete from jq_question;
delete from jq_point_level;
delete from jq_category;
delete from jq_candidate;
delete from jq_joker_type;
delete from jq_game;
