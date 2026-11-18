# Singularität – animiertes Schwarzes-Loch-Hintergrundbild für KDE Plasma 6

Ein Wallpaper-Plugin, das vollständig in QML geschrieben ist (ohne vorkompilierte Shader und ohne Bilddateien):

- **Schatten des Ereignishorizonts** mit pulsierendem **Photonenring**
- **Akkretionsscheibe** aus sechs Gasringen, die **differentiell nach Kepler** rotieren (ω ∝ r^-3/2). Innen dreht sie schnell, aussen langsam, dadurch scheren Filamente und Staubbänder sichtbar auseinander
- **Gravitationslinse**: Das Bild der Scheibenrückseite wölbt sich als Bogen über den Schatten, darunter erscheint ein schwächeres Sekundärbild
- **Relativistisches Beaming**: Die auf dich zukommende linke Seite ist heller, die rechte dunkler
- **Orbitierende Plasmaklumpen**, die korrekt vor bzw. hinter dem Loch vorbeiziehen
- Sternenfeld mit Nebelschleiern, leichter Linsenverzerrung der Sterne und funkelnden Sternen
- 4 Farbschemata: Interstellar, Blauer Riese, Nebula, Glut

## Installation

```bash
kpackagetool6 --type Plasma/Wallpaper --install org.kde.singularity
```

Danach: Rechtsklick auf den Desktop → **Arbeitsfläche und Hintergrundbild einrichten…** →
**Hintergrundbild-Typ: Singularität**.

Aktualisieren bzw. Entfernen:

```bash
kpackagetool6 --type Plasma/Wallpaper --upgrade org.kde.singularity
kpackagetool6 --type Plasma/Wallpaper --remove  org.kde.singularity
```

Falls Änderungen nach einem Upgrade nicht sichtbar werden, hilft:
`systemctl --user restart plasma-plasmashell`

## Einstellungen

| Option | Bedeutung |
|---|---|
| Farbschema | Interstellar / Blauer Riese / Nebula / Glut |
| Geschwindigkeit | 0–400 % (0 % = Standbild) |
| Blickwinkel | Neigung über der Scheibenebene, 3°–45° (Standard 8°) |
| Grösse | Grösse des Schwarzen Lochs, 40–200 % |
| Horizontale Position | verschiebt das Loch nach links oder rechts, z. B. damit Desktop-Symbole frei bleiben |
| Orbitierende Partikel | Anzahl der Plasmaklumpen |
| Sterne anzeigen | Hintergrund-Sternenfeld |
| Leuchteffekte | Weichzeichner und Glühen. Abschalten spart GPU-Leistung |

## Ohne Plasma testen

`BlackHole.qml` ist unabhängig von Plasma und lässt sich direkt starten:

```bash
qml6 contents/ui/BlackHole.qml        # je nach Distribution auch /usr/lib/qt6/bin/qml
```

## Aufbau

```
org.kde.singularity/
├── metadata.json            Plugin-Beschreibung (Plasma/Wallpaper)
└── contents/
    ├── config/main.xml      Konfigurationsschema (KConfigXT)
    └── ui/
        ├── main.qml         WallpaperItem → reicht die Einstellungen an BlackHole weiter
        ├── config.qml       Einstellungsseite (Kirigami FormLayout)
        ├── BlackHole.qml    die komplette Szene und ihre Ebenen
        ├── DiskBand.qml     ein prozedural gemalter, rotierender Gasring (Canvas)
        ├── StarField.qml    Hintergrund mit Sternen und Nebel
        └── bh.js            Zufallsgenerator mit festem Startwert, Farbpaletten, Hilfsfunktionen
```

**Technik:** Die Gasringe werden einmalig per `Canvas` gemalt und danach nur noch rotiert. Das ist
eine reine GPU-Transformation. Die Scheibe wird in eine Ebene gerendert und mit zwei
`ShaderEffectSource` in eine hintere und eine vordere Hälfte geteilt, damit das Loch dazwischen
liegen kann. Weichzeichnung und Masken laufen über `MultiEffect` (QtQuick.Effects). Die Zeit
stammt aus einer `FrameAnimation`, die anhält, sobald der Desktop nicht sichtbar ist.

## Voraussetzungen

Plasma 6.0 oder neuer (Qt ≥ 6.6). Benötigt werden die Module QtQuick, QtQuick.Shapes und
QtQuick.Effects, die bei Plasma 6 standardmässig installiert sind.

Lizenz: CC0-1.0 license
