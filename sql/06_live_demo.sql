/*
  Live demo for DBeaver.

  This file uses normal SQL statements and anonymous PL/SQL blocks.
  Run one block at a time.  For teacher-requested changes, edit the small
  values in the declare section of the relevant block and re-run that block.

  Enable DBMS Output in DBeaver before running the demo blocks.
*/

/* ============================================================
   1) Create a fresh live game.  Run once.
   ============================================================ */
declare
  l_game_id  number;
  l_alex_id  number;
  l_ben_id   number;
  l_chris_id number;
begin
  dbms_output.put_line('Demo 1');
  create_game('Live Jeopardy Demo', l_game_id);
  add_candidate(l_game_id, 'Live Alex',  1, l_alex_id);
  add_candidate(l_game_id, 'Live Ben',   2, l_ben_id);
  add_candidate(l_game_id, 'Live Chris', 3, l_chris_id);
  start_game(l_game_id);

  dbms_output.put_line('Game ID: '     || l_game_id);
  dbms_output.put_line('Alex ID: '     || l_alex_id);
  dbms_output.put_line('Ben ID: '      || l_ben_id);
  dbms_output.put_line('Chris ID: '    || l_chris_id);
  dbms_output.put_line('Leaderboard: ' || leaderboard(l_game_id));
end;

/* ============================================================
   2) Choose a question.  Change l_question_id live if requested.
   ============================================================ */
declare
  l_game_id     number;
  l_question_id number := 2;   -- << change this for each new question
  l_option_a    jq_question.option_a%type;
  l_option_b    jq_question.option_b%type;
  l_option_c    jq_question.option_c%type;
  l_option_d    jq_question.option_d%type;
begin
  dbms_output.put_line('Demo 2');
  select max(game_id)
  into   l_game_id
  from   jq_game
  where  title = 'Live Jeopardy Demo';

  select_question(l_game_id, l_question_id);
  dbms_output.put_line(current_question(l_game_id));

  select option_a, option_b, option_c, option_d
  into   l_option_a, l_option_b, l_option_c, l_option_d
  from   jq_question
  where  question_id = l_question_id;

  dbms_output.put_line('A: ' || l_option_a);
  dbms_output.put_line('B: ' || l_option_b);
  dbms_output.put_line('C: ' || l_option_c);
  dbms_output.put_line('D: ' || l_option_d);
end;

/* ============================================================
   3) Optional joker.  Change l_candidate_name if requested.
   ============================================================ */
declare
  l_game_id        number;
  l_candidate_id   number;
  l_candidate_name varchar2(80) := 'Live Alex';   -- << change if needed
begin
  dbms_output.put_line('Demo 3');
  select max(game_id)
  into   l_game_id
  from   jq_game
  where  title = 'Live Jeopardy Demo';

  select candidate_id
  into   l_candidate_id
  from   jq_candidate
  where  display_name = l_candidate_name;

  use_joker(l_game_id, l_candidate_id, 'J50');
  dbms_output.put_line(joker_hint(l_game_id, l_candidate_id, 'J50'));
end;

/* ============================================================
   4) Buzz candidates.  Lower reaction_ms wins.  Change values live.
      Existing buzzes for this question are cleared first so the
      block is safely re-runnable during the demo.
   ============================================================ */
declare
  l_game_id           number;
  l_question_id       number;
  l_alex_id           number;
  l_ben_id            number;
  l_chris_id          number;
  l_alex_reaction_ms  number := 410;   -- << change live
  l_ben_reaction_ms   number := 350;
  l_chris_reaction_ms number := 520;
begin
  dbms_output.put_line('Demo 4');
  select max(game_id)
  into   l_game_id
  from   jq_game
  where  title = 'Live Jeopardy Demo';

  select current_question_id
  into   l_question_id
  from   jq_game
  where  game_id = l_game_id;

  select candidate_id into l_alex_id  from jq_candidate where display_name = 'Live Alex';
  select candidate_id into l_ben_id   from jq_candidate where display_name = 'Live Ben';
  select candidate_id into l_chris_id from jq_candidate where display_name = 'Live Chris';

  -- clear previous buzzes so this block can be re-run during the demo
  delete from jq_buzz
  where  game_id     = l_game_id
    and  question_id = l_question_id;

  register_buzz(l_game_id, l_alex_id,  l_alex_reaction_ms);
  register_buzz(l_game_id, l_ben_id,   l_ben_reaction_ms);
  register_buzz(l_game_id, l_chris_id, l_chris_reaction_ms);

  dbms_output.put_line(
    'Fastest candidate ID: ' || fastest_candidate(l_game_id, l_question_id)
  );
end;

/* ============================================================
   5) First answer attempt.
      Change l_candidate_name and l_selected_option when the
      teacher says e.g. "answer C".
      Default answer for question 1 is correct (A = PL/SQL).
   ============================================================ */
declare
  l_game_id         number;
  l_candidate_id    number;
  l_candidate_name  varchar2(80) := 'Live Ben';   -- << fastest buzzer above
  l_selected_option char(1)      := 'A';          -- << correct for question 1
begin
  dbms_output.put_line('Demo 5');
  select max(game_id)
  into   l_game_id
  from   jq_game
  where  title = 'Live Jeopardy Demo';

  select candidate_id
  into   l_candidate_id
  from   jq_candidate
  where  display_name = l_candidate_name;

  answer_question(l_game_id, l_candidate_id, l_selected_option);
  dbms_output.put_line('Leaderboard: ' || leaderboard(l_game_id));
end;

/* ============================================================
   6) Follow-up answer after a wrong first attempt.
      Only relevant if block 5 answered incorrectly.
      Prints an error and continues gracefully if not needed.
   ============================================================ */
declare
  l_game_id         number;
  l_candidate_id    number;
  l_candidate_name  varchar2(80) := 'Live Alex';   -- << next fastest buzzer
  l_selected_option char(1)      := 'A';
begin
  dbms_output.put_line('Demo 6');
  select max(game_id)
  into   l_game_id
  from   jq_game
  where  title = 'Live Jeopardy Demo';

  select candidate_id
  into   l_candidate_id
  from   jq_candidate
  where  display_name = l_candidate_name;

  answer_question(l_game_id, l_candidate_id, l_selected_option);
  dbms_output.put_line('Leaderboard: ' || leaderboard(l_game_id));
exception
  when others then
    dbms_output.put_line('No follow-up answer needed/allowed: ' || sqlerrm);
end;

/* ============================================================
   7) Question 2 — demonstrates the wrong-answer + lockout flow.
      Run block 2 first with l_question_id = 2, then let players try to answer via buzzer, then come here.

      Question: "Dieses Constraint verhindert doppelte Werte in einer Spalte."
        A = Foreign Key   (wrong)
        B = Unique        (CORRECT)
        C = Check         (wrong)
        D = Not Null      (wrong)

      The fastest buzzer defaults to answering A (wrong) so the class
      can see the lockout and score deduction before the next candidate
      picks it up correctly with B.
   ============================================================ */

/* 7a) First wrong attempt — fastest buzzer answers incorrectly. */
declare
  l_game_id         number;
  l_candidate_id    number;
  l_candidate_name  varchar2(80) := 'Live Ben';   -- << fastest buzzer for q2
  l_selected_option char(1)      := 'A';          -- << deliberately wrong
begin
  dbms_output.put_line('Demo 7a - wrong answer');
  select max(game_id)
  into   l_game_id
  from   jq_game
  where  title = 'Live Jeopardy Demo';

  select candidate_id
  into   l_candidate_id
  from   jq_candidate
  where  display_name = l_candidate_name;

  answer_question(l_game_id, l_candidate_id, l_selected_option);
  dbms_output.put_line('Score after wrong answer: ' || leaderboard(l_game_id));
  dbms_output.put_line('(Live Ben is now locked out — next fastest may answer)');
end;

/* 7b) Correct follow-up — second candidate answers correctly. */
declare
  l_game_id         number;
  l_candidate_id    number;
  l_candidate_name  varchar2(80) := 'Live Alex';  -- << second fastest buzzer
  l_selected_option char(1)      := 'B';          -- << correct answer
begin
  dbms_output.put_line('Demo 7b - correct answer');
  select max(game_id)
  into   l_game_id
  from   jq_game
  where  title = 'Live Jeopardy Demo';

  select candidate_id
  into   l_candidate_id
  from   jq_candidate
  where  display_name = l_candidate_name;

  answer_question(l_game_id, l_candidate_id, l_selected_option);
  dbms_output.put_line('Leaderboard after correct answer: ' || leaderboard(l_game_id));
end;

/* ============================================================
   8) Show scoreboard.
   ============================================================ */
select c.display_name, gc.score
from   jq_game_candidate gc
join   jq_candidate c on c.candidate_id = gc.candidate_id
where  gc.game_id = (
  select max(game_id) from jq_game where title = 'Live Jeopardy Demo'
)
order  by gc.score desc, c.display_name;

/* ============================================================
   9) Show event log.
   ============================================================ */
select event_id, event_type, details, created_at
from   jq_game_event
where  game_id = (
  select max(game_id) from jq_game where title = 'Live Jeopardy Demo'
)
order  by event_id;

/*
  Full demo flow:
    Block 1  — create game and candidates
    Block 2  — select question 1 (l_question_id := 1)
    Block 3  — optional joker (skip if not needed)
    Block 4  — buzz all three candidates
    Block 5  — fastest answers correctly (question 1 closes)
    Block 2  — select question 2 (change l_question_id := 2, re-run)
    Block 4  — buzz again (adjust reaction times)
    Block 7a — fastest answers wrong → lockout + score deduction shown
    Block 7b — second candidate answers correctly → question closes
    Block 8  — final scoreboard
    Block 9  — full event log
*/
