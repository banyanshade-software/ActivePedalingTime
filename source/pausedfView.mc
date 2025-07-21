using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Application;

class ActivePedalingTimerView extends WatchUi.DataField {
    
    // Variables pour tracker le temps de pédalage actif
    private var mActivePedalingTime;
    private var mLastUpdateTime;
    private var mIsMoving;
    private var mSpeedThreshold;
    private var mLastSpeed;
    private var mMovingStartTime;
    
    function initialize() {
        DataField.initialize();
        
        // Initialisation des variables
        mActivePedalingTime = 0;
        mLastUpdateTime = null;
        mIsMoving = false;
        mSpeedThreshold = 0.7; // Seuil de vitesse en m/s (3.6 km/h)
        mLastSpeed = 0;
        mMovingStartTime = null;
    }

    // Appelé quand l'activité démarre
    function onTimerStart() {
        mLastUpdateTime = System.getTimer();
    }

    // Appelé quand l'activité s'arrête
    function onTimerStop() {
        // Si on était en mouvement, ajouter le temps écoulé
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            mActivePedalingTime += (currentTime - mMovingStartTime);
        }
        mIsMoving = false;
        mMovingStartTime = null;
    }

    // Appelé quand l'activité est en pause
    function onTimerPause() {
        // Si on était en mouvement, ajouter le temps écoulé
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            mActivePedalingTime += (currentTime - mMovingStartTime);
        }
        mIsMoving = false;
        mMovingStartTime = null;
    }

    // Appelé quand l'activité reprend après une pause
    function onTimerResume() {
        mLastUpdateTime = System.getTimer();
    }

    // Appelé à chaque mise à jour des données
    function compute(info) {
        var currentTime = System.getTimer();
        
        if (mLastUpdateTime == null) {
            mLastUpdateTime = currentTime;
            return;
        }

        // Récupérer la vitesse actuelle
        var currentSpeed = 0;
        if (info has :currentSpeed && info.currentSpeed != null) {
            currentSpeed = info.currentSpeed;
        }

        // Déterminer si on est en mouvement
        var wasMoving = mIsMoving;
        mIsMoving = (currentSpeed > mSpeedThreshold);

        // Si on commence à bouger
        if (mIsMoving && !wasMoving) {
            mMovingStartTime = currentTime;
        }
        // Si on s'arrête de bouger
        else if (!mIsMoving && wasMoving && mMovingStartTime != null) {
            mActivePedalingTime += (currentTime - mMovingStartTime);
            mMovingStartTime = null;
        }
        // Si on continue de bouger, on ne fait rien ici
        // (le temps sera ajouté quand on s'arrêtera)

        mLastSpeed = currentSpeed;
        mLastUpdateTime = currentTime;
    }

    // Appelé pour dessiner le datafield
    function onUpdate(dc) {
        // Calculer le temps total à afficher
        var totalTime = mActivePedalingTime;
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            totalTime += (currentTime - mMovingStartTime);
        }

        // Convertir en heures, minutes, secondes
        var totalSeconds = totalTime / 1000;
        var hours = totalSeconds / 3600;
        var minutes = (totalSeconds % 3600) / 60;
        var seconds = totalSeconds % 60;

        // Formater le temps
        var timeString;
        if (hours >= 1) {
            timeString = hours.format("%d") + ":" + 
                        minutes.format("%02d") + ":" + 
                        seconds.format("%02d");
        } else {
            timeString = minutes.format("%d") + ":" + 
                        seconds.format("%02d");
        }

        // Définir les couleurs
        var bgColor = getBackgroundColor();
        var fgColor = (bgColor == Graphics.COLOR_WHITE) ? Graphics.COLOR_BLACK : Graphics.COLOR_WHITE;

        // Effacer l'arrière-plan
        dc.setColor(bgColor, bgColor);
        dc.clear();

        // Dessiner le label en haut
        dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() * 0.25,
            Graphics.FONT_XTINY,
            "TEMPS ACTIF",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Ajuster la taille de police pour la valeur
        var font = Graphics.FONT_NUMBER_HOT;
        var textDimension = dc.getTextDimensions(timeString, font);
        
        if (textDimension[0] > dc.getWidth() * 0.9) {
            font = Graphics.FONT_NUMBER_MEDIUM;
            textDimension = dc.getTextDimensions(timeString, font);
        }
        
        if (textDimension[0] > dc.getWidth() * 0.9) {
            font = Graphics.FONT_LARGE;
        }

        // Dessiner la valeur du temps au centre
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() * 0.65,
            font,
            timeString,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Indicateur de mouvement
        if (mIsMoving) {
            dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(dc.getWidth() - 8, 8, 3);
        }
    }

    // Retourner le label du datafield
    function getLabel() {
        return "Temps Actif";
    }
}

class ActivePedalingTimerApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        return [new ActivePedalingTimerView()];
    }
}