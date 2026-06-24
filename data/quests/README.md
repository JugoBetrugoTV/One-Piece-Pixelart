# data/quests/ & data/dialogues/

In diesem Projekt sind **Quests und Dialoge bewusst direkt in der jeweiligen
Arc-Datei** (`data/arcs/<arc>.json`) eingebettet – Felder `"quests"` und
`"dialogues"`. Das hat einen Grund:

> **Ein neuer Arc = eine einzige neue JSON-Datei.**
> Alles, was zum Arc gehört (Maps, NPCs, Dialoge, Quests, Gegner, Boss), steht
> an einem Ort und kann hinzugefügt werden, ohne den Kerncode anzufassen.

Diese Ordner sind als **Erweiterungspunkt** reserviert: Wenn ein Arc sehr groß
wird, kannst du Dialoge/Quests hierhin auslagern und den Loader in
`scripts/arc_manager.gd` entsprechend erweitern (z.B. `"dialogues_file"` in der
Arc-JSON unterstützen). Für die aktuelle Spielgröße ist die Inline-Variante
einfacher und übersichtlicher.

Das Schema ist dokumentiert in [`docs/ARC_SCHEMA.md`](../../docs/ARC_SCHEMA.md).
