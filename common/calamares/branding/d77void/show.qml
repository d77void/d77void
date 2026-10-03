/* === This file is part of d77void ===
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation

    function nextSlide() {
        presentation.goToNextSlide()
    }

    Timer {
        interval: 7500
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.nextSlide()
    }

    Item {
        anchors.fill: parent
        property bool isSlide: true
        property bool delayPoints: false
        property string notes: ""
        visible: false

        Image {
            anchors.fill: parent
            source: "01-welcome.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    Item {
        anchors.fill: parent
        property bool isSlide: true
        property bool delayPoints: false
        property string notes: ""
        visible: false

        Image {
            anchors.fill: parent
            source: "02-void-linux.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    Item {
        anchors.fill: parent
        property bool isSlide: true
        property bool delayPoints: false
        property string notes: ""
        visible: false

        Image {
            anchors.fill: parent
            source: "03-desktops.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    Item {
        anchors.fill: parent
        property bool isSlide: true
        property bool delayPoints: false
        property string notes: ""
        visible: false

        Image {
            anchors.fill: parent
            source: "04-community.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
        }
    }

    function onActivate() {
        presentation.currentSlide = 0
    }

    function onLeave() {
    }
}
