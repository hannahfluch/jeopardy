# Jeopardy PL/SQL Backend

Dieses Projekt implementiert ein Oracle PL/SQL Backend fuer eine TV-Quizshow im Stil von **Jeopardy**.
Der Fokus liegt auf sauberer Tabellenmodellierung, einfachen Procedures/Functions, Triggern fuer Logging/Validierung
und einem kurzen Demo-Spielverlauf fuer die Praesentation.

## Dateien

- `Dockerfile` - Oracle Free Image fuer lokale Tests
- `compose.yaml` - Podman Compose Setup mit Portfreigabe fuer DBeaver
- `sql/00_drop.sql` - entfernt alle Projektobjekte in sinnvoller Reihenfolge
- `sql/01_schema.sql` - DDL fuer Tabellen, Constraints, Checks, Foreign Keys und Unique Constraints
- `sql/02_routines.sql` - Spiellogik mit standalone Procedures und Functions
- `sql/03_triggers.sql` - Trigger fuer Logging und Datenregeln
- `sql/04_seed.sql` - Stammdaten und Beispiel-Fragen
- `sql/05_demo.sql` - kurzer Standard-Spielverlauf zum Vorzeigen
- `sql/06_live_demo.sql` - interaktiver Demo-Ablauf mit editierbaren Variablen
- `docs/presentation.md` - Use Cases, Demo-Ablauf und Code-Deep-Dive Notizen

## Ausfuehren

### Podman / Oracle Container

Zum lokalen Testen mit DBeaver kann eine Oracle Free Datenbank per Podman gestartet werden.
Beim ersten Start wird automatisch ein Schema `JEOPARDY` erstellt. Die Projekt-Skripte werden
danach in DBeaver ausgefuehrt, damit Ablauf, Fehler und spontane Aenderungen sichtbar bleiben.

```sh
podman compose up --build -d
```

Logs ansehen, bis `DATABASE IS READY TO USE` erscheint:

```sh
podman compose logs -f oracle
```

DBeaver-Verbindung:

- Driver: Oracle
- Host: `localhost`
- Port: `1521`
- Service name: `FREEPDB1`
- Username: `jeopardy`
- Password: `jeopardy`
- SYS/SYSTEM Passwort fuer Admin-Login: `oracle`

Danach in DBeaver zB ausfuehren:

```sql
select table_name
from user_tables
where table_name like 'JQ_%'
order by table_name;
```

Dann die Projektdateien in DBeaver als SQL Script in dieser Reihenfolge ausfuehren:

1. `sql/00_drop.sql`
2. `sql/01_schema.sql`
3. `sql/02_routines.sql`
4. `sql/03_triggers.sql`
5. `sql/04_seed.sql`
6. `sql/05_demo.sql` fuer den festen Demo-Ablauf

In DBeaver fuer Dateien mit mehreren Statements `Execute SQL Script` verwenden, typischerweise
`Alt+X` oder das Script-Run Icon. Nicht `Execute SQL Statement` / `Ctrl+Enter` fuer ganze Dateien
verwenden. Sonst sendet DBeaver zB mehrere `create table ...` Statements als eine einzige Query
und Oracle meldet Fehler wie `ORA-03405: End of query reached; no additional text should follow`.

Die Skripte enthalten keine `/`-Zeilen als Blocktrenner. Wenn ein PL/SQL-Block einzeln gestartet
wird, genau den Block von `declare`/`begin` bis `end;` markieren und ausfuehren. Nicht zwei
`begin`/`declare` Bloecke gemeinsam als ein Statement ausfuehren. `sql/00_drop.sql` ist absichtlich
als ein einzelner Block geschrieben und kann auch mit `Execute SQL Statement` ausgefuehrt werden.

Fuer Live-Fragen waehrend der Praesentation danach einzelne Bloecke aus `sql/06_live_demo.sql`
ausfuehren.

Wenn die Datenbank komplett neu erstellt werden soll, Container und Volume loeschen:

```sh
podman compose down -v
podman compose up --build -d
```

## Enthaltene Anforderungen

- DDL mit Primary Keys, Foreign Keys, Unique Constraints und Check Constraints
- Gewinnstufen/Point Levels als eigene Tabelle fuer Jeopardy-Werte
- Procedures fuer Spielfluss: Spiel anlegen, Kandidaten anmelden, Spiel starten, Frage waehlen, buzzern, antworten, Joker verwenden
- Functions fuer Rueckgabewerte: Score, Leaderboard, schnellster Kandidat, aktuelle Frage, Joker-Hinweis
- Trigger fuer Audit-Logging und Validierung
- Eigene Fehler mit `raise_application_error`
- Demo-Spielverlauf inklusive Buzz-in: schnellste Antwort zaehlt
- Jeopardy-spezifische Punkte-Logik mit positiven und negativen Punkten
