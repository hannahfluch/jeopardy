create or replace procedure jq_log_event(
  p_game_id in number,
  p_event_type in varchar2,
  p_details in varchar2
) is
begin
  insert into jq_game_event (game_id, event_type, details)
  values (p_game_id, p_event_type, p_details);
end;

create or replace procedure jq_require_running(p_game_id in number) is
  l_status jq_game.status%type;
begin
  select status
  into l_status
  from jq_game
  where game_id = p_game_id;

  if l_status != 'RUNNING' then
    raise_application_error(-20001, 'Game is not running.');
  end if;
exception
  when no_data_found then
    raise_application_error(-20002, 'Game does not exist.');
end;

create or replace function jq_current_question_id(
  p_game_id in number
) return number is
  l_question_id jq_game.current_question_id%type;
begin
  select current_question_id
  into l_question_id
  from jq_game
  where game_id = p_game_id;

  if l_question_id is null then
    raise_application_error(-20002, 'No active question selected.');
  end if;

  return l_question_id;
end;

create or replace procedure create_game(
  p_title in varchar2,
  o_game_id out number
) is
begin
  insert into jq_game (title)
  values (trim(p_title))
  returning game_id into o_game_id;

  jq_log_event(o_game_id, 'GAME_CREATED', 'Created game "' || trim(p_title) || '".');
end;

create or replace procedure add_candidate(
  p_game_id in number,
  p_display_name in varchar2,
  p_seat_no in number,
  o_candidate_id out number
) is
  l_status jq_game.status%type;
begin
  select status
  into l_status
  from jq_game
  where game_id = p_game_id;

  if l_status != 'SETUP' then
    raise_application_error(-20002, 'Candidates can only be added while the game is in SETUP.');
  end if;

  begin
    insert into jq_candidate (display_name)
    values (trim(p_display_name))
    returning candidate_id into o_candidate_id;
  exception
    when dup_val_on_index then
      select candidate_id
      into o_candidate_id
      from jq_candidate
      where display_name = trim(p_display_name);
  end;

  insert into jq_game_candidate (game_id, candidate_id, seat_no)
  values (p_game_id, o_candidate_id, p_seat_no);

  insert into jq_candidate_joker (game_id, candidate_id, joker_code)
  select p_game_id, o_candidate_id, joker_code
  from jq_joker_type;

  jq_log_event(
    p_game_id,
    'CANDIDATE_ADDED',
    'Candidate ' || trim(p_display_name) || ' joined on seat ' || p_seat_no || '.'
  );
exception
  when no_data_found then
    raise_application_error(-20002, 'Game does not exist.');
end;

create or replace procedure start_game(p_game_id in number) is
  l_candidates number;
  l_questions number;
begin
  select count(*)
  into l_candidates
  from jq_game_candidate
  where game_id = p_game_id;

  select count(*)
  into l_questions
  from jq_question
  where used_in_game_id is null;

  if l_candidates < 2 then
    raise_application_error(-20002, 'At least two candidates are required.');
  end if;

  if l_questions = 0 then
    raise_application_error(-20002, 'No unused questions available.');
  end if;

  update jq_game
  set status = 'RUNNING',
      started_at = coalesce(started_at, localtimestamp)
  where game_id = p_game_id
    and status = 'SETUP';

  if sql%rowcount = 0 then
    raise_application_error(-20002, 'Game must be in SETUP before it can start.');
  end if;
end;

create or replace procedure select_question(
  p_game_id in number,
  p_question_id in number
) is
  l_used_game_id jq_question.used_in_game_id%type;
  l_current_question_id jq_game.current_question_id%type;
begin
  jq_require_running(p_game_id);

  select current_question_id
  into l_current_question_id
  from jq_game
  where game_id = p_game_id;

  if l_current_question_id is not null then
    raise_application_error(-20002, 'Finish the active question before selecting a new one.');
  end if;

  select used_in_game_id
  into l_used_game_id
  from jq_question
  where question_id = p_question_id;

  if l_used_game_id is not null then
    raise_application_error(-20002, 'Question has already been used.');
  end if;

  update jq_question
  set used_in_game_id = p_game_id
  where question_id = p_question_id;

  update jq_game
  set current_question_id = p_question_id
  where game_id = p_game_id;

  update jq_game_candidate
  set locked_out = 'N'
  where game_id = p_game_id;

  jq_log_event(p_game_id, 'QUESTION_SELECTED', 'Question ' || p_question_id || ' is now active.');
exception
  when no_data_found then
    raise_application_error(-20002, 'Question does not exist.');
end;

create or replace procedure register_buzz(
  p_game_id in number,
  p_candidate_id in number,
  p_reaction_ms in number
) is
  l_question_id number;
begin
  jq_require_running(p_game_id);
  l_question_id := jq_current_question_id(p_game_id);

  insert into jq_buzz (game_id, question_id, candidate_id, reaction_ms)
  values (p_game_id, l_question_id, p_candidate_id, p_reaction_ms);

  jq_log_event(
    p_game_id,
    'BUZZ',
    'Candidate ' || p_candidate_id || ' buzzed after ' || p_reaction_ms || ' ms.'
  );
exception
  when dup_val_on_index then
    raise_application_error(-20002, 'Candidate already buzzed for this question.');
end;

create or replace function fastest_candidate(
  p_game_id in number,
  p_question_id in number
) return number is
  l_candidate_id jq_buzz.candidate_id%type;
begin
  select candidate_id
  into l_candidate_id
  from (
    select candidate_id
    from jq_buzz
    where game_id = p_game_id
      and question_id = p_question_id
      and is_valid = 'Y'
    order by reaction_ms, buzzed_at, buzz_id
  )
  where rownum = 1;

  return l_candidate_id;
exception
  when no_data_found then
    return null;
end;

create or replace procedure use_joker(
  p_game_id in number,
  p_candidate_id in number,
  p_joker_code in varchar2
) is
  l_question_id number;
begin
  jq_require_running(p_game_id);
  l_question_id := jq_current_question_id(p_game_id);

  update jq_candidate_joker
  set used_on_question_id = l_question_id,
      used_at = localtimestamp
  where game_id = p_game_id
    and candidate_id = p_candidate_id
    and joker_code = upper(trim(p_joker_code))
    and used_at is null;

  if sql%rowcount = 0 then
    raise_application_error(-20004, 'Joker is unknown or already used.');
  end if;

  jq_log_event(
    p_game_id,
    'JOKER_USED',
    'Candidate ' || p_candidate_id || ' used joker ' || upper(trim(p_joker_code))
      || ' on question ' || l_question_id || '.'
  );
end;

create or replace procedure answer_question(
  p_game_id in number,
  p_candidate_id in number,
  p_selected_option in char
) is
  l_question_id number;
  l_fastest_candidate_id number;
  l_correct_option jq_question.correct_option%type;
  l_point_value jq_question.point_value%type;
  l_is_correct char(1);
  l_delta number;
  l_open_candidates number;
begin
  jq_require_running(p_game_id);
  l_question_id := jq_current_question_id(p_game_id);
  l_fastest_candidate_id := fastest_candidate(p_game_id, l_question_id);

  if l_fastest_candidate_id is null then
    raise_application_error(-20002, 'No candidate buzzed for this question.');
  end if;

  if l_fastest_candidate_id != p_candidate_id then
    raise_application_error(-20003, 'Only the fastest valid buzz may answer now.');
  end if;

  select correct_option, point_value
  into l_correct_option, l_point_value
  from jq_question
  where question_id = l_question_id;

  if upper(trim(p_selected_option)) = l_correct_option then
    l_is_correct := 'Y';
    l_delta := l_point_value;
  else
    l_is_correct := 'N';
    l_delta := -l_point_value;
  end if;

  update jq_game_candidate
  set score = score + l_delta,
      locked_out = case when l_is_correct = 'Y' then locked_out else 'Y' end
  where game_id = p_game_id
    and candidate_id = p_candidate_id;

  if sql%rowcount = 0 then
    raise_application_error(-20002, 'Candidate is not part of this game.');
  end if;

  insert into jq_answer (
    game_id,
    question_id,
    candidate_id,
    selected_option,
    is_correct,
    score_delta
  ) values (
    p_game_id,
    l_question_id,
    p_candidate_id,
    upper(trim(p_selected_option)),
    l_is_correct,
    l_delta
  );

  if l_is_correct = 'Y' then
    update jq_game
    set current_question_id = null
    where game_id = p_game_id;
  else
    update jq_buzz
    set is_valid = 'N'
    where game_id = p_game_id
      and question_id = l_question_id
      and candidate_id = p_candidate_id;

    select count(*)
    into l_open_candidates
    from jq_game_candidate gc
    where gc.game_id = p_game_id
      and gc.locked_out = 'N'
      and not exists (
        select 1
        from jq_buzz b
        where b.game_id = gc.game_id
          and b.question_id = l_question_id
          and b.candidate_id = gc.candidate_id
          and b.is_valid = 'N'
      );

    if l_open_candidates = 0 then
      update jq_game
      set current_question_id = null
      where game_id = p_game_id;
    end if;
  end if;
exception
  when dup_val_on_index then
    raise_application_error(-20002, 'Candidate already answered this question.');
end;

create or replace procedure finish_game(p_game_id in number) is
begin
  update jq_game
  set status = 'FINISHED',
      current_question_id = null,
      finished_at = localtimestamp
  where game_id = p_game_id
    and status = 'RUNNING';

  if sql%rowcount = 0 then
    raise_application_error(-20002, 'Only a running game can be finished.');
  end if;
end;

create or replace function get_score(
  p_game_id in number,
  p_candidate_id in number
) return number is
  l_score jq_game_candidate.score%type;
begin
  select score
  into l_score
  from jq_game_candidate
  where game_id = p_game_id
    and candidate_id = p_candidate_id;

  return l_score;
exception
  when no_data_found then
    return null;
end;

create or replace function current_question(
  p_game_id in number
) return varchar2 is
  l_text varchar2(1000);
begin
  select c.category_name || ' fuer ' || q.point_value || ': ' || q.clue_text
  into l_text
  from jq_game g
  join jq_question q on q.question_id = g.current_question_id
  join jq_category c on c.category_id = q.category_id
  where g.game_id = p_game_id;

  return l_text;
exception
  when no_data_found then
    return 'No active question.';
end;

create or replace function joker_hint(
  p_game_id in number,
  p_candidate_id in number,
  p_joker_code in varchar2
) return varchar2 is
  l_question_id number;
  l_correct jq_question.correct_option%type;
  l_wrong char(1);
  l_used number;
begin
  l_question_id := jq_current_question_id(p_game_id);

  select count(*)
  into l_used
  from jq_candidate_joker
  where game_id = p_game_id
    and candidate_id = p_candidate_id
    and joker_code = upper(trim(p_joker_code))
    and used_on_question_id = l_question_id;

  if l_used = 0 then
    return 'Joker was not used for the current question.';
  end if;

  select correct_option
  into l_correct
  from jq_question
  where question_id = l_question_id;

  l_wrong := case l_correct
    when 'A' then 'B'
    when 'B' then 'A'
    when 'C' then 'A'
    else 'A'
  end;

  return 'Remaining options after ' || upper(trim(p_joker_code)) || ': '
    || l_correct || ' and ' || l_wrong || '.';
end;

create or replace function leaderboard(
  p_game_id in number
) return varchar2 is
  l_board varchar2(4000);
begin
  for r in (
    select c.display_name, gc.score
    from jq_game_candidate gc
    join jq_candidate c on c.candidate_id = gc.candidate_id
    where gc.game_id = p_game_id
    order by gc.score desc, c.display_name
  ) loop
    l_board := l_board || r.display_name || ': ' || r.score || ' | ';
  end loop;

  return rtrim(l_board, ' | ');
end;
