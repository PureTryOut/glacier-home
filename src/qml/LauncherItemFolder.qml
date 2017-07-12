// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// Copyright (c) 2017, Eetu Kahelin
// Copyright (c) 2013, Jolla Ltd <robin.burchell@jollamobile.com>
// Copyright (c) 2012, Timur Kristóf <venemo@fedoraproject.org>
// Copyright (c) 2011, Tom Swindell <t.swindell@rubyx.co.uk>

import QtQuick 2.6
import QtQuick.Controls.Nemo 1.0
import QtQuick.Controls.Styles.Nemo 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: wrapper
    property alias iconCaption: iconText
    property bool reordering: launcherItem.reordering
    property bool isFolder
    property int folderAppsCount
    property bool notNemoIcon
    property alias folderLoader: folderLoader
    property alias folderModel:launcherItem.folderModel
    onXChanged: moveTimer.start()
    onYChanged: moveTimer.start()

    Timer {
        id: moveTimer
        interval: 1
        onTriggered: moveIcon()
    }

    function moveIcon() {
        if (!reordering) {
            if (!launcherItem.slideMoveAnim.running) {
                launcherItem.slideMoveAnim.start()
            }
        }
    }
    // Application icon for the launcher
    LauncherItemWrapper {
        id: launcherItem
        width: wrapper.width
        height: wrapper.height
        isFolder: wrapper.isFolder
        notNemoIcon:wrapper.notNemoIcon
        parentItem: wrapper.parent

        clip: true
        onClicked: {
            // TODO: disallow if close mode enabled
            if (modelData.object.type !== LauncherModel.Folder) {
                var winId = switcher.switchModel.getWindowIdForTitle(modelData.object.title)
                if (winId == 0 || !modelData.object.isLaunching)
                    modelData.object.launchApplication()
                else
                    Lipstick.compositor.windowToFront(winId)
            } else {
                folderLoader.model = modelData.object
                //folderLoader.visible = true
            }
        }
        Item {
            id:folderIconStack
            width: size
            height: size
            property int size: parent.width -parent.width/10
            property int iconSize: (/*launcherItem.notNemoIcon ? size-size/3 : */ (size - size/4)) * 0.9
            property real transparency: 0.6
            property int iconCount: 4
            property var icons: addIcons()

            function addIcons() {
                var iconsList = []
                for (var i = 0; i < modelData.object.itemCount && i < iconCount; i++) {
                    var icon = (modelData.object.get(i).iconId.indexOf("/") == 0 ? "file://" : "image://theme/") + modelData.object.get(i).iconId
                    iconsList.push(icon)
                }
                return iconsList
            }

            Image {
                width: folderIconStack.iconSize
                height: folderIconStack.iconSize
                opacity: folderIconStack.transparency
                x:toppestIcon.x+Theme.itemSpacingSmall
                y:toppestIcon.y+Theme.itemSpacingSmall
                visible: folderIconStack.icons.length > folderIconStack.iconCount-1
                source: visible ? folderIconStack.icons[folderIconStack.iconCount-1] : ""
            }

            Image {
                width: folderIconStack.iconSize
                height: folderIconStack.iconSize
                opacity: folderIconStack.transparency
                x:toppestIcon.x-Theme.itemSpacingSmall
                y:toppestIcon.y+Theme.itemSpacingSmall
                visible: folderIconStack.icons.length > folderIconStack.iconCount-2
                source: visible ? folderIconStack.icons[folderIconStack.iconCount-2] : ""
            }

            Image {
                width: folderIconStack.iconSize
                height: folderIconStack.iconSize
                opacity: folderIconStack.transparency
                x:toppestIcon.x+Theme.itemSpacingSmall
                y:toppestIcon.y-Theme.itemSpacingSmall
                visible: folderIconStack.icons.length > folderIconStack.iconCount-3
                source: visible ? folderIconStack.icons[folderIconStack.iconCount-3] : ""
            }

            Image {
                id:toppestIcon
                width: folderIconStack.iconSize
                height: folderIconStack.iconSize
                opacity: folderIconStack.transparency
                anchors.centerIn: parent
                visible: icons.length > 0
                source: visible ? folderIconStack.icons[0]: ""
            }
            Text{
                id: itemsCount
                visible: false// launcherItem.isFolder
                text: wrapper.folderAppsCount
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: folderIconStack.iconSize.width/4
                color: "white"
            }
        }
        // Caption for the icon
        Text {
            id: iconText
            // elide only works if an explicit width is set
            width: iconWrapper.width
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.textColor
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                topMargin: Theme.itemSpacingExtraSmall
            }
        }

        Rectangle {
            id:triangle
            width: wrapper.height/4
            height: width
            rotation: 45
            color: "white"
            opacity: 0.85
            visible: folderLoader.visible && folderLoader.count > 0
            anchors.top:launcherItem.bottom
            anchors.horizontalCenter: launcherItem.horizontalCenter
        }
    }

    GridView {
        id: folderLoader
        property Item reorderItem
        property bool isRootFolder:false
        cacheBuffer: folderLoader.contentHeight
        parent: gridview.contentItem
        y: wrapper.y + wrapper.width
        x: 0
        z: wrapper.z + 100
        width: gridview.width
        height: count == 0 ? 0 :  (Math.floor((count*wrapper.height-1)/width) + 1) * wrapper.height
        cellWidth: wrapper.width
        cellHeight: wrapper.width

        Rectangle {
            width: parent.width
            height: parent.height
            opacity: 0.85
            color: triangle.color
            radius: Theme.itemSpacingMedium
            z: -1
        }

        delegate: LauncherItemDelegate {
            id:folderLauncherItem
            property QtObject modelData : model
            property int cellIndex: index
            parent: folderLoader
            parentItem: folderLoader
            width: wrapper.width
            height: wrapper.height
            notNemoIcon:  isFolder || model.object.iconId == "" ? false : model.object.iconId.indexOf("harbour") > -1  ||  model.object.iconId.indexOf("apkd_launcher") > -1 ? true : false //Dirty but works most of the times
            isFolder: model.object.type == LauncherModel.Folder
            source: model.object.iconId == "" || isFolder ? "/usr/share/lipstick-glacier-home-qt5/qml/theme/default-icon.png" : (model.object.iconId.indexOf("/") == 0 ? "file://" : "image://theme/") + model.object.iconId
            iconCaption.text: model.object.title
            iconCaption.color: Theme.backgroundColor
            folderModel:folderLoader.model
            onReorderingChanged: if(!reordering) folderIconStack.icons=folderIconStack.addIcons()
            visible: false
        }

        Behavior on height {
            NumberAnimation {
                easing.type: Easing.InQuad
                duration: 100
                onRunningChanged: if(!running && folderLoader.count>0) folderLauncherItem.visible = true
            }
        }
    }

    //When display goes off, close the folderloader
    Connections {
        target: Lipstick.compositor
        onDisplayOff: {
            folderLoader.model = 0
        }
    }

    InverseMouseArea {
        anchors.fill: folderLoader
        enabled: folderLoader.visible && folderLoader.count > 0
        parent:folderLoader.contentItem
        onPressed: {
            folderLoader.model = 0
        }
    }


}

