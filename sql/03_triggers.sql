create or replace trigger trg_game_status_audit
after update of status on jq_game
for each row
when (old.status <> new.status)
begin
  insert into jq_game_event (game_id, event_type, details)
  values (
    :new.game_id,
    'GAME_STATUS',
    'Status changed from ' || :old.status || ' to ' || :new.status
  );
end;

create or replace trigger trg_answer_audit
after insert on jq_answer
for each row
begin
  insert into jq_game_event (game_id, event_type, details)
  values (
    :new.game_id,
    'ANSWER',
    'Candidate ' || :new.candidate_id
      || ' answered question ' || :new.question_id
      || ' with ' || :new.selected_option
      || ', correct=' || :new.is_correct
      || ', delta=' || :new.score_delta
  );
end;

create or replace trigger trg_question_clean_text
before insert or update on jq_question
for each row
begin
  :new.correct_option := upper(trim(:new.correct_option));
  :new.is_daily_double := upper(trim(:new.is_daily_double));

  if :new.clue_text != trim(:new.clue_text) then
    :new.clue_text := trim(:new.clue_text);
  end if;

  if :new.point_value >= 600 and :new.round_no = 1 then
    raise_application_error(-20020, 'Round 1 questions may not exceed 500 points.');
  end if;
end;

create or replace trigger trg_buzz_guard
before insert on jq_buzz
for each row
declare
  l_status jq_game.status%type;
  l_current_question_id jq_game.current_question_id%type;
  l_locked_out jq_game_candidate.locked_out%type;
begin
  select g.status, g.current_question_id, gc.locked_out
  into l_status, l_current_question_id, l_locked_out
  from jq_game g
  join jq_game_candidate gc on gc.game_id = g.game_id
  where g.game_id = :new.game_id
    and gc.candidate_id = :new.candidate_id;

  if l_status != 'RUNNING' then
    raise_application_error(-20021, 'Buzz is only allowed while the game is running.');
  end if;

  if l_current_question_id is null or l_current_question_id != :new.question_id then
    raise_application_error(-20022, 'Buzz must target the current question.');
  end if;

  if l_locked_out = 'Y' then
    raise_application_error(-20023, 'Candidate is locked out for this question.');
  end if;
end;
