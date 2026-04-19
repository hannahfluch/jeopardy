begin
  for r in (
    select object_name, object_type
    from user_objects
    where object_type in ('FUNCTION', 'PROCEDURE')
      and object_name in (
        'ADD_CANDIDATE',
        'ANSWER_QUESTION',
        'CREATE_GAME',
        'CURRENT_QUESTION',
        'FASTEST_CANDIDATE',
        'FINISH_GAME',
        'GET_SCORE',
        'JOKER_HINT',
        'JQ_CURRENT_QUESTION_ID',
        'JQ_LOG_EVENT',
        'JQ_REQUIRE_RUNNING',
        'LEADERBOARD',
        'REGISTER_BUZZ',
        'SELECT_QUESTION',
        'START_GAME',
        'USE_JOKER'
      )
  ) loop
    execute immediate 'drop ' || r.object_type || ' ' || r.object_name;
  end loop;

  for r in (
    select table_name
    from user_tables
    where table_name in (
      'JQ_GAME_EVENT',
      'JQ_ANSWER',
      'JQ_BUZZ',
      'JQ_CANDIDATE_JOKER',
      'JQ_JOKER_TYPE',
      'JQ_QUESTION',
      'JQ_POINT_LEVEL',
      'JQ_CATEGORY',
      'JQ_GAME_CANDIDATE',
      'JQ_CANDIDATE',
      'JQ_GAME'
    )
  ) loop
    execute immediate 'drop table ' || r.table_name || ' cascade constraints purge';
  end loop;
end;
