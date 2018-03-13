# schema2class
Eine kleine Aufgabe für ein Haskell Dojo.

Es geht darum ein relationales Schema in eine Vererbungshierachie umzuwandeln.
Zunächst wird aus jeder Tabelle eine "Klasse", aus jeder Spalte ein "Attribut"
dieser Klasse.

Oberklassen werden gebildet, wenn verschiedene Tabellen gleichnamige Spalten haben.

Am Ende wird aus jedem Spaltennamen genau ein Attribut in genau einer (Ober-)Klasse.

## Musterlösung
Die "Musterlösung" benutzt keine der im Dojo genannten Typen,
ist aber eine komplette "Lösung" des Problems basierend auf Listen.

Sie erstellt nicht nur die komplette Klassenhierarchie (Funktion allClasses)
sondern daraus auch wieder eine relationales Schema (Funktion allTables).

Damit das auch immer gut geht gibt es eine Funktion: normalizeTable
die ein Schema "normiert":
- genau eine Tabelle pro Tabellenname
- Jeder Spaltennamen nur einmal pro Tabelle

Die Funktion recurrence kombiniert allClasses, allTables und normalizeTable
zu einem "quickCheck"-fähigen Recurrenztest. Theoretisch, die Performanz ist aber so schlecht, dass ich den noch nicht seine 100 Tests zu Ende laufen lassen konnte.

## Beispiele
Ein paar kleine Beispiele stecken im Code: ex1-6
Ein Funktion zum Einlesen einer Textdatei readTable macht aus jeder Textdatei ein Schema, das man nur noch normalisieren muss.

In der Datei "in" steckt ein bisschen grösseres Testschema.

## Aufgabenansatz
Die Typen Schema und Classes und die Ein- Ausgabefunktionen solltet ihr wiederverwenden können.

Natürlich sollt ihr aber dazwischen *andere* Datenstrukturen als die Listen verwenden.
Definiert sie und wandelt die Table um in diese Datenstruktur, und Euer Ergebnis dann in zurück in "Classes".
Die nicht implementierte Funktion "normalizeClasses" sollte dafür sorgen,
dass die "Classes" Struktur normiert ist:
- Die Klassennamen sind gleich den Tabellennamen oder der sortierten Liste der Tabellennamen deren Oberklasse sie bilden.
- Die Spaltennamen sind lexikalisch sortiert und niemals doppelt.
- Jede Klasse hat mindestens ein Attribut.

Meine Implementierung (behaupte ich jedenfalls, und der quickCheck glaubt das)
liefert immer so eine Struktur ab. Ihr müsste gegebenfalls dafür noch sorgen.

## Aufgabe:
Verwendet eine der Typen:
- Map
- Sequence
- Set
- Vector

Meine Zusatzaufgabe:
- löst das Problem etwas effizienter als ich das getan habe!
- n log n sollte machbar sein wenn n die Gesamtzahl aller Spaltennamen ist.
