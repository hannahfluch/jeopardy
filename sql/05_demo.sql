declare
  l_game_id number;
  l_alex_id number;
  l_ben_id number;
  l_chris_id number;
begin
  create_game('Classroom Jeopardy', l_game_id);
  add_candidate(l_game_id, 'Alex', 1, l_alex_id);
  add_candidate(l_game_id, 'Ben', 2, l_ben_id);
  add_candidate(l_game_id, 'Chris', 3, l_chris_id);
  start_game(l_game_id);

  dbms_output.put_line('Game ID: ' || l_game_id);
  dbms_output.put_line('Candidates: Alex=' || l_alex_id || ', Ben=' || l_ben_id || ', Chris=' || l_chris_id);

  select_question(l_game_id, 1);
  dbms_output.put_line(current_question(l_game_id));

  register_buzz(l_game_id, l_ben_id, 430);
  register_buzz(l_game_id, l_alex_id, 390);
  dbms_output.put_line('Fastest candidate: ' || fastest_candidate(l_game_id, 1));

  begin
    answer_question(l_game_id, l_ben_id, 'A');
  exception
    when others then
      dbms_output.put_line('Expected fastest-buzz rule: ' || sqlerrm);
  end;

  answer_question(l_game_id, l_alex_id, 'D');
  dbms_output.put_line('After wrong answer: ' || leaderboard(l_game_id));

  answer_question(l_game_id, l_ben_id, 'A');
  dbms_output.put_line('After correct answer: ' || leaderboard(l_game_id));

  select_question(l_game_id, 2);
  dbms_output.put_line(current_question(l_game_id));
  use_joker(l_game_id, l_chris_id, 'J50');
  dbms_output.put_line(joker_hint(l_game_id, l_chris_id, 'J50'));
  register_buzz(l_game_id, l_chris_id, 270);
  answer_question(l_game_id, l_chris_id, 'B');

  dbms_output.put_line('Final leaderboard: ' || leaderboard(l_game_id));
  finish_game(l_game_id);
end;

select event_id, event_type, details
from jq_game_event
order by event_id;

select c.display_name, gc.score
from jq_game_candidate gc
join jq_candidate c on c.candidate_id = gc.candidate_id
order by gc.score desc, c.display_name;

commit;
