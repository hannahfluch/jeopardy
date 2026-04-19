/*
  Live demo for DBeaver.

  This file uses normal SQL statements and anonymous PL/SQL blocks.
  Run one block at a time. For teacher-requested changes, edit the small
  values in the declare section of the relevant block and run that block again.

  Enable DBMS Output in DBeaver before running the demo blocks.
*/

/* 1) Create a fresh live game. Run once. */
declare
  l_game_id number;
  l_alex_id number;
  l_ben_id number;
  l_chris_id number;
begin
  create_game('Live Jeopardy Demo', l_game_id);
  add_candidate(l_game_id, 'Live Alex', 1, l_alex_id);
  add_candidate(l_game_id, 'Live Ben', 2, l_ben_id);
  add_candidate(l_game_id, 'Live Chris', 3, l_chris_id);
  start_game(l_game_id);

  dbms_output.put_line('Game ID: ' || l_game_id);
  dbms_output.put_line('Alex ID: ' || l_alex_id);
  dbms_output.put_line('Ben ID: ' || l_ben_id);
  dbms_output.put_line('Chris ID: ' || l_chris_id);
  dbms_output.put_line('Leaderboard: ' || leaderboard(l_game_id));
end;

/* 2) Choose a question. Change l_question_id live if requested. */
declare
  l_game_id number;
  l_question_id number := 1;
begin
  select max(game_id)
  into l_game_id
  from jq_game
  where title = 'Live Jeopardy Demo';

  select_question(l_game_id, l_question_id);
  dbms_output.put_line(current_question(l_game_id));
end;

/* 3) Optional joker. Change l_candidate_name if requested. */
declare
  l_game_id number;
  l_candidate_id number;
  l_candidate_name varchar2(80) := 'Live Alex';
begin
  select max(game_id)
  into l_game_id
  from jq_game
  where title = 'Live Jeopardy Demo';

  select candidate_id
  into l_candidate_id
  from jq_candidate
  where display_name = l_candidate_name;

  use_joker(l_game_id, l_candidate_id, 'J50');
  dbms_output.put_line(joker_hint(l_game_id, l_candidate_id, 'J50'));
end;

/* 4) Buzz candidates. Lower reaction_ms wins. Change values live. */
declare
  l_game_id number;
  l_question_id number;
  l_alex_id number;
  l_ben_id number;
  l_chris_id number;
  l_alex_reaction_ms number := 410;
  l_ben_reaction_ms number := 350;
  l_chris_reaction_ms number := 520;
begin
  select max(game_id)
  into l_game_id
  from jq_game
  where title = 'Live Jeopardy Demo';

  select current_question_id
  into l_question_id
  from jq_game
  where game_id = l_game_id;

  select candidate_id
  into l_alex_id
  from jq_candidate
  where display_name = 'Live Alex';

  select candidate_id
  into l_ben_id
  from jq_candidate
  where display_name = 'Live Ben';

  select candidate_id
  into l_chris_id
  from jq_candidate
  where display_name = 'Live Chris';

  delete from jq_buzz
  where game_id = l_game_id
    and question_id = l_question_id;

  register_buzz(l_game_id, l_alex_id, l_alex_reaction_ms);
  register_buzz(l_game_id, l_ben_id, l_ben_reaction_ms);
  register_buzz(l_game_id, l_chris_id, l_chris_reaction_ms);

  dbms_output.put_line(
    'Fastest candidate ID: '
    || fastest_candidate(l_game_id, l_question_id)
  );
end;

/*
  5) Answer with any option.
  Change l_candidate_name and l_selected_option when the teacher says e.g. "answer C".
*/
declare
  l_game_id number;
  l_candidate_id number;
  l_candidate_name varchar2(80) := 'Live Ben';
  l_selected_option char(1) := 'A';
begin
  select max(game_id)
  into l_game_id
  from jq_game
  where title = 'Live Jeopardy Demo';

  select candidate_id
  into l_candidate_id
  from jq_candidate
  where display_name = l_candidate_name;

  answer_question(l_game_id, l_candidate_id, l_selected_option);
  dbms_output.put_line('Leaderboard: ' || leaderboard(l_game_id));
end;

/*
  6) If the first answer was wrong, let the next fastest valid candidate answer.
  This block is expected to print an error if the previous answer was already correct.
*/
declare
  l_game_id number;
  l_candidate_id number;
  l_candidate_name varchar2(80) := 'Live Alex';
  l_selected_option char(1) := 'A';
begin
  select max(game_id)
  into l_game_id
  from jq_game
  where title = 'Live Jeopardy Demo';

  select candidate_id
  into l_candidate_id
  from jq_candidate
  where display_name = l_candidate_name;

  answer_question(l_game_id, l_candidate_id, l_selected_option);
  dbms_output.put_line('Leaderboard: ' || leaderboard(l_game_id));
exception
  when others then
    dbms_output.put_line('No follow-up answer needed/allowed: ' || sqlerrm);
end;

/* 7) Show scoreboard. */
select c.display_name, gc.score
from jq_game_candidate gc
join jq_candidate c on c.candidate_id = gc.candidate_id
where gc.game_id = (
  select max(game_id)
  from jq_game
  where title = 'Live Jeopardy Demo'
)
order by gc.score desc, c.display_name;

/* 8) Show event log. */
select event_id, event_type, details, created_at
from jq_game_event
where game_id = (
  select max(game_id)
  from jq_game
  where title = 'Live Jeopardy Demo'
)
order by event_id;

/*
  For another live round:
  - Edit l_question_id in block 2 to an unused question, for example 2.
  - Run block 2.
  - Optionally run block 3.
  - Run block 4.
  - Edit and run block 5.
  - Run blocks 7 and 8 to show the result.
*/
