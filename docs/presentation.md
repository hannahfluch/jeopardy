# Praesentation: Jeopardy PL/SQL Backend

## Showbeschreibung

Jeopardy ist eine Quizshow mit mehreren Kategorien und Fragen mit steigendem Punktewert.
Kandidaten buzzern, sobald sie die Antwort wissen. Nur die schnellste gueltige Person darf zuerst antworten.
Eine richtige Antwort bringt Punkte, eine falsche Antwort zieht Punkte ab und sperrt diese Person fuer die aktuelle Frage.

Diese Umsetzung verwendet zusaetzlich einen kleinen Joker pro Kandidat, damit die Projektanforderung
"Joker verwenden" abgedeckt ist: `J50` blendet zwei falsche Optionen aus.

## Use Cases

1. Spiel anlegen
   - Moderator erstellt ein neues Spiel.
   - System setzt Status auf `SETUP`.

2. Kandidaten anmelden
   - Kandidaten werden Sitzplaetzen zugeordnet.
   - Pro Spiel und Sitzplatz gibt es nur eine Person.
   - Jeder Kandidat erhaelt seine Joker.

3. Spiel starten
   - System prueft, ob mindestens zwei Kandidaten vorhanden sind.
   - Status wechselt auf `RUNNING`.
   - Trigger schreibt ein Status-Event.

4. Frage waehlen
   - Moderator waehlt eine noch nicht verwendete Frage.
   - System merkt die Frage als aktuell und entsperrt alle Kandidaten.

5. Buzz-in
   - Kandidaten buzzern mit Reaktionszeit in Millisekunden.
   - Function `fastest_candidate` liefert die schnellste gueltige Person.
   - Nur diese Person darf zuerst antworten.

6. Antwort verarbeiten
   - Richtige Antwort: Punkte werden addiert, Frage wird geschlossen.
   - Falsche Antwort: Punkte werden abgezogen, Kandidat wird fuer diese Frage gesperrt.
   - Trigger protokolliert jede Antwort.

7. Gewinnstufen/Point Levels verwalten
   - Tabelle `jq_point_level` definiert erlaubte Jeopardy-Werte je Runde.
   - Fragen referenzieren diese Tabelle per Foreign Key.
   - Dadurch kann die Punkte-Logik nicht mit ungueltigen Werten arbeiten.

8. Joker verwenden
   - Kandidat verwendet `J50`.
   - Function `joker_hint` gibt nur die richtige Option und eine falsche Option zurueck.
   - Joker kann pro Kandidat und Spiel nur einmal verwendet werden.

9. Spiel beenden
   - Status wird auf `FINISHED` gesetzt.
   - Sieger ist der Kandidat mit dem hoechsten Score.

## Muster-Spielverlauf

Das Skript `sql/05_demo.sql` fuehrt einen kurzen Ablauf vor:

1. Neues Spiel wird erstellt.
2. Drei Kandidaten werden angemeldet.
3. Spiel startet.
4. Erste Frage wird ausgewaehlt.
5. Mehrere Kandidaten buzzern.
6. Schnellster Kandidat antwortet falsch und verliert Punkte.
7. Naechster Kandidat buzzert und antwortet richtig.
8. Leaderboard und Event-Log werden angezeigt.
9. Eine zweite Frage demonstriert den `J50` Joker.

Fuer spontane Aenderungen in der Praesentation gibt es zusaetzlich `sql/06_live_demo.sql`.
Dieses Skript ist in einzelne normale SQL/PLSQL-Bloecke aufgeteilt. In den `declare`-Abschnitten
koennen Werte wie `l_question_id`, `l_candidate_name` und `l_selected_option` live geaendert
werden. Dadurch kann zB Antwort `C` statt `A` getestet werden, ohne das ganze Demo-Skript
umzubauen.

## Lokale Testumgebung

Die Datenbank laeuft fuer die Praesentation in einem Podman-Container mit Oracle Free.
DBeaver verbindet sich mit `localhost`, Port `1521`, Service `FREEPDB1`, User `jeopardy`
und Passwort `jeopardy`. Die SQL-Dateien werden direkt in DBeaver ausgefuehrt. Dadurch sind
DBMS-Output, Fehlermeldungen und spontane Aenderungen live sichtbar.

## Code-Deep-Dive: wichtigste Procedure

Empfohlen fuer die 4-Minuten-Erklaerung: `answer_question`.

Warum diese Procedure wichtig ist:

- Sie bildet die zentrale Spielregel ab.
- Sie prueft, ob ein Spiel laeuft und ob eine aktuelle Frage aktiv ist.
- Sie erzwingt "schnellste Antwort zaehlt".
- Sie berechnet Punkte positiv oder negativ.
- Sie sperrt Kandidaten nach falscher Antwort.
- Sie schliesst die Frage nach richtiger Antwort.

## Code-Deep-Dive: Trigger

Empfohlen: `trg_answer_audit`.

Was der Trigger macht:

- Reagiert automatisch auf jede neue Antwort.
- Schreibt ein Event in `jq_game_event`.
- Trennt Audit-Logging von der Spiellogik.

Warum das sinnvoll ist:

- Jede Antwort wird protokolliert, egal welcher Code sie einfuegt.
- Die Procedure bleibt lesbarer.
- Bei der Praesentation kann man leicht zeigen, dass Trigger ein Ereignis ausloesen.

## Troubleshooting-Ideen fuer die Praesentation

Moegliche spontane Aenderungen:

- Punktewert einer Frage aendern:
  ```sql
  update jq_question set point_value = 800 where question_id = 1;
  ```

- Neuen Kandidaten anmelden:
  ```sql
  declare
    l_candidate_id number;
  begin
    add_candidate(1, 'Dana', 4, l_candidate_id);
    dbms_output.put_line('Dana ID: ' || l_candidate_id);
  end;
  /
  ```

- Joker nochmal verwenden und Exception zeigen:
  ```sql
  begin
    use_joker(1, 1, 'J50');
  end;
  /
  ```

- Event-Log pruefen:
  ```sql
  select event_id, event_type, details, created_at
  from jq_game_event
  order by event_id;
  ```
