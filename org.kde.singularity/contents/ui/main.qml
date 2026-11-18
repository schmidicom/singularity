import QtQuick
import org.kde.plasma.plasmoid

WallpaperItem {
    id: wallpaper

    BlackHole {
        anchors.fill: parent

        speed: wallpaper.configuration.Speed / 100
        tilt: wallpaper.configuration.Tilt
        holeScale: wallpaper.configuration.HoleSize / 100
        offsetX: wallpaper.configuration.OffsetX / 100
        scheme: wallpaper.configuration.ColorScheme
        particleCount: wallpaper.configuration.ParticleCount
        showStars: wallpaper.configuration.ShowStars
        glow: wallpaper.configuration.Glow

        // stop rendering while the desktop is not visible (e.g. screen locked / off)
        running: wallpaper.visible && Qt.application.state !== Qt.ApplicationSuspended
    }
}
