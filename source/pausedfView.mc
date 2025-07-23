using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.System;
using Toybox.ActivityRecording;
using Toybox.Application;
using Toybox.FitContributor;

/*
class MyFitContributor extends Fit.FitContributorBase {
    
    function initialize() {
        FitContributorBase.initialize();
    }
    
    function getFieldDescriptors() {
        return [
            new Fit.FieldDescriptor(
                "my_custom_metric",
                0, // Field ID unique
                Fit.DATA_TYPE_FLOAT
            )
        ];
    }


    function onTimerLap() {
        // Appelé à chaque lap
    }
    
    function onTimerStart() {
        // Appelé au début de l'activité
    }
    
    function onTimerStop() {
        // Appelé à la fin de l'activité
    }
}
*/


class ActivePedalingTimerView extends WatchUi.DataField {
    
    // Variables pour tracker le temps de pédalage actif
    private var mActivePedalingTime;
    private var mLastUpdateTime;
    private var mIsMoving;
    private var mSpeedThreshold;
    private var mLastSpeed;
    private var mMovingStartTime;
    private var mStopDelay;
    private var mSlowStartTime;
    private var fitField;
    const TACT_FIELD_ID = 0;
    private var lbl;

    function getLabel() {
        // Récupère la chaîne selon la langue du système
        return WatchUi.loadResource(Rez.Strings.fldname);
    }
    function initialize() {
        DataField.initialize();
        lbl = getLabel();
      
        fitField = createField(
            lbl,
            TACT_FIELD_ID,
            FitContributor.DATA_TYPE_FLOAT,
            {:mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"B"}
        );
    
        
        // Initialisation des variables
        mActivePedalingTime = 0;
        mLastUpdateTime = null;
        mIsMoving = false;
        mSpeedThreshold = 1.0; // Seuil de vitesse en m/s (3.6 km/h)
        mLastSpeed = 0;
        mMovingStartTime = null;
        mStopDelay = 5000; // 5 secondes de délai avant arrêt
        mSlowStartTime = null;
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
            var endTime = (mSlowStartTime != null) ? mSlowStartTime : currentTime;
            mActivePedalingTime += (endTime - mMovingStartTime);
        }
        mIsMoving = false;
        mMovingStartTime = null;
        mSlowStartTime = null;
    }

    // Appelé quand l'activité est en pause
    function onTimerPause() {
        // Si on était en mouvement, ajouter le temps écoulé
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            var endTime = (mSlowStartTime != null) ? mSlowStartTime : currentTime;
            mActivePedalingTime += (endTime - mMovingStartTime);
        }
        mIsMoving = false;
        mMovingStartTime = null;
        mSlowStartTime = null;
    }

    function updateFit() as Void {
        fitField.setData(mActivePedalingTime);
    }
    // Appelé quand l'activité reprend après une pause
    function onTimerResume() {
        updateFit();
        mActivePedalingTime = 0; // reset active time
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

        // Déterminer si on est au-dessus du seuil de vitesse
        var isAboveThreshold = (currentSpeed > mSpeedThreshold);
        var wasMoving = mIsMoving;

        // Logique avec délai d'arrêt
        if (isAboveThreshold) {
            // On va assez vite
            if (!mIsMoving) {
                // On commence à bouger
                mIsMoving = true;
                mMovingStartTime = currentTime;
            }
            // Reset du délai d'arrêt
            mSlowStartTime = null;
            
        } else {
            // On est en dessous du seuil
            if (mIsMoving) {
                // On était en mouvement, commencer le décompte du délai
                if (mSlowStartTime == null) {
                    mSlowStartTime = currentTime;
                } else {
                    // Vérifier si le délai est écoulé
                    if (currentTime - mSlowStartTime >= mStopDelay) {
                        // Délai écoulé, arrêter le compteur
                        if (mMovingStartTime != null) {
                            // Ajouter le temps jusqu'au début du ralentissement
                            mActivePedalingTime += (mSlowStartTime - mMovingStartTime);
                        }
                        mIsMoving = false;
                        mMovingStartTime = null;
                        mSlowStartTime = null;
                    }
                }
            }
        }

        mLastSpeed = currentSpeed;
        mLastUpdateTime = currentTime;
    }

    // Appelé pour dessiner le datafield
    function onUpdate(dc) {
        // Calculer le temps total à afficher
        var totalTime = mActivePedalingTime;
        if (mIsMoving && mMovingStartTime != null) {
            var currentTime = System.getTimer();
            var endTime = (mSlowStartTime != null) ? mSlowStartTime : currentTime;
            totalTime += (endTime - mMovingStartTime);
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
        //dc.setColor(fgColor, Graphics.COLOR_TRANSPARENT);
        dc.setColor(Graphics.COLOR_PINK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            dc.getWidth() / 2,
            dc.getHeight() * 0.25,
            Graphics.FONT_XTINY,
            lbl,
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

        // Indicateur de mouvement avec état du délai
        if (mIsMoving) {
            if (mSlowStartTime != null) {
                // En période de délai - orange
                dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
            } else {
                // En mouvement normal - vert
                dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_TRANSPARENT);
            }
            dc.fillCircle(dc.getWidth() - 8, 8, 3);
        }
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