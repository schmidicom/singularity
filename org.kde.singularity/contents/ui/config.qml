import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property alias cfg_Speed: speedSlider.value
    property alias cfg_Tilt: tiltSlider.value
    property alias cfg_HoleSize: sizeSlider.value
    property alias cfg_OffsetX: offsetSlider.value
    property alias cfg_ColorScheme: schemeBox.currentIndex
    property alias cfg_ParticleCount: particleSpin.value
    property alias cfg_ShowStars: starsCheck.checked
    property alias cfg_Glow: glowCheck.checked

    QQC2.ComboBox {
        id: schemeBox
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.singularity", "Color scheme:")
        model: [
            i18nd("plasma_wallpaper_org.kde.singularity", "Interstellar (warm)"),
            i18nd("plasma_wallpaper_org.kde.singularity", "Blue giant"),
            i18nd("plasma_wallpaper_org.kde.singularity", "Nebula"),
            i18nd("plasma_wallpaper_org.kde.singularity", "Ember")
        ]
    }

    RowLayout {
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.singularity", "Speed:")
        QQC2.Slider { id: speedSlider; from: 0; to: 400; stepSize: 5; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
        QQC2.Label { text: Math.round(speedSlider.value) + " %" }
    }

    RowLayout {
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.singularity", "Viewing angle:")
        QQC2.Slider { id: tiltSlider; from: 3; to: 45; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
        QQC2.Label { text: Math.round(tiltSlider.value) + "°" }
    }

    RowLayout {
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.singularity", "Size:")
        QQC2.Slider { id: sizeSlider; from: 40; to: 200; stepSize: 5; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
        QQC2.Label { text: Math.round(sizeSlider.value) + " %" }
    }

    RowLayout {
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.singularity", "Horizontal position:")
        QQC2.Slider { id: offsetSlider; from: -40; to: 40; stepSize: 1; Layout.preferredWidth: Kirigami.Units.gridUnit * 12 }
        QQC2.Label { text: Math.round(offsetSlider.value) + " %" }
    }

    QQC2.SpinBox {
        id: particleSpin
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.singularity", "Orbiting particles:")
        from: 0
        to: 600
        stepSize: 10
    }

    QQC2.CheckBox {
        id: starsCheck
        Kirigami.FormData.label: i18nd("plasma_wallpaper_org.kde.singularity", "Background:")
        text: i18nd("plasma_wallpaper_org.kde.singularity", "Show stars")
    }

    QQC2.CheckBox {
        id: glowCheck
        text: i18nd("plasma_wallpaper_org.kde.singularity", "Glow effects (uses more GPU)")
    }
}
