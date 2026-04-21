# Jeopardy PL/SQL Backend

Dieses Projekt implementiert ein Oracle PL/SQL Backend fuer eine TV-Quizshow im Stil von **Jeopardy**.

## How to Run

### Podman (oder Docker) / Oracle Container

Zum lokalen Testen mit DBeaver kann eine Oracle Free Datenbank per Podman gestartet werden.
Beim ersten Start wird automatisch ein Schema `JEOPARDY` erstellt. Die Projekt-Skripte werden
danach in DBeaver ausgefuehrt, damit Ablauf, Fehler und spontane Aenderungen sichtbar bleiben.

```sh
podman compose up --build -d
```

DBeaver-Verbindung:

- Driver: Oracle
- Host: `localhost`
- Port: `1521`
- Service name: `FREEPDB1`
- Username: `jeopardy`
- Password: `jeopardy`
- SYS/SYSTEM Passwort fuer Admin-Login: `oracle`

Dann die Projektdateien in DBeaver als SQL Script in dieser Reihenfolge ausfuehren:

1. `sql/00_drop.sql`
2. `sql/01_schema.sql`
3. `sql/02_routines.sql`
4. `sql/03_triggers.sql`
5. `sql/04_seed.sql`
6. `sql/05_demo.sql`
7. `sql/07_reset_data.sql` to reset the state back to empty schema

Fuer Live-Fragen waehrend der Praesentation danach einzelne Bloecke aus `sql/06_live_demo.sql`
ausfuehren.

Wenn die Datenbank komplett neu erstellt werden soll, Container und Volume loeschen:

```sh
podman compose down -v
podman compose up --build -d
```
