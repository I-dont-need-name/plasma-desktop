/***************************************************************************
 *   Copyright (C) 2013-2014 by Eike Hein <hein@kde.org>                   *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: root

    readonly property bool inPanel: (plasmoid.location === PlasmaCore.Types.TopEdge
        || plasmoid.location === PlasmaCore.Types.RightEdge
        || plasmoid.location === PlasmaCore.Types.BottomEdge
        || plasmoid.location === PlasmaCore.Types.LeftEdge)
    readonly property bool vertical: (plasmoid.formFactor === PlasmaCore.Types.Vertical)
    readonly property bool useCustomButtonImage: (plasmoid.configuration.useCustomButtonImage
        && plasmoid.configuration.customButtonImage.length !== 0)
    property QtObject dashWindow: null

    onWidthChanged: updateSizeHints()
    onHeightChanged: updateSizeHints()

    onDashWindowChanged: {
        if (dashWindow) {
            dashWindow.visualParent = root;
        }
    }

    function updateSizeHints() {
        if (useCustomButtonImage) {
            if (vertical) {
                var scaledHeight = Math.floor(parent.width * (buttonIcon.implicitHeight / buttonIcon.implicitWidth));
                root.Layout.minimumHeight = scaledHeight;
                root.Layout.maximumHeight = scaledHeight;
                root.Layout.minimumWidth = PlasmaCore.Units.iconSizes.small;
                root.Layout.maximumWidth = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
            } else {
                var scaledWidth = Math.floor(parent.height * (buttonIcon.implicitWidth / buttonIcon.implicitHeight));
                root.Layout.minimumWidth = scaledWidth;
                root.Layout.maximumWidth = scaledWidth;
                root.Layout.minimumHeight = PlasmaCore.Units.iconSizes.small;
                root.Layout.maximumHeight = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
            }
        } else {
            root.Layout.minimumWidth = PlasmaCore.Units.iconSizes.small;
            root.Layout.maximumWidth = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
            root.Layout.minimumHeight = PlasmaCore.Units.iconSizes.small;
            root.Layout.maximumHeight = inPanel ? PlasmaCore.Units.iconSizeHints.panel : -1;
        }
    }

    Connections {
        target: PlasmaCore.Units.iconSizeHints

        function onPanelChanged() {
            root.updateSizeHints()
        }
    }

    PlasmaCore.IconItem {
        id: buttonIcon

        anchors.fill: parent

        readonly property double aspectRatio: (root.vertical ? implicitHeight / implicitWidth
            : implicitWidth / implicitHeight)

        source: root.useCustomButtonImage ? plasmoid.configuration.customButtonImage : plasmoid.configuration.icon

        active: mouseArea.containsMouse && !justOpenedTimer.running

        smooth: true

        // A custom icon could also be rectangular. However, if a square, custom, icon is given, assume it
        // to be an icon and round it to the nearest icon size again to avoid scaling artifacts.
        roundToIconSize: !root.useCustomButtonImage || aspectRatio === 1

        onSourceChanged: root.updateSizeHints()
    }

    MouseArea
    {
        id: mouseArea
        property bool wasExpanded: false;

        anchors.fill: parent

        hoverEnabled: !root.dashWindow || !root.dashWindow.visible

        onPressed: {
            if (!isDash) {
                wasExpanded = plasmoid.expanded
            }
        }

        onClicked: {
            if (isDash) {
                root.dashWindow.toggle();
                justOpenedTimer.start();
            } else {
                plasmoid.expanded = !wasExpanded;
            }
        }
    }

    Component.onCompleted: {
        if (isDash) {
            dashWindow = Qt.createQmlObject("DashboardRepresentation {}", root);
            plasmoid.activated.connect(function() {
                dashWindow.toggle()
                justOpenedTimer.start()
            })
        }
    }
}
