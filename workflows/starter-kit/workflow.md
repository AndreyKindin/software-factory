# Workflow: Starter Kit

Basiert auf dem [AI Coding Starter Kit](https://github.com/AlexPEClub/ai-coding-starter-kit) von Alex Sprogis, angepasst für die Factory.

## Aufgabenteilung

- **Du (lokal):** Spec schreiben, prüfen und auf den Standard-Branch pushen. Dann ein Issue mit dem Label `factory` und einem Verweis `Spec: <pfad>` anlegen.
- **Du (im Issue):** Eine Idee mit `factory:spec-draft` markieren, Rückfragen und Entwürfe im Issue beantworten und die aktuelle Version mit `/approve-spec v1` (bzw. der aktuellen Nummer) freigeben. Der Runner speichert die freigegebene Fassung schreibgeschützt und setzt `factory`.
- **Factory (auf dem Server):** Architektur, Umsetzung, QA, Pull Request.
- **Du:** Pull Request prüfen und mergen.

Die serverseitigen Workflow-Skills werden im Job-Container unter `~/.agents/skills/` bereitgestellt.

## Ablage

Pro Feature ein Ordner, Spec, Architektur und Testbericht getrennt:

```
features/
  INDEX.md                         Übersicht aller Features + Status + nächste freie ID
  PROJ-3-genre-sortierung/
    spec.md                        WAS: User Stories, Akzeptanzkriterien, Edge Cases (Vertrag, von dir)
    design.md                      WIE: Komponenten, Datenmodell, Tech-Entscheidungen (Factory)
    qa-report.md                   ERGEBNIS: Testlauf gegen die Akzeptanzkriterien (Factory)
```

## Zuordnung zu den Factory-Phasen

- **Prüfung** (eigener, kurzer Lauf, baut nichts)
  - Feature: Spec vorhanden? Jedes Akzeptanzkriterium testbar? Widerspruchsfrei, passend zum Stack, Voraussetzungen erfüllt?
  - Bug: Ist klar, was falsch ist und was stattdessen passieren soll?
  - Bei Freigabe: Testszenarien für die Abnahme schreiben (`/scenarios/scenarios.md`, außerhalb des Repos, der Entwickler-Agent sieht sie nie)
  - Ergebnis: **Freigegeben**, **Rückfrage** oder **Abgelehnt** (Feature ohne Spec wird immer abgelehnt)
- **Bau** (startet automatisch, sobald ein Platz frei ist)
  - Schritt **Architektur** → Skill `architecture` → `design.md` (Bug: reproduzieren, roter Test)
  - Schritt **Umsetzung** → Skill `build` (Bug: Fix)
  - Schritt **Tests** → Skill `qa` → `qa-report.md`
  - Ergebnis: Pull Request → **Abnahme**
- **Abnahme** (eigener Lauf, neuer Agent, entwickelt nichts)
  - Prüft die Testszenarien auf dem PR-Branch über die Schnittstelle des Projekts. Bei Webanwendungen nutzt sie den Browser.
  - Bestanden → **Review**. Nicht bestanden → Befunde zurück in die Entwicklung (max. 2 Runden, danach Review mit „Bitte genau prüfen")

## Status auf dem Board

Neu → In Prüfung → (Rückfrage | Abgelehnt) → Freigegeben → In Arbeit (Schritt: Architektur · Umsetzung · Tests) → Abnahme → Review → Fertig. Technische Fehler: Fehlgeschlagen (ein Kommentar startet einen neuen Versuch).

## Status in `features/INDEX.md`

`Planned` (Spec fertig, von dir) → `Architected` → `In Progress` → `In Review` → `Approved` (QA bestanden)

## Einen anderen Workflow verwenden

Die Factory ist nicht an diesen Workflow gebunden. Ein Workflow ist ein Ordner unter `workflows/<name>/` mit
- `workflow.md`: welcher Skill in welcher Stage läuft und wo Ergebnisse abgelegt werden
- `skills/`: die Skills (werden im Job-Container als Nutzer-Skills installiert)

Das Playbook (`playbooks/factory.md`) bleibt gleich: Stages melden, bei Unklarheit fragen, Checks, PR. Auswahl über `workflow` in der Factory-Config.
