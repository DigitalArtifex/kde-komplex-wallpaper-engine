 /*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  WindowModel.qml
 *
 *  Copyright 2018 Rog131 <samrog131@hotmail.com>
 *  Copyright 2019 adhe   <adhemarks2@gmail.com>
 *  Copyright 2024 Luis Bocanegra <luisbocanegra17b@gmail.com>
 *
 *  This file was part of the KDE Shader Wallpaper project and is used to track the 
 *  desktop state.
 *
 *  --------------------------------------------------------------------------------------------------------
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *  This software uses some of the QML code from JaredTao/jared2020@163.com's ToyShader for Android.
 *  See: https://github.com/jaredtao/TaoShaderToy/
 */

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.taskmanager 0.1 as TaskManager
import org.kde.kwindowsystem

import com.github.digitalartifex.komplex as Komplex

Item 
{
    id: wModel
    property var screenGeometry
    property int pauseMode: wallpaper.configuration.pauseMode
    property bool runShader: false
    property bool maximizedExists: false
    property bool visibleExists: false
    property bool activeExists: false
    property var abstractTasksModel: TaskManager.AbstractTasksModel
    property var appId: abstractTasksModel.AppId
    property var isWindow: abstractTasksModel.IsWindow
    property var isMinimized: abstractTasksModel.IsMinimized
    property var isMaximized: abstractTasksModel.IsMaximized
    property var isFullScreen: abstractTasksModel.IsFullScreen
    property var isActive: abstractTasksModel.IsActive
    property var isHidden: abstractTasksModel.IsHidden
    property bool activeScreenOnly: wallpaper.configuration.checkActiveScreen
    property var excludeWindows: wallpaper.configuration.excludeWindows

    Komplex.ShaderPackModel
    {
        id: shaderPackModel
    }

    Connections 
    {
        target: wallpaper.configuration
        function onValueChanged() 
        {
            wModel.updateWindowsInfo();
        }
    }

    Connections 
    {
        target: KWindowSystem
        function onShowingDesktopChanged() 
        {
            wModel.updateWindowsInfo();
        }
    }

    onPauseModeChanged: 
    {
        updateWindowsInfo();
    }

    function updateRun() 
    {
        let shouldRun = true;
        switch (pauseMode)
        {
        case 0:
            shouldRun = !maximizedExists;
            break;
        case 1:
            shouldRun = !activeExists;
            break;
        case 2:
            shouldRun = !visibleExists;
            break;
        case 3:
            shouldRun = true;
        }
        runShader = shouldRun;
    }

    TaskManager.VirtualDesktopInfo 
    {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo 
    {
        id: activityInfo
        readonly property string nullUuid: "00000000-0000-0000-0000-000000000000"
    }

    TaskManager.TasksModel 
    {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        virtualDesktop: virtualDesktopInfo.currentDesktop
        activity: activityInfo.currentActivity
        screenGeometry: wModel.screenGeometry
        filterByVirtualDesktop: true
        filterByScreen: parent.activeScreenOnly
        filterByActivity: true
        filterMinimized: true

        onActiveTaskChanged: 
        {
            updateWindowsInfo();
        }

        onDataChanged: 
        {
            updateWindowsInfo();
        }

        onCountChanged: 
        {
            updateWindowsInfo();
        }
    }

    function updateWindowsInfo() 
    {
        let activeCount = 0;
        let visibleCount = 0;
        let maximizedCount = 0;

        if (!KWindowSystem.showingDesktop) 
        {
            for (var i = 0; i < tasksModel.count; i++) 
            {
                const currentTask = tasksModel.index(i, 0);

                // Long line
                if (currentTask === undefined || excludeWindows.includes(tasksModel.data(currentTask, appId).replace(/\.desktop$/, "")) || tasksModel.data(currentTask, isHidden) || !tasksModel.data(currentTask, isWindow) || tasksModel.data(currentTask, isMinimized))
                    continue;

                visibleCount += 1;
                if (tasksModel.data(currentTask, isMaximized) || tasksModel.data(currentTask, isFullScreen))
                    maximizedCount += 1;
                if (tasksModel.data(currentTask, isActive))
                    activeCount += 1;
            }
        }

        visibleExists = visibleCount > 0;
        maximizedExists = maximizedCount > 0;
        activeExists = activeCount > 0;
        updateRun();
    }
}
